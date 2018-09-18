#include <unistd.h>
#include "loggingstream.h"

struct IsDir {

  IsDir() {}

  bool operator()(std::string const &name, bool const warn = false) const {
    struct stat st;
    int sc = stat(name.c_str(), &st);
    bool res = false;
    if (sc == 0) {
      res = S_ISDIR(st.st_mode);
    } else {
      if (warn) {
        logger(ls::ERROR) << "stat(" << name << ") failed: " << strerror(errno) << "\n";
      }
    } 
    return res;
  }
};

struct MkDir {
  unsigned const mkdirMode;

  MkDir(unsigned const _mkdirMode = 0700) : 
    mkdirMode(_mkdirMode)
  {}

  int operator()(std::string const &name) const {
    errno = 0;
    int mkc = mkdir(name.c_str()
#ifndef __WIN32
                    , mkdirMode
#endif
                    );
    if (mkc != 0) {
      logger(ls::ERROR) << "mkdir(" << name << ") failed: " << strerror(errno) << "\n";
    }
    return mkc;
  }
};

// fixme: provide decent tests in configure.ac for these functions

struct CurDir {
  std::string m_dir;
  CurDir() {
#ifdef _GNU_SOURCE
    char * const cwd = get_current_dir_name();
    m_dir = cwd;
    free(cwd);
#else
    size_t bsz = FILENAME_MAX;
    bool tryagain = false;
    do {
      tryagain = false;
      char *buffer = new char[bsz];
      logger(ls::TALKATIVE) << "allocate " << bsz << " B for getcwd\n";
      if (buffer) {
        char *res = getcwd(buffer, bsz);
        if (res == 0) {
          if (errno == ERANGE) {
            tryagain = true;
            bsz *= 2;
          } else {
            logger(ls::ERROR) << "getcwd() failed: " << strerror(errno) << "\n";
          }
        } else {
          m_dir = buffer;
        }
        delete[] buffer;
        buffer = 0;
      } else {
        logger(ls::ERROR) << "malloc for getcwd() failed: " << strerror(errno) << "\n";
      }
    } while (tryagain);
#endif
  }
  operator std::string const &() const { return m_dir; }
  std::string const &operator()() const { return m_dir; }
};


#ifndef __WIN32

struct ChDir {

  std::vector<std::string> m_stack;

  ChDir() {}

  int operator()(std::string const &name) const {
    errno = 0;
    int const chc = chdir(name.c_str());
    if (chc != 0) {
      logger(ls::ERROR) << "chdir(" << name << ") failed: " << strerror(errno) << "\n";
    }
    return chc;
  }

  int pushd(std::string const &name) {
    CurDir curDir;
    int const chc = operator()(name);
    if (chc == 0) {
      m_stack.push_back(curDir);
    }
    return chc;
  }

  int popd() {
    if (m_stack.empty()) {
      return -2;
    }
    int const chc = operator()(m_stack.back());
    m_stack.pop_back();
    return chc;
  }
};

struct RmDir {

  std::string const m_root;

  RmDir(std::string const &root = "/") :
    m_root(root)
  {}

  int operator()(std::string const &name) const {
    std::string rmCommand;
    if (name.substr(0, m_root.size()) != m_root) {
      logger(ls::ERROR) << "refusing to remove directory '" << name << "', which is not under root '"
                        << m_root << "'\n";
      return -3;
    }
    rmCommand = "rm -rf " + name;
    int sc = system(rmCommand.c_str());
    if (not WIFEXITED(sc)) {
      logger(ls::CRITICAL) << "return code: " << WEXITSTATUS(sc) << "\n";
      logger(ls::CRITICAL) << "clean exit: " << WIFEXITED(sc) << "\n";
      logger(ls::CRITICAL) << "error: command we tried to run did not exit cleanly\n";
      exit(1);
    }
    int const cmdExitStatus = WEXITSTATUS(sc);
    if (cmdExitStatus != 0) {
      logger(ls::ERROR) << "The command: '" << rmCommand << "' failed: " << strerror(errno) << "\n";
    }
    return cmdExitStatus;
  }

};

struct Stat {
  struct stat st;

  Stat(std::string const &fname) {
    int c = stat(fname.c_str(), &st);
    if (c != 0) {
      logger(ls::ERROR) << "stat(" << fname << ") failed: " << strerror(errno) << "\n";
    }
  }

};

#endif
