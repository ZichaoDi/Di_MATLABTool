#ifndef jw_adimat_pid_hh
#define jw_adimat_pid_hh
#include <unistd.h>

struct PID {
  pid_t m_pid;

  PID() : m_pid(::getpid()) {}
  explicit PID(pid_t _m_pid) : m_pid(_m_pid) {}

  pid_t pid() const { return m_pid; }
  operator pid_t() const { return this->pid(); }
};

/*
struct PPID : public PID {
  PPID() : PID(getppid()) {}
};
*/

#endif
