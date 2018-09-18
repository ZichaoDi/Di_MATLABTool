#include <assert.h>
#include "rfc822-message.hh"
#include "logcontext.hh"
#include "xmlutil.h"

// #define Debug_CGI

struct CGI : public MyMap<RFC822Message> {
  typedef AllEnvs EnvVarMap;

  LogContext &logContext;
  EnvVarMap const &m_envVars;
  std::string m_postData;
  HeaderValue m_contentType;
  std::string m_requestMethod;
  bool m_fail, m_hasFiles;
  std::string const validNameChars;
  std::string const validValueChars;

  CGI(AllEnvs const &envVars, LogContext &logContext) : 
    logContext(logContext),
    m_envVars(envVars),
    m_contentType(m_envVars["CONTENT_TYPE"]),
    m_fail(), 
    m_hasFiles(),
    validNameChars("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"),
    validValueChars(validNameChars + " \"?.,@:#+")
  {
  }

  void parseRequest() {
    std::string contentTypeStr = m_envVars["CONTENT_TYPE"];
#ifdef Debug_CGI
    fprintf(stderr, "cgi: contentType string: %s\n", contentTypeStr.c_str());
#endif
    m_requestMethod = getRequestMethod();
    if (m_requestMethod == "GET") {
      parseGetRequest();
    } else if (m_requestMethod == "POST") {
      parsePostRequest();
    } else {
      fprintf(stderr, "error: cgi: request method %s not handled\n", m_requestMethod.c_str());
      m_fail = true;
    }
  }
  
  bool isValidParameterName(std::string const &fname) const {
    bool const allLettersValid = fname.find_first_not_of(validNameChars) == std::string::npos;
    return allLettersValid and fname.size() > 0 and fname.size() < 100;
  }

  bool isValidParameterValue(std::string const &fname) const {
    bool const allLettersValid = fname.find_first_not_of(validValueChars) == std::string::npos;
    return allLettersValid and fname.size() < 100;
  }

  bool isValidAdmprocParameterValue(std::string const &fname) const {
    bool const allLettersValid = fname.find_first_not_of(validValueChars) == std::string::npos;
    return allLettersValid and fname.size() < 100;
  }

  void insert(std::string const &name, std::string const &value) {
    if (not isValidParameterName(name)) {
      std::cerr << "parameter with invalid name ignored: " << urlencode(name) << "\n";
      return;
    }
    if (not isValidParameterValue(value)) {
      std::cerr << "parameter with invalid value ignored: " << urlencode(value) << "\n";
      return;
    }
    RFC822Message msg;
    msg.m_content = value;
    m_map.insert(make_pair(name, msg));
  }

  void parseGetRequest() {
    std::string queryString = m_envVars["QUERY_STRING"];
    parseQueryString(queryString);
  }

  void parseQueryString(std::string const &queryString) {
    SplitText params(queryString, "&");
    for (size_t i = 0; i < params.size(); ++i) {
      std::string param = params[i];
      SplitText parts(param, "=", 1);
      if (parts.size() == 2) {
        insert(parts[0], urldecode(parts[1]));
      } else {
        std::cerr << "error: invalid param=value pair: " << param << "\n";
      }
    }
  }

  void parsePostRequest() {
    if (m_contentType() != "application/x-www-form-urlencoded"
        and m_contentType() != "multipart/form-data") {
      fprintf(stderr, "error: cgi: parsePostRequest: wrong contentType %s, request ignored\n", m_contentType().c_str());
      m_fail = true;
      return;
    }
    std::string contentLength = m_envVars["CONTENT_LENGTH"];
#ifdef Debug_CGI
    fprintf(stderr, "cgi: contentLength: %s\n", contentLength.c_str());
#endif
    std::string postData = readPostData(contentLength);
#ifdef Debug_CGI
    fprintf(stderr, "cgi: POST data: %s\n", postData.c_str());
    fprintf(stderr, "cgi: POST data END\n");
#endif
    if (not postData.empty()) {
      if (m_contentType() == "application/x-www-form-urlencoded") {
        parsePostDataUrlencoded(postData, m_contentType);
      } else if (m_contentType() == "multipart/form-data") {
        parsePostDataMultipart(postData, m_contentType);
      }
    }
  }
  
  void parsePostDataUrlencoded(std::string const &postData, HeaderValue const &) {
    parseQueryString(postData);
  }

  void parsePostDataMultipart(std::string const &postData, HeaderValue const &contentType) {
    std::string boundary = "--" + contentType["boundary"];
#ifdef Debug_CGI
    fprintf(stderr, "cgi: Multipart boundary: %s\n", boundary.c_str());
#endif
    SplitText parts(postData, boundary);
    // part 0 is the whitespace before first boundary
    for (size_t i = 1; i < parts.size(); ++i) {
      if (parts[i][0] == '-' and parts[i][1] == '-') {
        if (i != parts.size() - 1) {
          fprintf(stderr, "error: cgi: part starts with double hyphen --, "
                  "but is not the last part (%ld/%ld)!?\n",i,parts.size());
        }
        break;
      }
      std::string partData = parts[i].substr(2, parts[i].size() - 4);
#ifdef Debug_CGI
      fprintf(stderr, "cgi: part %ld: >>%s<<\n", i, partData.c_str());
#endif
      RFC822Message partHeaders(partData, true);
#ifdef Debug_CGI
      fprintf(stderr, "cgi: part %ld: num headers: %ld, body length: %ld\n", i, partHeaders.size(), partHeaders().size());
      for (RFC822Message::CIT it = partHeaders.begin(); it != partHeaders.end(); ++it) {
        HeaderValue hv = it->second;
        fprintf(stderr, "cgi: header %s: %s\n", it->first.c_str(), it->second().c_str());
        for (HeaderValue::CIT jt = hv.begin(); jt != hv.end(); ++jt) {
          fprintf(stderr, "cgi: header param %s=%s\n", jt->first.c_str(), jt->second.c_str());
        }
      }
#endif
      HeaderValue contentDisposition = partHeaders["Content-Disposition"];
      if (contentDisposition() != "form-data") {
        fprintf(stderr, "error: cgi: invalid value for Header Content-Disposition in field %ld: '%s' (request ignored)\n", 
                i, contentDisposition().c_str());
        m_fail = 1;
        return;
      }
#ifdef Debug_CGI
      fprintf(stderr, "cgi: checking header contentDisposition: main value '%s', params: %ld\n", 
              contentDisposition().c_str(), contentDisposition.size());
      for (HeaderValue::CIT jt = contentDisposition.begin(); jt != contentDisposition.end(); ++jt) {
        fprintf(stderr, "cgi: contentDisposition param %s=%s\n", jt->first.c_str(), jt->second.c_str());
      }
#endif
      std::string fieldName = contentDisposition["name"];
      if (fieldName.empty()) {
        fprintf(stderr, "error: cgi: no field name in header content-disposition,"
                " or field name is empty, field ignored\n");
        return;
      }
      if (not isValidParameterName(fieldName)) {
        fprintf(stderr, "error: cgi: invalid field name '%s', field ignored\n", urlencode(fieldName).c_str());
        return;
      }
      if (not isFileField(partHeaders)) {
        if (not isValidParameterValue(partHeaders.m_content)) {
          fprintf(stderr, "error: cgi: invalid field value '%s', field ignored\n", urlencode(partHeaders.m_content).c_str());
          return;
        }
      }
#ifdef Debug_CGI
      fprintf(stderr, "cgi: field is named '%s'\n", fieldName.c_str());
#endif

      m_map.insert(make_pair(fieldName, partHeaders));
      
    }
  }

  std::string readPostData(std::string const &contentLength) {
    char *endPtr = 0;
    long const nBytes = strtol(contentLength.c_str(), &endPtr, 10);
    std::string result;
    if (contentLength.size() > 0 and *endPtr == 0) {
      if (nBytes < 0 or nBytes > 1024 * 1024) {
        fprintf(stderr, "error: cgi: readPostData: post Data to large (%ld), request ignored\n", nBytes);
        m_fail = true;
        return result;
      }
      result.resize(nBytes);
      size_t nread = fread((char*)result.data(), nBytes, 1, stdin);
      if (nread != 1) {
        fprintf(stderr, "error: cgi: readPostData: failed to read entire data, request ignored\n");
        m_fail = true;
        result.resize(0);
      }
      {
        std::string postDataLog = logContext.logDirName + "/post.dat";
        toFile(postDataLog, result);
      }
    } else {
      fprintf(stderr, "error: cgi: readPostData: wrong contentLength %s, request ignored\n", contentLength.c_str());
      m_fail = true;
    }
    return result;
  }
  
  operator bool() const { return m_fail; }

  std::string getRequestMethod() const { return m_envVars["REQUEST_METHOD"]; }

  static bool isFileField(RFC822Message const &msg) {
    HeaderValue const &cDisp = msg["Content-Disposition"];
    if (cDisp().size()) {
      std::string const &fileName = cDisp["filename"];
      if (not fileName.empty()) {
        return true;
      }
    }
    return false;
  }

  void writeHTML(std::ostream &aus) const {
    aus << "<table>\n";
    for(CIT it = begin(); it != end(); ++it) {
      aus << "<tr>\n";
      aus << "<th>" << it->first << "</th>\n";
      aus << "<td>\n";
      RFC822Message const &msg = it->second;
      HeaderValue const cDisp = msg["Content-Disposition"];
      HeaderValue const cType = msg["Content-Type"];
      if (isFileField(msg)) {
        std::string const &fileName = cDisp["filename"];
        aus << "file(" << fileName << ", content-type="
            << cType.m_content << ", size=" << msg.m_content.size() << ")\n";
      } else {
        aus << it->second() << "\n";
      }
      aus << "</td>\n";
      aus << "</tr>\n";
    }
    aus << "</table>\n";
  }

  void writeXML(std::ostream &aus, std::string const &indent = "") const {
    aus << indent << "<adm:cgi-parameters>\n";
    for(CIT it = begin(); it != end(); ++it) {
      aus << indent << indentUnit << "<adm:cgi-param name='" << it->first << "'>";
      RFC822Message const &msg = it->second;
      HeaderValue const cDisp = msg["Content-Disposition"];
      HeaderValue const cType = msg["Content-Type"];
      if (isFileField(msg)) {
        std::string const &fileName = cDisp["filename"];
        aus << "<adm:input-file name='" << notDir(fileName) << "' full-name='" << fileName
            << "' content-type='" << cType.m_content
            << "' size='" << msg.m_content.size() << "'/>";
      } else {
        aus << it->second();
      }
      aus << "</adm:cgi-param>\n";
    }
    aus << indent << "</adm:cgi-parameters>\n";
  }

  static std::string urldecode(std::string const &str) {
    std::string res;
    res.resize(str.length());
    size_t resi = 0;
    char hexbuf[3] = {0};
    for(size_t i = 0; i < str.size(); ++i) {
      char const c = str[i];
      switch(c) {
      case '%':
        if (i + 2 < str.size()) {
          hexbuf[0] = str[i + 1];
          hexbuf[1] = str[i + 2];
          if (isxdigit(hexbuf[0]) and isxdigit(hexbuf[0])) {
            unsigned code = strtol(hexbuf, 0, 16);
            assert(code < 256);
            res[resi] = code;
            i+= 2;
            ++resi;
          } else {
            std::cerr << "invalid url encoded string (invalid hex number): " << str << "\n";
          }
        } else {
          std::cerr << "invalid url encoded string (too short): " << str << "\n";
        }
        break;
      case '+':
        res[resi] = ' ';
        ++resi;
        break;
      default:
        res[resi] = c;
        ++resi;
        break;
      }
    }
    std::string result = res.substr(0, resi);
    return result;
  }

  static std::string urlencode(std::string const &str) {
    std::ostringstream res;
    char hexbuf[3] = {0};
    for(size_t i = 0; i < str.size(); ++i) {
      unsigned char const c = str[i];
      if ((c >= 'a' and c <= 'z')
          or (c >= 'A' and c <= 'Z')
          or (c >= '0' and c <= '9')
          or c == '*' or c == '-' or c == '_' or c == '.') {
        res << c;
      } else if (c == ' ') {
        res << '+';
      } else {
        unsigned code = c;
#ifndef NDEBUG
        int n = 
#endif
          snprintf(hexbuf, 3, "%.2x", code);
        assert(n == 2);
        res << '%' << hexbuf[0] << hexbuf[1];
      }
    }
    return res.str();
  }

};

inline std::ostream &operator << (std::ostream &aus, CGI const &r) {
  r.writeXML(aus);
  return aus;
}

