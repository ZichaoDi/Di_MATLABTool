#ifndef adimat_util_envvars_hh
#define adimat_util_envvars_hh
#include <map>
#include <vector>

extern "C" char **environ;

// struct StringMap {
//   typedef std::map<std::string, std::string> StringMap;
//   typedef StringMap::const_iterator CIT;
//   typedef StringMap::iterator IT;

//   StringMap m_envVars;
// };

struct GetEnvString {
  std::string value;
  bool present;
  GetEnvString(std::string const &vname, std::string const &def = "") : 
    value(def),
    present()
  {
    char const *envString = ::getenv(vname.c_str());
    if (envString) {
      present = 1;
      value = envString;
    }
  }

  operator std::string const &() const { return this->value; }
  std::string const &operator()() const { return this->value; }

  operator bool() const { return this->good(); }
  bool good() const { return this->present; }
  bool fail() const { return !this->good(); }
};

template<class T, class Key=std::string>
struct MyMap {
  typedef T value_type;
  typedef Key key_type;
  typedef typename std::map<key_type, value_type> ParamMap;
  typedef typename ParamMap::const_iterator CIT;
  typedef typename ParamMap::iterator IT;
  typedef typename std::map<key_type, value_type>::iterator iterator;
  typedef typename std::map<key_type, value_type>::const_iterator const_iterator;

  ParamMap m_map;

  ParamMap const &getMap() { return m_map; }

  size_t size() const { return m_map.size(); }

  CIT begin() const { return m_map.begin(); }
  CIT end() const { return m_map.end(); }
  IT begin() { return m_map.begin(); }
  IT end() { return m_map.end(); }

  std::pair<iterator, bool> insert(std::pair<key_type, value_type> const &p) { return m_map.insert(p); }

  value_type &operator[](key_type const &key) {
    return m_map[key];
  }
  value_type operator[](key_type const &key) const {
    value_type res;
    CIT it = m_map.find(key);
    if (it != m_map.end()) {
      res = it->second;
    }
    return res;
  }
  value_type operator()(key_type const &key) const {
    value_type res;
    CIT it = m_map.find(key);
    if (it != m_map.end()) {
      res = it->second;
    }
    return res;
  }
  bool exist(key_type const &key) const {
    bool res = 0;
    CIT it = m_map.find(key);
    if (it != m_map.end()) {
      res = 1;
    }
    return res;
  }
  size_t count(key_type const &key) const {
    return m_map.count(key);
  }

};

struct AllEnvs : public MyMap<std::string> {
  char const * const *m_envVarField;
  
  AllEnvs(char **envVarField = environ) : 
    m_envVarField(envVarField) { 
    refresh();
  }

  void refresh() {
    if (not m_envVarField)
      return;
    char const *ptr = m_envVarField[0];
    for(int i = 0; ptr; ++i) {
      std::string f = ptr;
      size_t ePos = f.find_first_of('=');
      if (ePos != std::string::npos) {
        std::string name(ptr, ePos);
        std::string val(ptr + ePos + 1, f.length() - ePos - 1);
        // std::cerr << "Param: name " << name << " " << val << "\n";
        m_map.insert(make_pair(name, val));
      }
      ptr = m_envVarField[i+1];
    }
  }

  void print(std::ostream &aus) const {
    for(CIT it = begin(); it != end(); ++it) {
      aus << "export " << it->first << "='" << it->second << "'\n";
    }
  }

  void writeXML(std::ostream &aus) const {
    for(CIT it = begin(); it != end(); ++it) {
      aus << "<env name='" << it->first << "'><!CDATA[[" << it->second << "]]></env>\n";
    }
  }

};

inline std::ostream &operator << (std::ostream &aus, AllEnvs const &r) {
  r.print(aus);
  return aus;
}


template<class T>
struct MyList {
  typedef T value_type;
  typedef size_t key_type;
  typedef typename std::vector<value_type> List;
  typedef typename List::const_iterator CIT;
  typedef typename List::iterator IT;

  List m_list;

  List const &getList() { return m_list; }

  size_t size() const { return m_list.size(); }

  CIT begin() const { return m_list.begin(); }
  CIT end() const { return m_list.end(); }
  IT begin() { return m_list.begin(); }
  IT end() { return m_list.end(); }

  value_type &operator[](key_type const &key) {
    return m_list[key];
  }
  value_type operator[](key_type const &key) const {
    value_type res;
    CIT it = m_list.find(key);
    if (it != m_list.end()) {
      res = it->second;
    }
    return res;
  }
  value_type operator()(key_type const &key) const {
    value_type res;
    CIT it = m_list.find(key);
    if (it != m_list.end()) {

      res = it->second;
    }
    return res;
  }
  bool exist(key_type const &key) const {
    bool res = 0;
    CIT it = m_list.find(key);
    if (it != m_list.end()) {
      res = 1;
    }
    return res;
  }

};

#endif

