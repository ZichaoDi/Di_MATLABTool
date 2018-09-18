// $Id: time.hh 1891 2009-05-26 14:35:28Z willkomm $

#ifndef su_time_hh
#define su_time_hh

#include <time.h>

struct Time {
  time_t m_time;

  Time() : m_time(time(0)) {}
  Time(time_t _time) : m_time(_time) {}

  Time operator +(double const d) const { return Time(time_t(m_time + d)); }
  Time operator -(double const d) const { return Time(time_t(m_time - d)); }
  operator time_t() const { return m_time; }
};

#endif
