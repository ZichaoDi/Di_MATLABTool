#ifndef adimat_web_util_hh
#define adimat_web_util_hh

#include <locale>
#include <fstream>
#include "loggingstream.h"

std::string num2Str(long int n) {
  std::ostringstream str;
  str << n;
  return str.str();
}

template<class T>
std::string toString(T const &v) {
  std::ostringstream str;
  str << v;
  return str.str();
}

long int toInt(std::string const &s) {
  long int n = 0;
  char *endp = 0;
  long _n = strtol(s.c_str(), &endp, 10);
  if (not s.empty() && *endp == 0) {
    n = _n;
  }
  return n;
}

template<class T>
std::string toUpper(T const &v, std::locale const &loc = std::locale()) {
  std::string res(v);
  for (size_t i = 0; i < v.size(); ++i) {
    res[i] = toupper(v[i], loc);
  }
  return res;
}

template<class T>
std::string toXML(T const &v, std::string const &indent = "") {
  std::ostringstream str;
  v.writeXML(str, indent);
  return str.str();
}

template<class T>
int toFile(std::string const &fname, T const &v) {
  std::ofstream str(fname.c_str(), std::ios::binary);
  if (not str) {
    std::cerr << "failed to open file: " << fname << ": " << strerror(errno) << "\n";
    return errno;
  }
  str << v;
  return 0;
}

template<class T>
int toFileXML(std::string const &fname, T const &v) {
  std::ofstream str(fname.c_str(), std::ios::binary);
  if (not str) {
    std::cerr << "failed to open file: " << fname << ": " << strerror(errno) << "\n";
    return errno;
  }
  v.writeXML(str);
  return 0;
}

int readFile(std::string const &fileName, std::string &fileData) {
  fileData.clear();
  struct stat st;
  int c = stat(fileName.c_str(), &st);
  if (c == 0) {
    std::ifstream inFile(fileName.c_str(), std::ios::binary);
    if (inFile) {
      fileData.resize(st.st_size);
      inFile.read((char*)fileData.data(), st.st_size);
    } else {
      logger(ls::ERROR) << "failed to open file for reading: " << fileName
                        << ": " << strerror(errno) << "\n";
      return -1;
    }
  } else {
    logger(ls::ERROR) << "File " << fileName << " not found: " << strerror(errno) << "." << std::endl;
    return -1;
  }
  return 0;
}

std::string unquote(std::string const &val) {
  if (val.size() >= 2 and val[0] == '"' and val[val.size()-1] == '"') {
    return val.substr(1, val.size() - 2);
  }
  return val;
}

std::string toLower(std::string const &val) {
  std::string res;
  res.resize(val.size());
  for (unsigned i = 0; i < val.size(); ++i) {
    res[i] = tolower(val[i]);
  }
  return res;
}

std::string notDir(std::string const &path) {
  std::string res = path;
  size_t lastSlash = path.find_last_of("/\\");
  if (lastSlash != std::string::npos) {
    res = path.substr(lastSlash + 1);
  }
  return res;
}

std::string dirname(std::string const &path) {
  std::string res;
  size_t lastSlash = path.find_last_of("/\\");
  if (lastSlash != std::string::npos) {
    res = path.substr(0, lastSlash);
  }
  return res;
}

bool isXMLChar(unsigned const c) {
  return c == 0x9 or c == 0xa or c == 0xd
    or (c >= 0x20 and c <= 0xD7FF)
    or (c >= 0xE000 and c <= 0xFFFD)
    or (c >= 0x10000 and c <= 0x10FFFF);
}

bool isXMLChar(std::string const &s) {
  bool res = true;
  for(size_t i = 0; i < s.size(); ++i) {
    res = res && isXMLChar(s[i]);
  }
  return res;
}

std::string killNonXMLChars(std::string const &s, std::string &killed) {
  std::string res;
  for(size_t i = 0; i < s.size(); ++i) {
    unsigned char c = s[i];
    if (isXMLChar(c)) {
      res += c;
    } else {
      killed += c;
    }
  }
  return res;
}

std::string escapeXMLChars(std::string const &s) {
  std::string res;
  for(size_t i = 0; i < s.size(); ++i) {
    if (isXMLChar(s[i])) {
      res += s[i];
    }
  }
  return res;
}

#endif
