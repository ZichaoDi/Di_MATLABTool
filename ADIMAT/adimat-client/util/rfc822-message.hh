#ifndef adimat_rfc822_message_hh
#define adimat_rfc822_message_hh

#include "envvars.hh"
#include "splittext.hh"
#include "web-util.hh"

// #define Debug_RFC822

struct Trim {
  std::string m_str;
  Trim(std::string const &str) : 
    m_str(str) 
  {
    size_t fNonWhite = m_str.find_first_not_of(" \n\t\r");
    if (fNonWhite != m_str.npos) {
      m_str.erase(0, fNonWhite);
    } else {
      m_str.clear();
    }
    size_t lNonWhite = m_str.find_last_not_of(" \n\t\r");
    if (lNonWhite != m_str.npos) {
      m_str.erase(lNonWhite + 1, m_str.size());
    }
  }
  std::string const &operator()() const { return m_str; }
};

struct HeaderValue : public MyMap<std::string> {

  std::string m_content;

  HeaderValue() {}

  HeaderValue(std::string const &headerFieldStr) {
#ifdef Debug_RFC822
    fprintf(stderr, "cgi: parse header value: %s\n", headerFieldStr.c_str());
#endif
    SplitText contentTypeParts(headerFieldStr, ";");
    m_content = contentTypeParts[0];
#ifdef Debug_RFC822
    fprintf(stderr, "cgi: main header value: %s\n", m_content.c_str());
#endif
    for (size_t i = 1; i < contentTypeParts.size(); ++i) {
      Trim contentTypePart(contentTypeParts[i]);
#ifdef Debug_RFC822
      fprintf(stderr, "cgi: header value field: %s\n", contentTypePart().c_str());
#endif
      SplitText parts(contentTypePart(), "=", false);
      if (parts.size() == 2) {
        std::string unquoted = unquote(parts[1]);
        m_map.insert(make_pair(parts[0], unquoted));
#ifdef Debug_RFC822
        fprintf(stderr, "cgi: header value param: '%s'='%s'\n", parts[0].c_str(), parts[1].c_str());
#endif
      } else {
        fprintf(stderr, "error: cgi: illegal parameter to header value (ignored): %s\n", contentTypeParts[i].c_str());
      }
    }
  }
  
  operator std::string const &() const {
    return m_content;
  }
  std::string const &operator()() const {
    return m_content;
  }

  void print(std::ostream &aus) const {
    aus << m_content;
    for (CIT it = begin(); it != end(); ++it) {
      aus << "; " << it->first << "=" << it->second;
    }
  }
};
std::ostream &operator << (std::ostream &aus, HeaderValue const &r) {
  r.print(aus);
  return aus;
}


struct HeaderMultiValue : public MyList<HeaderValue> {

  HeaderMultiValue() {}

  HeaderMultiValue(std::string const &headerFieldStr) {
#ifdef Debug_RFC822
    fprintf(stderr, "cgi: parse header multi-value: %s\n", headerFieldStr.c_str());
#endif
    SplitText contentTypeParts(headerFieldStr, ",");
    for (size_t i = 0; i < contentTypeParts.size(); ++i) {
      Trim contentTypePart(contentTypeParts[i]);
#ifdef Debug_RFC822
      fprintf(stderr, "cgi: header multi-value field: %s\n", contentTypePart().c_str());
#endif
      HeaderValue hv(contentTypePart());
      m_list.push_back(hv);
    }
  }
  
  void print(std::ostream &aus) const {
    int i = 0;
    for (CIT it = begin(); it != end(); ++it, ++i) {
      if (i > 0) {
        aus << ", ";
      }
      aus << *it;
    }
  }
};
std::ostream &operator << (std::ostream &aus, HeaderMultiValue const &r) {
  r.print(aus);
  return aus;
}


struct RFC822Message : public MyMap<HeaderValue> {

  std::string m_content;

  RFC822Message() {}

  RFC822Message(std::string const &dataStr) : 
    m_content(dataStr) 
  {}

  RFC822Message(std::string const &dataStr, bool) {
    size_t offset = 0, found = 0;
    found = dataStr.find("\r\n", offset);
    for (size_t i = 0; found != dataStr.npos; ++i) {
      std::string line = dataStr.substr(offset, found - offset);
#ifdef Debug_RFC822
      fprintf(stderr, "cgi: RFC822 line: '%s'\n", line.c_str());
#endif
      if (line.empty()) {
        m_content = dataStr.substr(offset + 2);
#ifdef Debug_RFC822
        fprintf(stderr, "cgi: RFC822 body: '%s'\n", m_content.c_str());
#endif
        break;
      }
      SplitText parts(line, ": ", false);
      if (parts.size() == 2) {
#ifdef Debug_RFC822
        fprintf(stderr, "cgi: RFC822 header: '%s': '%s'\n", parts[0].c_str(), parts[1].c_str());
#endif
        HeaderValue hv(parts[1]);
        std::pair<IT, bool> ires = m_map.insert(make_pair(parts[0], hv));
        if (not ires.second) {
          fprintf(stderr, "error: cgi: duplicate RFC822 header (ignored): %s\n", line.c_str());
        }
#ifdef Debug_RFC822
        fprintf(stderr, "cgi: RFC822 main value: '%s', number of parameters %ld\n", hv().c_str(), hv.size());
        fprintf(stderr, "cgi: RFC822 main value: '%s', number of parameters %ld\n", 
                ires.first->second().c_str(), ires.first->second.size());
#endif
      } else {
        fprintf(stderr, "error: cgi: illegal RFC822 header (ignored): %s\n", line.c_str());
      }
      offset = found + 2;
      found = dataStr.find("\r\n", offset);
    }
  }
  
  operator std::string const &() const {
    return m_content;
  }
  std::string const &operator()() const {
    return m_content;
  }

  void printHeaders(std::ostream &aus, std::string const &sep = "\r\n") const {
    for (CIT it = begin(); it != end(); ++it) {
      aus << it->first << ": " << it->second << sep;
    }
  }
  void print(std::ostream &aus) const {
    printHeaders(aus);
    aus << "\r\n";
    aus << m_content;
  }
};

std::ostream &operator << (std::ostream &aus, RFC822Message const &r) {
  r.print(aus);
  return aus;
}

#endif
