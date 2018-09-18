#include "loggingstream.h"

struct HTTPResponse {
  std::string m_statusLine, m_httpVersion, m_statusMessage;
  int m_statusCode;
  RFC822Message m_msg;

  HTTPResponse() : m_statusCode() {}

  HTTPResponse(std::string const &dataStr) {
    size_t offset = 0, found = 0;
    found = dataStr.find("\r\n", offset);
    for (size_t i = 0; found != dataStr.npos and i < 1; ++i) {
      std::string line = dataStr.substr(offset, found - offset);
      logger(ls::MINOR) << "response line: '" << line << "'\n";
      m_statusLine = line;
    }
    SplitText statusParts(m_statusLine, " ", 2);
    if (statusParts.size() != 3) {
      logger(ls::CRITICAL) << "invalid status line in response: " << m_statusLine << "\n";
      exit(1);
    }
    m_httpVersion = statusParts[0];
    m_statusMessage = statusParts[2];
    char *endPtr;
    m_statusCode = strtol(statusParts[1].c_str(), &endPtr, 10);
    if (statusParts[1].empty()) {
      std::cerr << "error: HTTP status code string could not be found: "
                << m_statusLine << "\n";
      exit(1);
    }
    if (*endPtr != '\0') {
      std::cerr << "error: invalid HTTP status code: " << statusParts[1] << "\n";
      exit(1);
    }
    if (m_statusMessage.empty()) {
      std::cerr << "error: HTTP status message is missing: " << m_statusLine << "\n";
      exit(1);
    }
    logger(ls::MAJOR) << "HTTP status: " << m_httpVersion << ", code " << m_statusCode
                      << ", \"" << m_statusMessage << "\"\n";
    m_msg = RFC822Message(dataStr.substr(found + 2), true);
  }

  void printStatusLine(std::ostream &aus) const {
    aus << m_httpVersion << " " << std::dec << m_statusCode << " " << m_statusMessage;
  }

  void print(std::ostream &aus) const {
    printStatusLine(aus);
    aus << "\n" << m_msg;
  }
};

inline std::ostream &operator << (std::ostream &aus, HTTPResponse const &r) {
  r.print(aus);
  return aus;
}
