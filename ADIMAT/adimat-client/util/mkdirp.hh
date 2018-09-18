struct MkDirP {
  IsDir m_isDir;
  MkDir m_mkdir;

  MkDirP(unsigned const _mkdirMode = 0700) : 
    m_mkdir(_mkdirMode)
  {}

  int operator()(std::string const &name) const {
    int mkc = 0;
    SplitText parts(name, "/");
    std::string cur = "/";
    for (unsigned i = 0; i < parts.size() and mkc == 0; ++i) {
      cur = cur + parts[i] + "/";
      if (m_isDir(cur)) {
      } else {
        mkc = m_mkdir(cur);
      }
    }
    return mkc;
  }

};
