#ifndef jw_adimat_logcontext_hh
#define jw_adimat_logcontext_hh

#include "pid.hh"
#include "strftime.hh"

struct LogContext {
  std::string timeStr;
  std::string pidStr;
  std::string const runId;
  std::string const logDirName;

  LogContext(std::string const &logBase, int id) : 
    timeStr(StrFTime("%Y/%m/%d/%H/%M")()),
    pidStr(toString(PID())),
    runId(timeStr + "/" + pidStr + "_" + toString(id)),
    logDirName(logBase + "/" + runId)
  {
  }

};

#endif
