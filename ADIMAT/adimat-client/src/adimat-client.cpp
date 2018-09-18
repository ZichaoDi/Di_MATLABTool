#include <iostream>
#include <iomanip>
#include <sstream>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/stat.h>
#include <time.h>

#include <libxml/tree.h>
#include <libxml/parser.h>

// #include <openssl/ssl.h>
// // #include <openssl/rand.h>
// #include <openssl/err.h>

#include "adimat-client-opts.hh"
#include "rfc822-message.hh"
#include "logcontext.hh"
#include "cgi.hh"
#include "mkdir.hh"
#include "windows-util.hh"
#include "connection.hh"
#include "response.hh"
#include "web-util.hh"
#include "random.hh"
#include "client-util.h"
#include "loggingstream.h"
#include "uri.hh"
#include "libxml-util.hh"
#include "adimat-version.h"

// The global options structure.  
static gengetopt_args_info args;

#ifdef CMDLINE_PARSER_PACKAGE_NAME
static char const *packageName = 
  (strlen(CMDLINE_PARSER_PACKAGE_NAME) ? CMDLINE_PARSER_PACKAGE_NAME : CMDLINE_PARSER_PACKAGE);
#else 
static char const *packageName = CMDLINE_PARSER_PACKAGE;
#endif

static int adimatClientDebug = 0;

static std::string debugDumpDir = ".";

bool isxdigit(std::string const &s) {
  bool res = true;
  for(size_t i = 0; i < s.size(); ++i) {
    res = res && isxdigit(s[i]);
  }
  return res;
}

using namespace std;

struct HTTPRequest {
  std::string m_requestMethod, m_URI, m_httpVersion;

  RFC822Message m_msg;

  HTTPRequest() {}

  HTTPRequest(std::string const &URI, std::string const &requestMethod = "GET", 
              std::string const &requestData = "", std::string const &httpVersion = "1.1") {
    m_URI = URI;
    m_requestMethod = requestMethod;
    m_msg.m_content = requestData;
    m_httpVersion = httpVersion;
  }
  
  HTTPRequest(std::string const &URI, CGI const &cgi, std::string const &httpVersion = "1.1") {
    m_URI = URI;
    m_requestMethod = cgi.m_requestMethod;
    if (m_requestMethod.empty()) {
      m_requestMethod = "GET";
    }
    if (m_requestMethod == "GET") {
      m_URI += "?";
      size_t i = 0;
      for (CGI::CIT it = cgi.begin(); it != cgi.end(); ++it, ++i) {
        logger(ls::MINOR) << "processing parameter " << i << " " << it->first << " = " << it->second.m_content << "\n";
        if (i > 0) {
          m_URI += "&";
        }
        m_URI += it->first + "=" + CGI::urlencode(it->second());
      }
    } else if (m_requestMethod == "POST") {
      if (not cgi.m_hasFiles) {
        m_msg["Content-Type"] = string("application/x-www-form-urlencoded");
        size_t i = 0;
        for (CGI::CIT it = cgi.begin(); it != cgi.end(); ++it, ++i) {
          logger(ls::MINOR) << "processing parameter " << i << " " << it->first << "\n";
          if (i > 0) {
            m_msg.m_content += "&";
          }
          m_msg.m_content += it->first + "=" + CGI::urlencode(it->second());
        }
      } else {
        std::ostringstream str;
        RandomSource randomSource(time(0));
        string mimeBoundary = string("------") + RandomString(randomSource, 44)();
        HeaderValue ctype;
        ctype.m_content = "multipart/form-data";
        ctype["boundary"] = mimeBoundary;
        m_msg["Content-Type"] = ctype;
        for (CGI::CIT it = cgi.begin(); it != cgi.end(); ++it) {
          logger(ls::MINOR) << "processing parameter " << it->first << "\n";
          str << "\r\n--" << mimeBoundary << "\r\n";
          RFC822Message fieldMsg = it->second;
          fieldMsg["Content-Disposition"]["name"] = it->first;
          fieldMsg["Content-Disposition"].m_content = "form-data";
          str << fieldMsg;
        }
        str << "\r\n--" << mimeBoundary << "--\r\n";
        m_msg.m_content = str.str();
      }
      m_msg["Content-Length"].m_content = toString(m_msg.m_content.size());
    } else {
      cerr << "error: invalid request method " << m_requestMethod << "\n";
      exit(1);
    }
    m_httpVersion = httpVersion;
  }
  
  void printRequestLine(std::ostream &aus) const {
    aus << m_requestMethod << " " << m_URI << " " << "HTTP/" << m_httpVersion;
  }

  void print(std::ostream &aus) const {
    printRequestLine(aus);
    aus << "\r\n";
    aus << m_msg;
  }
};
std::ostream &operator << (std::ostream &aus, HTTPRequest const &r) {
  r.print(aus);
  return aus;
}

struct HTTP {

  Connection *m_connection;
  std::string m_httpVersion;
  MyMap<std::string> m_headers;
  unsigned m_nrequest;

  HTTP(Connection *connection, std::string const &httpVersion) :
    m_connection(connection),
    m_httpVersion(httpVersion),
    m_nrequest()
  { }

  ~HTTP() { }

  struct HTTPSSLReconnect {};

private:
  int readData(char *&buf, size_t const nBytes) {
    int nread, offset = 0;
    size_t nreadTotal = 0;
    if (buf != 0) {
      delete [] buf;
    }
    buf = new char[nBytes + 1];
    do {
      nread = m_connection->read(buf + offset, nBytes - offset);
      logger(ls::MINOR) << "HTTP readData: nread: " << nread << ", total " << nreadTotal << endl;
      
      if (nread <= 0) {
        int sslError = m_connection->getError(nread);
        if (m_connection->isSSL() and m_connection->isZERO_RETURN(sslError)) {
          logger(ls::WARNING) << "HTTP readData: SSL_ERROR_ZERO_RETURN (" << sslError << ") encountered" << endl;
          throw HTTPSSLReconnect();
        } else {
          logger(ls::ERROR) << "HTTP readData: " << sslError << ": " << m_connection->errorMsg(sslError) << endl;
          break;
        }
      }
      
      buf[offset + nread] = 0;
      logger(ls::MINOR) << "HTTP readData: Received " << nread << " B\n";
      // cerr << "Received data:\n" << buf + offset << "\n";
      // printf("Received %ld bytes:\n%s\n", (long) nread, buf + offset);
      
      nreadTotal += nread;

      // for (int i = 0; i < nread; ++i) {
      //   cerr << "byte " << i << ": " << buf[i] << " (" << (int)buf[i] << ")\n";
      // }
      logger(ls::MINOR) << "HTTP readData: Pending bytes: " << m_connection->pending() << "\n";
    } while(m_connection->pending() and nreadTotal < nBytes);

    return nreadTotal;
  }

  size_t readNumBytes(std::string &content, size_t const len) {
    char *buf = 0;
    while(content.size() != len) {
      unsigned long missLen = len - content.size();
      int nread = readData(buf, missLen);
      if (nread == 0) {
        cerr << "Failed to read any data, give up (Content-Length too large?)\n";
        break;
      }
      content += string(buf, nread);
    }
    delete[] buf;
    return content.size();
  }

public:

  int reconnect() {
    int res = 0;
    logger(ls::MINOR) << "HTTP reconnect: creating a new SSL connection" << endl;
    Connection *sslNew = m_connection->reconnect();
    if (sslNew) {
      delete m_connection;
      m_connection = sslNew;
      logger(ls::MAJOR) << "HTTP reconnect: Successfully reconnected..." << endl;
    } else {
      logger(ls::ERROR) << "HTTP reconnect: failed to reconnect" << endl;
      res = -1;
    }
    return res;
  }

  int readMessage(HTTPResponse &response) {
    size_t const BUF_SIZE = 100000;
    char *buf = 0;
    
    int nread = readData(buf, BUF_SIZE);

    response = HTTPResponse(buf);
    
    // cerr << "TE: " << response.m_msg.exist("Transfer-Encoding") << "\n";
    // cerr << "CL: " << response.m_msg.exist("Content-Length") << "\n";

    if (response.m_msg.exist("Content-Length")) {
      std::string cl = response.m_msg["Content-Length"];
      logger(ls::MINOR) << "Content-Length: " << cl << endl;
      if (cl.empty()) {
        logger(ls::CRITICAL) << "Content-Length header is empty" << endl;
        exit(1);
      }
      char *endPtr = 0;
      unsigned long len = strtoul(cl.c_str(), &endPtr, 10);
      if (endPtr[0] != '\0') {
        logger(ls::CRITICAL) << "invalid Content-Length header field: " << cl << endl;
        exit(1);
      }
      std::string &content = response.m_msg.m_content;
      readNumBytes(content, len);
      if (content.size() == len) {
        logger(ls::MAJOR) << "The message has been received completely, good" << endl;
      } else {
        if (content.size() < len) {
          logger(ls::WARNING) << "The message is smaller (" << content.size() << " B) than expected (" << len << " B), continue anyway" << endl;
        } else {
          logger(ls::CRITICAL) << "The message is larger (" << content.size() << " B) than expected (" << len << " B), strange" << endl;
          exit(1);
        }
      }

    } else if (response.m_msg["Transfer-Encoding"].m_content == "chunked") {
      size_t contentLength = 0;
      std::string existingContent = response.m_msg.m_content;
      std::string &content = response.m_msg.m_content;
      content = string();
      while(true) {
        if (existingContent.empty()) {
          nread = readData(buf, BUF_SIZE);
          existingContent = string(buf, nread);
        }
        logger(ls::MINOR) << "Processing chunk: " << existingContent << "\n";
        SplitText chunkParts(existingContent, "\r\n", 1);
        if (isxdigit(chunkParts[0])) {
          char *endPtr = 0;
          size_t chunkLen = strtoul(chunkParts[0].c_str(), &endPtr, 16);
          if (chunkParts[0].empty() or *endPtr != '\0') {
            cerr << "error: invalid chunk length: " << chunkParts[0]
                 << " (length " << chunkParts[0].size() << ")\n";
          }
          cerr << "chunk length: " << chunkLen << " (0x" << std::hex
               << chunkLen << std::dec << ")\n";
          if (chunkLen == 0) {
            cerr << "The chunked encoding end marker was found, good.\n";
            break;
          }
          contentLength += chunkLen;
          content += chunkParts[1].substr(0, chunkLen);
          readNumBytes(content, contentLength);
          if (chunkParts[1].size() >= chunkLen + 2) {
            existingContent = chunkParts[1].substr(chunkLen + 2);
          } else {
            existingContent = "";
            std::string crlf;
            readNumBytes(crlf, 2);
          }
        } else {
          cerr << "error: invalid chunk size line: " << chunkParts[0] << "\n";
          exit(1);
        }
      }

    } else {
      std::string &content = response.m_msg.m_content;
      char *buf = 0;
      for (int i = 0; true; ++i) {
        int nread = readData(buf, 100);
        cerr << "read until connection close (" << i+1 << "th try): " << nread << "\n";
        if (nread == 0) {
          break;
        }
        content += string(buf, nread);
      }
    }

    if (buf) {
      delete[] buf;
    }

    {
      ostream &lStr = logger(ls::MAJOR);
      lStr << "received response " << m_nrequest << ": ";
      response.printStatusLine(lStr);
      lStr << "\n";
    }
    if (adimatClientDebug) {
      std::string responseDumpFile = debugDumpDir + "/response_" + toString(m_nrequest) + ".rfc822";
      logger(ls::MAJOR) << "Debug: save response to file " << responseDumpFile << ".\n";
      toFile(responseDumpFile, response);
      responseDumpFile = debugDumpDir + "/response_" + toString(m_nrequest) + ".dat";
      toFile(responseDumpFile, response.m_msg.m_content);
    }

    return 0;
  }

  int sendRequest(HTTPRequest &request) {
    IPSocketAddress const * addr = m_connection->getAddress();
    for (MyMap<string>::CIT it = m_headers.begin(); it != m_headers.end(); ++it) {
      logger(ls::MAJOR) << "setting user-defined header " << it->first << ": " << it->second << "\n";
      request.m_msg[it->first].m_content = it->second;
    }
    if (m_httpVersion == "1.1") {
      request.m_msg["Host"].m_content = 
        m_connection->hostname() + ":" + addr->portToString();
    }
    request.m_msg["User-Agent"].m_content = string(packageName)
      + " " + adimat_getLongVersion()
      + ", " + Connection::SSL_version_string();
    string requestData;
    {
      std::ostringstream str;
      str << request;
      requestData = str.str();
    }
    ++m_nrequest;
    {
      ostream &lStr = logger(ls::MAJOR);
      lStr << "HTTP send request: request number " << m_nrequest << ": ";
      request.printRequestLine(lStr);
      lStr << "\n";
    }
    if (adimatClientDebug) {
      std::string dumpFile = debugDumpDir + "/request_" + toString(m_nrequest) + ".rfc822";
      logger(ls::MAJOR) << "Debug: save request to file " << dumpFile << ".\n";
      toFile(dumpFile, requestData);
    }
    ssize_t nwritten = m_connection->write(requestData.c_str(), requestData.size());
    logger(ls::MINOR) << "HTTP send request: wrote "
                      << nwritten << " of " << requestData.size() << " bytes.\n";
    if (nwritten != ssize_t(requestData.size())) {
      logger(ls::ERROR) << "HTTP send request: Not all bytes were written\n";
      int errc = m_connection->getError(nwritten);
      logger(ls::ERROR) << "HTTP send request: error " << errc << ": " << m_connection->errorMsg(errc) << "\n";
    }
    return 0;
  }
  
};

struct HTTPServer {
  
};

static void print_element_names(xmlNode * a_node)
{
    xmlNode *cur_node = NULL;

    for (cur_node = a_node; cur_node; cur_node = cur_node->next) {
      cerr << "node type: " << cur_node->type << "\n";
        if (cur_node->type == XML_ELEMENT_NODE) {
            xmlNs *ns = cur_node->ns;
          
            if (ns) {
              printf("node type: Element, name: {%s}%s\n", ns->href, cur_node->name);
            } else {
              printf("node type: Element, name: %s\n", cur_node->name);
            }

            xmlElement *elem = (xmlElement *) cur_node;

            for (xmlAttribute *cur_attr = elem->attributes; cur_attr; 
                 cur_attr = (xmlAttribute *)cur_attr->next) {
              print_element_names((xmlNode *)cur_attr);
            }
        } else if (cur_node->type == XML_ATTRIBUTE_NODE) {
          xmlNs *ns = cur_node->ns;
          if (ns) {
            printf("node type: Attribute, name: {%s}%s\n", ns->href, cur_node->name);
          } else {
            printf("node type: Attribute, name: %s\n", cur_node->name);
          }
        } else if (cur_node->type == XML_TEXT_NODE) {
          printf("node type: text(), content: %s\n", cur_node->content);
        } else if (cur_node->type == XML_CDATA_SECTION_NODE) {
          printf("node type: cdata(), content: %s\n", cur_node->content);
        }

        print_element_names(cur_node->children);
    }
}

static void copyParametersToCGI(MyMap<string> const &parameters, CGI &cgi) {
  for (MyMap<string>::CIT it = parameters.begin(); it != parameters.end(); ++it) {
    // logger(ls::MINOR) << "copy parameter to CGI: " << it->first << "\n";
    cgi[it->first].m_content = it->second;
  }
}

static void copyTransformParametersToCGI(MyMap<string> const &parameters, CGI &cgi) {
  int i = 1;
  for (MyMap<string>::CIT it = parameters.begin(); it != parameters.end(); ++it, ++i) {
    string const pname = "pname_" + toString(i);
    string const pvalue = "pvalue_" + toString(i);
    logger(ls::MINOR) << "copy transform parameter to CGI: " << pname << "=" << it->first << "\n";
    logger(ls::MINOR) << "copy transform parameter to CGI: " << pvalue << "=" << it->second << "\n";
    cgi[pname].m_content = it->first;
    cgi[pvalue].m_content = it->second;
  }
}

static std::string adimatServername;

static int listFilesAndAsk(std::vector<string> const &files) {
  ostream &aStr = cout;
  aStr << "The following files will be send to the adimat server (" << adimatServername << "):\n";
  for (unsigned i = 0; i < files.size(); ++i) {
    aStr << " " << i+1 << ") " << files[i] << "\n";
  }
  aStr << "There are " << files.size() << " files in total\n";
  if (args.no_ssl_flag) {
    aStr << "Warning: SSL transport encryption has been turned off!\n";
  }
  aStr << "Do you agree to send the files (please type yes or no)? " << flush;
  string userAnswer;
  cin >> userAnswer;
  if (userAnswer == "yes") {
    return 0;
  }
  return 1;
}

static void addFilesToCGI(std::vector<string> const &files, CGI &cgi) {
  cgi.m_hasFiles = not files.empty();
  if (not files.empty() and not(args.interactive_given and args.interactive_arg[args.interactive_given - 1]==0)) {
    if (listFilesAndAsk(files)) {
      return;
    }
  }
  for (unsigned i = 0; i < files.size(); ++i) {
    logger(ls::NORMAL) << "Preparing file for transmission: " << files[i] << endl;
    std::string fileName = files[i];
    std::string fileData;
    int c = readFile(fileName, fileData);
    if (c != 0) {
      logger(ls::CRITICAL) << "Could not read file " << fileName << "." << endl;
      exit(-1);
    }
    ostringstream pnamestr;
    pnamestr << "file_" << setw(3) << setfill('0') << i;
    std::string pName = pnamestr.str();
    RFC822Message fileField;
    fileField["Content-Type"].m_content = "application/octet-stream";
    HeaderValue cdisp;
    cdisp.m_content = "form-data";
    cdisp["filename"] = string("\"") + fileName + "\"";
    fileField["Content-Disposition"] = cdisp;
    fileField.m_content = fileData;
    cgi[pName] = fileField;
  }
}

void readParametersFromResponse(xmlNode * const paramNode, MyMap<std::string> &parameters) {
  logger(ls::MAJOR) << "Reading paramaters from response header\n";
  for (xmlNode *cur_node = paramNode->children; cur_node; cur_node = cur_node->next) {
    if (cur_node->type == XML_ELEMENT_NODE) {
      xmlElement *res = (xmlElement *)cur_node;
      logger(ls::MINOR) << "processing paramater element: " << res->name << "\n";
      if (strcmp((char const*)res->name, "param") == 0) {
        string pName = getAttributeContent(res, "name");
        string pValue = getNodeContent(cur_node);
        if (not pName.empty()) {
          parameters[pName] = pValue;
          logger(ls::MINOR) << "paramater " << pName << "=" << pValue << "\n";
        } else {
          logger(ls::ERROR) << "no name for parameter (value=" << pValue << "), ignored\n";
        }
      }
    }
  }
}

int downloadOutputFile(HTTP &http, std::string const &serverFileName, std::string const &requestURI, std::string const &uid, CGI const &cgi, std::string &fileData) {
  int res = 0;
  CGI newCGI(cgi.m_envVars, cgi.logContext);
  newCGI.m_requestMethod = "GET";
  newCGI[string("uid")].m_content = uid;
  newCGI[string("method-get-output")].m_content = "";
  newCGI[string("name")].m_content = serverFileName;
  
  bool received = false;
  HTTPResponse resp;

  for (int nTries = 0; nTries < args.max_reconnect_arg and not received; ++nTries) {
    try {
      HTTPRequest request(requestURI, newCGI, http.m_httpVersion);
      http.sendRequest(request);
      
      http.readMessage(resp);

      received = true;
      if (nTries > 0) {
        logger(ls::WARNING) << "Succeeded after " << nTries + 1 << " tries\n";
      }
    } catch (HTTP::HTTPSSLReconnect &) {
      http.reconnect();
    }
  }

  res = resp.m_statusCode;
  if (resp.m_statusCode != 200) {
    ostream &errStr = logger(ls::CRITICAL);
    errStr << "Server sent HTTP status line which is not OK: ";
    resp.printStatusLine(errStr);
    errStr << "\n";
    exit(1);
  } else {
    fileData = resp.m_msg.m_content;
  }

  return res;
}

struct File {
  string name;
  string fullpath;
  string data;
  
  File() {}
  File(string const &name) : name(name) {}

};

void lookupFiles(SearchPath &searchpath, std::vector<std::string> const &files, std::vector<std::string> &foundFiles, bool reportError = true) {
  for (unsigned i = 0; i < files.size(); ++i) {
    File file(files[i]);
    logger(ls::MAJOR) << "looking for file: " << files[i] << endl;
    string found = searchpath.lookup(file.name, "");
    logger(ls::MAJOR) << "found: " << found << file.name << endl;
    if (found.empty()) {
      if (reportError) {
        logger(ls::ERROR) << "File " << file.name << " not found in search path." << endl;
      }
    } else {
      foundFiles.push_back(found + file.name);
    }
  }
}

void showErrorNode(xmlElement *errorElem) {
  ostream &errStr = logger(ls::ERROR);
  prettyPrintTree(errStr, (xmlNode*)errorElem);
  errStr << "\n";
}

void writeDependencyList(ostream &depFile, xmlElement *depElem) {
  xmlElement *fList = getFirstChildElement((xmlNode *)depElem);
  if (fList == 0) {
    logger(ls::ERROR) << "The dependencies element has no child element.\n";
    return;
  }
  for (xmlNode *cur_node = fList->children; cur_node; cur_node = cur_node->next) {
    if (cur_node->type == XML_ELEMENT_NODE) {
      depFile << getNodeContent(cur_node) << "\n";
    }
  }
}

// string getUserIdFromParameters(xmlElement *docElement) {
//   xmlElement *soapHeader = getFirstChildElementByName((xmlNode*)docElement, "Header");
//   xmlElement *parameters = getFirstChildElementByName((xmlNode*)soapHeader, "parameters");
//   for (xmlNode *cur_node = paramNode->children; cur_node; cur_node = cur_node->next) {
//     if (cur_node->type == XML_ELEMENT_NODE) {
//     }
//   }
// }

static int readConfigFile(string const &fname) {
  if (not fileExists(fname)) {
    return -1;
  }
  cmdline_parser_params cmdlineParams;
  cmdline_parser_params_init(&cmdlineParams);
  cmdlineParams.initialize = 0;
  cmdlineParams.override = true;
  cmdlineParams.check_required = 0;
  int res = cmdline_parser_config_file((char*)fname.c_str(), &args, &cmdlineParams);
  return res != 0;
}

void printCopyright() {
  printf("Copyright (C) 2010-2013 Johannes Willkomm <johannes.willkomm@sc.tu-darmstadt.de>\n");
}

void printBugreportInfo() {
#ifdef PACKAGE_URL
  printf("Visit us on the web at %s\n", PACKAGE_URL);
#endif
  printf("Report bugs to %s\n", PACKAGE_BUGREPORT);
}

void printVersion() {
  cmdline_parser_print_version();
  printCopyright();
}

void printHelp() {
  cmdline_parser_print_help();
  printf("\n");
  printBugreportInfo();
}

void printFullHelp() {
  cmdline_parser_print_full_help();
  printf("\n");
  printBugreportInfo();
}

void cleanup() {
  delete loggingstream::get();
}

int main(int argc, char *argv[]) {
  atexit(&cleanup);

  if (GetEnvString("AC_DEBUG_INIT")().empty()) {
    ls::get()->setVerbLevel(ls::NORMAL);
  } else {
    ls::get()->setVerbLevel(ls::FORCE);
  }

  std::string adimatUserDir;
#ifdef __WIN32
  std::string userHome = GetEnvString("HOMEDRIVE", "c:")() + GetEnvString("HOMEPATH", "\\")();
  // std::string appDataDir = winGetFolderPath();
  // if (appDataDir.empty()) {
  //   appDataDir = GetEnvString("APPDATA", "")();
  // }
  std::string userProfDir = winGetFolderPathPersonal();
  if (userProfDir.empty()) {
    userProfDir = GetEnvString("USERPROFILE", userHome)();
  }
  adimatUserDir = GetEnvString("ADIMAT_USER_DIR", userProfDir + "/ADiMat")();
#else
  std::string userHome = "~";
  userHome = GetEnvString("HOME", userHome)();
  adimatUserDir = GetEnvString("ADIMAT_USER_DIR", userHome + "/.adimat")();
#endif

  cmdline_parser_init(&args);

  string configFileName = adimatUserDir + "/client-options";
  int rc = readConfigFile(configFileName);
  if (rc == 1) {
    std::cerr << "invalid configuration file " << configFileName << "\n";
    exit(1);
  }

  {
    cmdline_parser_params cmdlineParams;
    cmdline_parser_params_init(&cmdlineParams);
    cmdlineParams.initialize = 0;
    cmdlineParams.override = 1;
    cmdlineParams.check_required = 0;
    if (cmdline_parser_ext(argc, argv, &args, &cmdlineParams)!=0) {
      printf("Run %s --help to see the list of options\n", packageName);
      return EXIT_FAILURE;
    }
  }

  if (cmdline_parser_required(&args, argv[0]) != 0) {
    logger(ls::CRITICAL) << "invalid client configuration\n";
    exit(1);
  }

  {
    int vLevel = 5;
    if (args.verbose_given>0) {
      for (unsigned i = 0; i < args.verbose_given; ++i) {
        if (args.verbose_arg[i] != 0) {
          vLevel = args.verbose_arg[i];
        } else {
          vLevel += 2;
        }
      }
    }
    ls::get()->setVerbLevel(vLevel);
    logger(ls::MAJOR)  << "Setting verbosity level to " << vLevel << "\n";
  }

  if (args.help_given) {
    printHelp();
    return EXIT_SUCCESS;
  }

  if (args.full_help_given) {
    printFullHelp();
    return EXIT_SUCCESS;
  }

  if (args.version_given) {
    printVersion();
    return EXIT_SUCCESS;
  }

  if (args.long_version_flag) {
    printf("%s %s, %s, libxml2 %d\n", packageName, adimat_getLongVersion(), Connection::SSL_version_string(), LIBXML_VERSION);
    
    if (ls::get()->getVerbLevel() >= 7) {
      printf("Compiled against OpenSSL version 0x%lx\n", 
             Connection::SSL_compiled_version_number());
#if ADIMAT_STATIC_BUILD == 0
      printf("Using OpenSSL version 0x%lx (%s)\n", Connection::SSL_runtime_version_number(), 
             Connection::SSL_version_string());
#endif
      
      printf("Compiled against libxml2 version %d\n", LIBXML_VERSION);
#if ADIMAT_STATIC_BUILD == 0
      printf("Using libxml2 version %s\n", xmlParserVersion);
#endif
#if ADIMAT_STATIC_BUILD > 0
      printf("%s was linked statically\n", packageName);
#else
      printf("%s was linked dynamically\n", packageName);
#endif
    }

    printCopyright();
    return EXIT_SUCCESS;
  }

  {
    CurDir curDir;
    logger(ls::MINOR) << "current directory is: \"" << curDir() << "\"\n";
  }

  if (args.debug_flag) {
    adimatClientDebug = 1;
    debugDumpDir = ".adimat";
    if (not isDir(debugDumpDir)) {
      logger(ls::WARNING) << "Debug dumping directory " << debugDumpDir << " does not exist\n";
      debugDumpDir = ".";
    }
    logger(ls::WARNING) << "Writing debugging output to directory " << debugDumpDir << "\n";
  }
  LogContext logContext(debugDumpDir, 0);

#ifdef __WIN32
  int const wsmajor = args.winsock_major_arg;
  int const wsminor = args.winsock_minor_arg;
  logger(ls::MAJOR) << "Attempt to use Winsock dll version " << wsmajor << "." << wsminor << "\n";
  int wsaInit = initWSA(wsmajor, wsminor);
  if (wsaInit) {
    logger(ls::CRITICAL) << "Failed to initalize winsock dll\n";
    exit(1);
  }
#endif

  /* Init libxml */     
  xmlInitParser();
  LIBXML_TEST_VERSION

  std::string adimatHome = ADIMAT_DEFAULT_HOME;
  adimatHome = GetEnvString("ADIMAT_HOME", adimatHome)();

  logger(ls::MINOR) << "ADiMat home directory: " << adimatHome << "\n";

  logger(ls::MINOR) << "user directory: " << adimatUserDir << "\n";
  MkDir createDirectory(0700);
  if (not isDir(adimatUserDir)) {
    int mkc = createDirectory(adimatUserDir);
    if (mkc) {
      logger(ls::MINOR) << "failed to create adimat user directory\n";
      adimatUserDir = userHome;
    } else {
      logger(ls::MAJOR) << "create user directory: " << adimatUserDir << "\n";
    }
  }

  std::string savedUserId;
  /*
  std::string clientIdFileName = adimatUserDir + "/client-id";
  logger(ls::MINOR) << "using client id file: " << clientIdFileName << "\n";
  if (fileExists(clientIdFileName)) {
    readFile(clientIdFileName, savedUserId);
    savedUserId = Trim(savedUserId)();
    logger(ls::MINOR) << "user id saved in client id file: " << savedUserId << "\n";
  } else {
    logger(ls::MINOR) << "creating client id file: " << clientIdFileName << "\n";
    ofstream clientIdFile(clientIdFileName.c_str(), ios::binary);
    if (not clientIdFile) {
      logger(ls::ERROR) << "failed to create client id file: " << clientIdFileName << ": " << strerror(errno) << "\n";
      clientIdFileName.clear();
    }
  }
  */

  string outputDirectory = args.output_dir_given ? args.output_dir_arg[args.output_dir_given -1] : args.output_dir_arg[0];
  if (not isDir(outputDirectory)) {
    logger(ls::CRITICAL) << "cannot open output directory " << outputDirectory << ": " << strerror(errno) << "\n";
    exit(1);
  }

  SearchPath searchPath;
  for (unsigned i = 0 ; i < args.include_dir_given; ++i ) {
    string path = args.include_dir_arg[i];
    logger(ls::MAJOR) << "search path given: " << path << endl;
    searchPath.multiAdd(path.c_str());
  }

  std::vector<std::string> fileList;
  for (unsigned i = 0 ; i < args.inputs_num; ++i ) {
    logger(ls::MAJOR) << "arg (input file) given: " << args.inputs[i] << endl;
    fileList.push_back(args.inputs[i]);
    string dir = dirname(args.inputs[i]);
    if (not dir.empty()) {
      logger(ls::MAJOR) << "adding directory " << dir << " to search path" << endl;
      searchPath.add(dir.c_str());
    } else {
      searchPath.add(".");
    }
  }

  // get environment variable, default is args.server_arg
  // this pulls the default set for that
  adimatServername = GetEnvString("ADIMAT_SERVER", args.server_arg)();

  // but if the option is actually  given, this applies
  if (args.server_given) {
    adimatServername = args.server_arg;
  }

  logger(ls::MAJOR) << "ADiMat servername: " << adimatServername << endl;
  URI uri(adimatServername);
  logger(ls::MAJOR) << "ADiMat server URI and parts: " << uri << endl;

  std::string hostname, port, requestURI;
  //  bool useSSL = true;

  if (args.hostname_given) {
    hostname = args.hostname_arg;
  } else {
    hostname = uri.host;
  }
  if (args.port_given) {
    port = args.port_arg;
  } else {
    if (not uri.port.empty()) {
      port = uri.port;
    } else if (uri.scheme == "http") {
      port = "80";
    } else if (uri.scheme == "https") {
      port = "443";
    } else {
      port = args.port_arg;
    }
  }
  if (args.request_path_given) {
    requestURI = args.request_path_arg;
  } else {
    requestURI = uri.path;
    if (uri.path.empty() or uri.path[uri.path.size()-1] != '/') {
      requestURI += "/";
    }
    requestURI += args.cgi_path_arg;
  }
  if (not args.no_ssl_given) {
    if (uri.scheme == "http") {
      args.no_ssl_flag = true;
    }
  }
  logger(ls::MAJOR) << "Connection details: hostname='" << hostname << "', port='" << port << "', requestURI='" << requestURI << "', SSL=" << !args.no_ssl_flag << "\n";
  
  addrinfo hints;
  memset(&hints, '\0', sizeof(hints));

  hints.ai_family = AF_UNSPEC;
  if (args.ipv4_flag) {
    hints.ai_family = AF_INET;
  }
  if (args.ipv6_flag) {
    hints.ai_family = AF_INET6;
  }
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_flags = 0;
  hints.ai_protocol = IPPROTO_TCP;

  if (args.numeric_host_flag) {
    hints.ai_flags |= AI_NUMERICHOST;
  }
  if (args.numeric_port_flag) {
#ifndef __WIN32
    hints.ai_flags |= AI_NUMERICSERV;
#else
    logger(ls::WARNING) << "AI_NUMERICSERV not available on Windows\n";
#endif
  }
  if (not args.no_canonical_host_name_flag) {
    hints.ai_flags |= AI_CANONNAME;
  }

  Connection *tcpConnection = Connection::makeConnection(hostname, port, hints);

  Connection *theConnection = tcpConnection;
  Connection *sslConnection = 0;

  if (!args.no_ssl_flag) {

    std::string seed_file;
    if (args.seed_file_given) {
      seed_file = args.seed_file_arg;
    }
    
    std::string trust_file1 = adimatUserDir + "/adimat.pem";
    std::string trust_file = adimatHome + "/share/adimat/certs/adimat.pem";
    if (args.trust_store_given) {
      trust_file = args.trust_store_arg;
    } else {
      if (fileExists(trust_file1)) {
        trust_file = trust_file1;
      }
    }
    logger(ls::MINOR) << "using trust store file: " << trust_file << "\n";
    if (not fileExists(trust_file)) {
      logger(ls::ERROR) << "trust store file does not exist: " << trust_file << ": " << strerror(errno) << "\n";
    }

    std::string ciphers;
    ciphers = args.ciphers_arg;

    Connection::SSL_init();
    sslConnection = Connection::makeSSLConnection(theConnection, seed_file, trust_file, ciphers, args.check_certificate_flag, args.check_certificate_name_flag);
    theConnection = sslConnection;
  }

  std::string httpVersion = args.http_version_arg;
  if (httpVersion != "1.1" and httpVersion != "1.0" and httpVersion != "0.9") {
    cerr << "error: HTTP Protocol version must be 1.1, 1.0, or 0.9\n";
  }

  HTTP http(theConnection, httpVersion);
  for (size_t i = 0; i < args.header_given; ++i) {
    std::string headerString = args.header_arg[i];
    SplitText nameValue(headerString, ":");
    if (nameValue.size() > 1) {
      Trim trimmedValue(nameValue[1]);
      logger(ls::MAJOR) << "creating user-defined header " << nameValue[0] << ": " << trimmedValue() << "\n";
      http.m_headers[nameValue[0]] = trimmedValue();
    } else {
      logger(ls::MAJOR) << "creating empty user-defined header " << headerString << ":\n";
      http.m_headers[headerString] = "";
    }
  }
  
  AllEnvs allEnvs;

  int exit_status = 0;

  MyMap<std::string> parameters, transformParameters;
  parameters[string("output")] = "xml";
  if (not savedUserId.empty()) {
    parameters[string("uid")] = savedUserId;
  }
            
  for (size_t i = 0; i < args.cgi_param_given; ++i) {
    std::string paramString = args.cgi_param_arg[i];
    SplitText pParts(paramString, "=", 1);
    if (pParts.size() != 2) {
      std::string pName = pParts[0];
      parameters[pName] = "";
    } else {
      std::string pName = pParts[0];
      std::string pValue = pParts[1];
      parameters[pName] = pValue;
    }
  }

  for (size_t i = 0; i < args.transformation_param_given; ++i) {
    std::string paramString = args.transformation_param_arg[i];
    SplitText pParts(paramString, "=", 1);
    if (pParts.size() != 2) {
      std::string pName = pParts[0];
      transformParameters[pName] = "";
    } else {
      std::string pName = pParts[0];
      std::string pValue = pParts[1];
      transformParameters[pName] = pValue;
    }
  }

  string method = "";
  if (args.classic_forward_flag 
      or (not args.forward_flag and not args.reverse_flag
          and not args.taylor_flag
          and not args.server_version_flag
          and not args.tool_chain_given and not args.list_tool_chains_flag)) {
    method = "run-adimat";
  }
  if (args.forward_flag) {
    method = "run-admproc";
    parameters["mode"] = "forward";
  }
  if (args.taylor_flag) {
    method = "run-admproc";
    parameters["mode"] = "taylor";
  }
  if (args.reverse_flag) {
    method = "run-admproc";
    parameters["mode"] = "reverse";
  }
  if (args.tool_chain_given) {
    method = "admproc-toolchain";
    parameters["toolchain"] = args.tool_chain_arg;
  }
  if (args.server_version_flag) {
    method = "version";
  }
  method = string("method-") + method;
  parameters[method] = "1";

  logger(ls::MAJOR) << "setting method to run: " << method << "\n";

  if (args.independent_given) {
    parameters["independents"] = args.independent_arg;
  }
  if (args.dependent_given) {
    parameters["dependents"] = args.dependent_arg;
  }
  if (args.all_active_flag) {
    parameters["all-active"] = "on";
  }
  if (args.xslt_processor_given) {
    parameters["xslt-processor"] = args.xslt_processor_arg;
  }
  if (args.encoding_given) {
    parameters["encoding"] = args.encoding_arg;
  }
  if (args.unbound_given) {
    parameters["unbound"] = num2Str(args.unbound_flag);
  }
  {
    int commentLevel = 0;
    if (args.comments_given>0) {
      for (unsigned i = 0; i < args.comments_given; ++i) {
        if (args.comments_arg[i] != 0) {
          commentLevel = args.comments_arg[i];
        } else {
          ++commentLevel;
        }
      }
    }
    logger(ls::MAJOR)  << "Setting comment level to " << commentLevel << "\n";
    if (commentLevel) {
      parameters["comment-level"] = toString(commentLevel);
    }
  }


  CGI cgi(allEnvs, logContext);

  cgi.m_requestMethod = args.request_method_arg;

  copyParametersToCGI(parameters, cgi);
  copyTransformParametersToCGI(transformParameters, cgi);

  addFilesToCGI(fileList, cgi);

  HTTPRequest request(requestURI, cgi, httpVersion);

  for (size_t i = 0; i < args.header_given; ++i) {
    std::string headerString = args.header_arg[i];
    SplitText nameValue(headerString, ":");
    if (nameValue.size() > 1) {
      Trim trimmedValue(nameValue[1]);
      logger(ls::MAJOR) << "setting header " << nameValue[0] << ": " << trimmedValue() << "\n";
      request.m_msg[nameValue[0]].m_content = trimmedValue();
    } else {
      logger(ls::MAJOR) << "setting empty header " << headerString << ":\n";
      request.m_msg[headerString].m_content = "";
    }
  }

  int nrequest = 1;
  bool finished = false;

  for(; not finished; ++nrequest) {

    HTTPResponse resp;

    bool received = false;
    for (int nTries = 0; nTries < args.max_reconnect_arg and not received; ++nTries) {
      try {
        http.sendRequest(request);
        
        http.readMessage(resp);
        
        received = true;
        if (nTries > 0) {
          logger(ls::WARNING) << "Succeeded after " << nTries + 1 << " tries\n";
        }
      } catch (HTTP::HTTPSSLReconnect &) {
        http.reconnect();
      }
    }

    finished = true;

    if (resp.m_statusCode != 200) {
      ostream &errStr = logger(ls::CRITICAL);
      errStr << "Server sent HTTP status line which is not OK: ";
      resp.printStatusLine(errStr);
      errStr << "\n";
      exit(1);
      continue;
    }

    xmlDocPtr doc;
    {
      std::string killed;
      string const cleanXMLDoc = killNonXMLChars(resp.m_msg.m_content, killed);
      if (cleanXMLDoc.size() != resp.m_msg.m_content.size()) {
        logger(ls::WARNING) << "The reponse data sent by the server contains "
                            <<  resp.m_msg.m_content.size() - cleanXMLDoc.size()
                            << " non XML characters."
          " I will remove these and try to parse the result\n";
      }
      /* Load XML document */
      doc = xmlParseMemory(cleanXMLDoc.c_str(), cleanXMLDoc.size());
    }
    if (doc == NULL) {
      logger(ls::CRITICAL) << "unable to parse response body\n";
      return(-1);
    }
    
    /*Get the root element node */
    xmlNode *docElement = xmlDocGetRootElement(doc);
    // print_element_names(docElement);
    
    logger(ls::MINOR) << "document element name: " << docElement->name << "\n";
    
    MyMap<std::string> serverParameters;

    xmlElement *soapHeader = getFirstChildElementByName((xmlNode*)docElement, "Header");
    if (soapHeader) {
      xmlElement *paramNode = getFirstChildElementByName((xmlNode*)soapHeader, "parameters");
      if (paramNode) {
        readParametersFromResponse((xmlNode*)paramNode, serverParameters);
      }
    }

    string uid = serverParameters["uid"];
    /*
    if (savedUserId != uid) {
      if (not clientIdFileName.empty()) {
        logger(ls::MINOR) << "Got a new user id " << uid << ", saving to client id file: " << clientIdFileName << "\n";
        toFile(clientIdFileName, uid);
      }
    }
    */

    xmlElement *soapBody = getFirstChildElementByName((xmlNode*)docElement, "Body");
    if (soapBody) {
      logger(ls::MINOR) << "Body element: " << soapBody->name << "\n";
      
      for (xmlNode *cur_node = soapBody->children; cur_node; cur_node = cur_node->next) {
        if (cur_node->type == XML_ELEMENT_NODE) {
          xmlElement *res = (xmlElement *)cur_node;
          logger(ls::MINOR) << "Processing response element: " << res->name << "\n";
          
          if (strcmp((char const*)res->name, "error") == 0) {
            showErrorNode(res);
            logger(ls::CRITICAL) << "The server has sent an error reponse\n";
            exit(2);
          }
          
          if (strcmp((char const*)res->name, "messages") == 0) {
            cerr << getNodeContent((xmlNode*)res);
          }
          
          if (strcmp((char const*)res->name, "dependencies") == 0) {
            if (args.dependency_list_given) {
              ofstream depFile(args.dependency_list_arg, std::ios::binary);
              writeDependencyList(depFile, res);
            }
          }

          if (strcmp((char const*)res->name, "description") == 0) {
            // logger(ls::MINOR) << "The server has sent a description\n";
            logger(ls::NORMAL) << getNodeContent((xmlNode*)res) << "\n";
          }

          if (strcmp((char const*)res->name, "adimat-server-version") == 0) {
            cout << "ADiMat server version: " << getNodeContent((xmlNode*)res) << "\n";
          }
          if (strcmp((char const*)res->name, "adimat-version") == 0) {
            cout << "Server uses ADiMat version: " << getNodeContent((xmlNode*)res) << "\n";
          }

          // The function-list element is present when the
          // differentiation has succeeded. It contains the list of
          // functions. We have to check this list and see if any
          // function that is reported as builtin is present on the
          // user's search path. If that is the case these functions
          // override the builtin ones, and we have to upload these
          // files and differentiate again.

          if (strcmp((char const*)res->name, "function-list") == 0) {
            logger(ls::MAJOR) << "The server has sent a list of functions\n";

            std::vector<std::string> newFileList, newFoundFileList;
            // make a list in newFileList of all the builtin function names
            xmlElement *unboundList = getFirstChildElementByName((xmlNode*)res, "function-list");
            for (xmlNode *occElem = unboundList->children; occElem; occElem = occElem->next) {
              if (occElem->type == XML_ELEMENT_NODE) {
                if (strcmp((char const*)occElem->name, "function") == 0) {
                  string attrBuiltin = getAttributeContent((xmlElement*) occElem, "builtin");
                  if (attrBuiltin == "1") {
                    string name = getAttributeContent((xmlElement*) occElem, "name");
                    if (not name.empty()) {
                      newFileList.push_back(name + ".m");
                    }
                  }
                }
              }
            }

            // lookup the list of function names in search path
            lookupFiles(searchPath, newFileList, newFoundFileList, false);

            if (not newFoundFileList.empty()) {
              // is any file was found, set finished to false and prepare a new request
              logger(ls::NORMAL) << "Found " << newFoundFileList.size() << " additional m-file functions, resubmitting the request\n";
              finished = false;
            
              parameters[string("uid")] = uid;
              parameters[string("rerun")] = "1";
              
              CGI newCGI(allEnvs, logContext);
              newCGI.m_requestMethod = "POST";
              
              copyParametersToCGI(parameters, newCGI);
              copyTransformParametersToCGI(transformParameters, newCGI);
              
              addFilesToCGI(newFoundFileList, newCGI);
              
              request = HTTPRequest(requestURI, newCGI, httpVersion);
            }

          }

          // The element differentiated-file is present when the
          // differentiation process was succesful. It contains a link
          // to an output file to download. However, if finished ==
          // false, then there are some functions shadowing a builtin,
          // which we have to upload first (see preceding if)
          if (strcmp((char const*)res->name, "differentiated-file") == 0) {
            logger(ls::MAJOR) << "The server has produced a file!\n";
            if (not finished) {
              logger(ls::MAJOR) << "But we are not finisehd yet\n";
            } else {
              xmlElement *fileElem = getFirstChildElementByName((xmlNode*)res, "output-file");
              if (fileElem) {
                string serverFileName = getAttributeContent(fileElem, "name");
                string fileData;
                int status = downloadOutputFile(http, serverFileName, requestURI, uid, cgi, fileData);
                string fileType = getAttributeContent(fileElem, "content-type");
                string fileSize = getAttributeContent(fileElem, "size");
                if ((unsigned) atoi(fileSize.c_str()) != fileData.size()) {
                  logger(ls::ERROR) << "file size is not equal to size attribute: "
                                    << fileData.size() << " != " << fileSize << "\n";
                }
                if (status == 200) {
                  if (args.stdout_flag 
                      or (args.output_given and string(args.output_arg) == "-")
                      or (args.tool_chain_given and not args.output_given)) {
                    cout << fileData;
                  } else {
                    string fileName;
                    if (args.output_given) {
                      fileName = args.output_arg;
                    } else {
                      fileName = outputDirectory + "/" + serverFileName;
                    }
                    if (not fileName.empty()) {
                      logger(ls::MAJOR) << "Saving file " << serverFileName << ", size " << fileSize
                                        << " B, type " << fileType << "\n";
                      logger(ls::NORMAL) << "Saving file to " << fileName << "\n";
                      toFile(fileName, fileData);
                    } else {
                      logger(ls::ERROR) << "file name could not be determined, not saving\n";
                    }
                  }
                } else {
                  logger(ls::ERROR) << "Failed to download file\n";
                }
              } else {
                logger(ls::ERROR) << "Element file is missing\n";
              }
            }
          }

          // The element file-request (or dependent-files) is present when the
          // differentitation process failed with unbound identifiers.
          // Note: dependent-files has been introduced to avoid
          // problems with older clients
          // FIXME: in some time, merge file-request and
          // dependent-files again
          if (strcmp((char const*)res->name, "file-request") == 0
              or strcmp((char const*)res->name, "dependent-files") == 0) {
            logger(ls::MAJOR) << "The server has sent a request (" << res->name << ") for more files\n";

            std::vector<std::string> newFileList, newFoundFileList;
            xmlElement *unboundList = getFirstChildElementByName((xmlNode*)res, "unbound-identifiers");
            for (xmlNode *occElem = unboundList->children; occElem; occElem = occElem->next) {
              if (occElem->type == XML_ELEMENT_NODE) {
                if (strcmp((char const*)occElem->name, "occurence") == 0) {
                  string name = getAttributeContent((xmlElement*) occElem, "name");
                  if (not name.empty()) {
                    newFileList.push_back(name + ".m");
                  }
                }
              }
            }

            lookupFiles(searchPath, newFileList, newFoundFileList);
            
            if (not newFoundFileList.empty()) {
              finished = false;

              parameters[string("uid")] = uid;
              parameters[string("rerun")] = "1";
              
              CGI newCGI(allEnvs, logContext);
              newCGI.m_requestMethod = "POST";
              
              copyParametersToCGI(parameters, newCGI);
              copyTransformParametersToCGI(transformParameters, newCGI);
              
              addFilesToCGI(newFoundFileList, newCGI);
              
              request = HTTPRequest(requestURI, newCGI, httpVersion);

            }

            if (newFoundFileList.size() < newFileList.size()) {
              if (args.unbound_given) {
                exit_status = 0;
              } else {
                exit_status = 3;
              }
            }
          }
          
        }
      }
    }

    xmlFreeDoc(doc);
    doc = 0;
  }

  xmlCleanupParser();

  bool const isSSL = http.m_connection->isSSL();
  
  http.m_connection->close();

  delete http.m_connection; // also deletes the underlying TCPConnection, if this is an SSLConnection
  http.m_connection = 0;

  if (isSSL) {
    Connection::SSL_cleanup();
  }

  cmdline_parser_free(&args);

#ifdef __WIN32
  shutdownWSA();
#endif

  return exit_status;

}
