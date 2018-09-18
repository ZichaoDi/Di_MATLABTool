#include <string>

struct URI {
  std::string const uri;

  std::string scheme;

  std::string authority;
  std::string userInfo, host, port;

  std::string path, query, fragment;

  bool isHierarchical, isValid;

  URI(std::string const &uri) : uri(uri), isHierarchical(), isValid() {
    parse();
  }

  void parse() {
    size_t colp = uri.find(":");
    if (colp == std::string::npos) {
      std::cerr << "error: the URI scheme (http, https) is missing\n";
      return;
    } 
    scheme = uri.substr(0, colp);
    std::string remainder = uri.substr(colp+1);

    size_t const hashp = remainder.find_first_of("#");
    if (hashp != std::string::npos) {
      fragment = remainder.substr(hashp);
      remainder = remainder.substr(0, hashp);
    }

    size_t const qp = remainder.find_first_of("?");
    if (qp != std::string::npos) {
      query = remainder.substr(qp);
      remainder = remainder.substr(0, qp);
    }

    if (remainder.size() >= 2 and remainder[0] == '/' and remainder[1] == '/') {
      isHierarchical = true;

      remainder = remainder.substr(2);
      size_t const slp = remainder.find_first_of("/");
      
      if (slp != std::string::npos) {
        authority = remainder.substr(0, slp);
        path = remainder.substr(slp);
      } else {
        authority = remainder;
      }

      host = authority;
      size_t const atp = host.find_first_of("@");
      if (atp != std::string::npos) {
        userInfo = host.substr(0, atp);
        host = host.substr(atp+1);
      }
      size_t const colp = host.find_first_of(":");
      if (colp != std::string::npos) {
        port = host.substr(colp+1);
        host = host.substr(0, colp);
      }
    } else {
      isHierarchical = false;
      path = remainder;
    }

    isValid = true;
  }

  void print(std::ostream &aus) const {
    aus << "URI(" << uri << ","
      "scheme='" << scheme << "',"
      "authority='" << authority << "',"
      "userInfo='" << userInfo << "',"
      "host='" << host << "',"
      "port='" << port << "',"
      "path='" << path << "',"
      "query='" << query << "',"
      "fragment='" << fragment << "')"
      ;
  }

};

inline std::ostream &operator <<(std::ostream &aus, URI const &u) {
  u.print(aus);
  return aus;
}
