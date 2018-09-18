#ifndef jw_utility_strftime
#define jw_utility_strftime

#include <string>

#include "time.hh"

struct StrFTime {
  std::string format;

  StrFTime(std::string const &_format) : format(_format) {}
  
  std::string operator()(Time const &t = Time()) const {
    char puffer[FILENAME_MAX];
//     struct tm * res = gmtime(&t.m_time);
    struct tm * res = localtime(&t.m_time);
    size_t nres = strftime(puffer, FILENAME_MAX, format.c_str(), res);
    if (nres) return std::string(puffer, nres);
    else return std::string();
  }

  void writeXML(std::ostream &aus, std::string const &indent = "") {
    aus << indent << "<date>" << operator()() << "</date>";
  }

};

#endif
