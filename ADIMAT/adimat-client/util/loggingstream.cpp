/**
    loggingstream.h -- Filtered output of error, warning and log messages.


    Depending on a configurable level the output can be filtered to
    print important messages only, or to be more chattering.

Author: Andre Vehreschild, Institute for Scientific Computing, RWTH Aachen Univ.
Copyright: (C) 2004 Institute f. Scientific Computing,
           RWTH Aachen Univ., Germany.
*/

/* History:
   $Log: loggingstream.cpp,v $
   Revision 1.4  2004/04/27 15:05:24  af116ve
   Replaced constant by symbol. In fact, cosmetics.

   Revision 1.3  2004/04/27 13:07:31  af116ve
   Added FILTERED level, which is used when the output is already filtered and the level known. In fact it outputs everything.
   Added lastmsglevel, which stores the level of the last message passed to the loggingstream.

   Revision 1.2  2004/04/14 15:14:51  af116ve
   Added fields and code to maintain the logger stats.
   Security checks are added, too.

   Revision 1.1  2004/04/06 15:42:10  af116ve
   Initial version.
   Enable parameterizable logging of messages. The log messages that are not of interest are skipped.


   */

#include "loggingstream.h"
#include <iostream>

/** Initialize the loggingstream's only instance. */
loggingstream *loggingstream::myinstance= new loggingstream();

/** Initialize the loggingstream. */
loggingstream::loggingstream() :
  level(USAGE), 
  lastmsglevel(USAGE),
  theOutstream(&std::cerr)
{

#ifdef HAVE_MEMSET
   std::memset(msg, 0, sizeof(long)* msgctrsize);
   std::memset(prt, 0, sizeof(long)* msgctrsize);
#else
  for(int i=0; i< msgctrsize; ++i) {
      msg[i]=0;
      prt[i]=0;
  }
#endif
}

/** Destroy the object and print some statistics if the level is higher than
  NORMAL. */
loggingstream::~loggingstream() {
  /*
  if (level>NORMAL)
    *theOutstream<< "Log-stats: Statistics of log-messages: LEVEL: "
      "#printed(#filtered)."<< std::endl<< "Log-stats: CRITICAL: "
      << prt[1]<< "("<< msg[1]<< "), ERROR: "<< prt[2]<< "("<< msg[2]
      << "), WARNING: "<< prt[3]+prt[4]<< "("<< msg[3]+msg[4]<< "),"
      << std::endl<< "Log-stats: Level 5: "<< prt[5]<< "("<< msg[5]
      << "), NORMAL: "<< prt[6]<< "("<< msg[6]<< "), USAGE: "<< prt[7]
      << "("<< msg[7]<< "),"<< std::endl<< "Log-stats: MAJOR(M): "
      << prt[8]<< "("<< msg[8]<< "), Level 9:"<< prt[9]<< "("<< msg[9]
      << "), MINOR(m): "<< prt[10]<< "("<< msg[10]<< "),"<< std::endl
      << "Log-stats: Level 11: "<< prt[11]<< "("<< msg[11]
      << "), TALKATIVE: "<< prt[12]<< "("<< msg[12]<< "), and Level 13+: "
      << prt[13]<< "("<< msg[13]<< ")."<< std::endl;
  */
}

std::ostream *loggingstream::setStream(std::ostream *newStream) {
  std::ostream *cur = theOutstream;
  theOutstream = newStream;
  return cur;
}

/** Select the correct outputstream and the level to print the
  data with. */
std::ostream &loggingstream::select(int lev) {
#ifdef DEBUG
  if(lev<-1) {
    logger(CRITICAL)<< "logging level is negative: "<< lev<< std::endl;
    return logger(CRITICAL);
  }
#endif
  if (lev==FILTERED)
    lev= lastmsglevel;
  else
    lastmsglevel= lev;

  if (lev< msgctrsize)
    ++msg[lev];
  else
    ++msg[msgctrsize-1];

  if (lev> level)
    return nullstream;

  if (lev< msgctrsize)
    ++prt[lev];
  else
    ++prt[msgctrsize-1];

  theOutstream->flush();

  switch (lev) {
    case SILENCE:
      *theOutstream<< "SILENCE: ";
      break;
    case CRITICAL:
      *theOutstream<< "CRITICAL: ";
      break;
    case ERROR:
      *theOutstream<< "ERROR: ";
      break;
    case 3: case WARNING:
      *theOutstream<< "WARN: ";
      break;
    case USAGE: case NORMAL: case 7:
      break;
    case MAJOR:
      *theOutstream<< "M: ";
      break;
    case MINOR:
      *theOutstream<< "m: ";
      break;
    case TALKATIVE:
      *theOutstream<< "t: ";
      break;
    case FORCE:
    default:
      break;
  }

  return *theOutstream;
}

/** Select the correct outputstream and the level to print the
  data with. */
std::ostream &loggingstream::select(int lev, std::string const &path, 
                                    int line, int col) {
  if (lev==FILTERED)
    lev= lastmsglevel;
  else
    lastmsglevel= lev;

  if (lev> level)
    return nullstream;

  theOutstream->flush();

  *theOutstream<< path << ":" << line << ":" << col << ":";
  
  return select(lev);

}

