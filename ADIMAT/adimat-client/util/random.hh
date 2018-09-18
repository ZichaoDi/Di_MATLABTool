
struct RandomSource {
  RandomSource(unsigned const randomSeed) {
    srand(randomSeed);
  }
  unsigned operator()() {
    return rand();
  }
};

/*
struct RandomSourceReentrant {
  unsigned short m_state[3];
  drand48_data m_buffer;

  RandomSourceReentrant(std::string const &randomSeed) {
    memset(m_state, '\0', sizeof(m_state));
    memcpy(m_state, randomSeed.data(), min(randomSeed.size(), sizeof(m_state)));
  }
  RandomSourceReentrant(unsigned long const randomSeed) {
    memset(m_state, '\0', sizeof(m_state));
    memcpy(m_state, &randomSeed, min(sizeof(randomSeed), sizeof(m_state)));
  }
  long int operator()(long int &res) {
    nrand48_r(m_state, &m_buffer, &res);
    return res;
  }
  double operator()(double &res) {
    erand48_r(m_state, &m_buffer, &res);
    return res;
  }
};
struct RandomSource {
  unsigned short m_state[3];

  RandomSource(std::string const &randomSeed) {
    memset(m_state, '\0', sizeof(m_state));
    memcpy(m_state, randomSeed.data(), min(randomSeed.size(), sizeof(m_state)));
  }
  RandomSource(unsigned long const randomSeed) {
    memset(m_state, '\0', sizeof(m_state));
    memcpy(m_state, &randomSeed, min(sizeof(randomSeed), sizeof(m_state)));
  }
  long int operator()(long int &) {
    return nrand48(m_state);
  }
  double operator()(double &) {
    return erand48(m_state);
  }
};
*/

struct RandomString {
  std::string m_str;
  RandomString(RandomSource &randSource,
               size_t const len,
               std::string const &alpha = "abcdefghijklmnopqrstuvwxyz"
               "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
               "0123456789") 
  {
    m_str.resize(len);
    for (size_t i = 0; i < len; ++i) {
      m_str[i] = alpha[randSource() % alpha.size()];
    }
  }
  std::string operator()() const { return m_str; }
};

