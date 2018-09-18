/**
    loggingstream.h -- Filtered output of error, warning and log messages.


    Depending on a configurable level the output can be filtered to
    print important messages only, or to be more chattering.

Author: Andre Vehreschild, Institute for Scientific Computing, RWTH Aachen Univ.
Copyright: (C) 2004 Institute f. Scientific Computing,
           RWTH Aachen Univ., Germany.
*/

/* History:
   $Log: loggingstream.h,v $
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

#ifndef LOGGINGSTREAM_H
#define LOGGINGSTREAM_H

#include <ostream>

#ifdef __WIN32
#undef ERROR
#endif

#define ifverb(level) if (loggingstream::get()->getVerbLevel()>=level)

/** Depending on a configurable level the output can be filtered to print important messages only, or to be more chattering.
@author Andre Vehreschild
*/
class loggingstream {
  public: /* Methods */
    /** Get the instance of the loggingstream. */
    inline static loggingstream *get() { return myinstance;};
    /** Destroy the object and print some statistics if the level is
      higher than NORMAL. */
    ~loggingstream();
    /** Get the level of verbosity. */
    inline int getVerbLevel() const { return level; };
    /** Set the level of verbosity. */
    inline void setVerbLevel(int newl) { level= newl; };
    /** Set the actual output stream. */
    std::ostream *setStream(std::ostream *newStream);
    /** Select the correct outputstream and the level to print the
      data with. */
    std::ostream &select(int lev);
    std::ostream &select(int lev, std::string const &path, 
                         int line = 0, int col = 0);
  public: /* Constants. */
    /** Some default levels:
      FILTERED - the output is already filtered, i.e., output everything,
      that follows. */
    static const int FILTERED= -1;
    /** SILENCE - no output at all. */
    static const int SILENCE=0;
    /** CRITICAL - only critical messages are printed. */
    static const int CRITICAL=1;
    /** ERROR - Error messages, those that are recoverable are printed. */
    static const int ERROR= 2;
    /** WARNING - Warning messages, are printed. */
    static const int WARNING= 4;
    /** USAGE - The usage of the programm. */
    static const int USAGE= 5;
    /** NORMAL - Normal level output, not to brief but not quiet. */
    static const int NORMAL= 6;
    /** MAJOR - Print messages of Major importance. */
    static const int MAJOR= 8;
    /** MINOR - Print messages for every logical step. */
    static const int MINOR = 10;
    /** TALKATIV - Print messages for everything. Chatters madly.*/
    static const int TALKATIVE = 12;
    /** FORCE - Print messages for everything. Chatters madly.*/
    static const int FORCE = 20;
  private: /* Members */
    /** Implemented as singleton. This is the only one instance available
      in the whole program. */
    static loggingstream *myinstance;
    /** The current level of verbosity. */
    int level, lastmsglevel;
    /** This stream discards all output written to it. */
    class int_nullstream: public std::basic_ostream<char, std::char_traits<char> > {
      public:
      int_nullstream() : std::basic_ostream<char, std::char_traits<char> >(0) {};
      std::ostream &put(char) {return *this;};
      std::ostream &write(const char *, std::streamsize ) {return *this;};
    } nullstream;
    /** The number of different verblevels understood by this class. */
    static const int msgctrsize= 14;
    /** Count the numbers of messages sent and the ones really printed. */
    long msg[msgctrsize], prt[msgctrsize];
    std::ostream *theOutstream;
  private: /* Methods. */
    /** Initialize the loggingstream. */
    loggingstream();
};

typedef loggingstream ls;

inline std::ostream &logger(int level) { 
  return loggingstream::get()->select(level); 
}

inline std::ostream &logger(int level, std::string const &path, 
                            int line = 0, int col = 0) { 
  return loggingstream::get()->select(level,path,line,col);
}

/*
Local Variables:
mode: C++
End:
 */
#endif
