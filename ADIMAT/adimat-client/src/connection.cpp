#include "connection.hh"
#include <iostream>
#include <string>
#include <sstream>
#include <assert.h>
#include <sys/types.h>
#ifdef HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#endif
#include <stdint.h>
//#include <linux/errqueue.h>

#include <openssl/conf.h>
#include <openssl/ssl.h>
#include <openssl/rand.h>
#include <openssl/err.h>

#include "loggingstream.h"
#include "client-util.h"

using std::cerr;
using std::endl;

class IPv4Address : public IPSocketAddress {
  sockaddr_in m_sockaddr;
  std::string m_canonicalName;

public:
  IPv4Address(sockaddr_in const &addr, std::string const &canonicalName) : 
    m_sockaddr(addr), 
    m_canonicalName(canonicalName)
  {
    assert(addr.sin_family == AF_INET);
  }

  std::string addressToString() const {
    std::stringstream str;
    uint32_t mh = toHost();
    str << (mh >> 24) << "." << ((mh >> 16) & 0xff) << "." << ((mh >> 8) & 0xff) << "." << (mh & 0xff);
    return str.str();
  }

  std::string portToString() const {
    std::stringstream str;
    uint16_t mh = portToHost();
    str << mh;
    return str.str();
  }

  std::string toString() const {
    std::stringstream str;
    uint32_t mh = toHost();
    str << (mh >> 24) << "." << ((mh >> 16) & 0xff) << "." << ((mh >> 8) & 0xff) << "." << (mh & 0xff);
    uint16_t mp = portToHost();
    if (mp) {
      str << ", port " << mp;
    }
    return str.str();
  }

  uint32_t toHost() const { return ntohl(m_sockaddr.sin_addr.s_addr); }

  uint32_t portToHost() const { return ntohs(m_sockaddr.sin_port); }

  uint32_t operator()() const { return toHost(); }

  IPv4Address &operator = (uint32_t adr) {
    m_sockaddr.sin_addr.s_addr = htonl(adr); 
    return *this;
  }

  std::string canonicalHostName() const { return m_canonicalName; }
  
};

class IPv6Address {
  in6_addr m_addr;

public:
  IPv6Address(in6_addr const &addr) : 
    m_addr(addr)
  {}

  std::string toString() const {
    std::stringstream str;
    for (int i = 0; i < 16; ++i) {
      if (i > 0) {
        str << ":";
      }
      str << std::hex << (int)m_addr.s6_addr[i];
    }
    return str.str();
  }
};

class IPv6SocketAddress : public IPSocketAddress {
  sockaddr_in6 m_sockaddr;
  std::string m_canonicalName;

public:
  IPv6SocketAddress(sockaddr_in6 const &addr, std::string const &canonicalName) : 
    m_sockaddr(addr),
    m_canonicalName(canonicalName)
  {
    assert(addr.sin6_family == AF_INET6);
  }

  std::string addressToString() const {
    std::stringstream str;
    IPv6Address ipaddr(m_sockaddr.sin6_addr);
    str << ipaddr.toString();
    return str.str();
  }

  std::string portToString() const {
    std::stringstream str;
    uint16_t mh = portToHost();
    str << mh;
    return str.str();
  }

  std::string toString() const {
    std::stringstream str;
    IPv6Address ipaddr(m_sockaddr.sin6_addr);
    str << ipaddr.toString();
    uint16_t mp = portToHost();
    if (mp) {
      str << ", port " << mp;
    }
    return str.str();
  }

  uint32_t portToHost() const { return ntohs(m_sockaddr.sin6_port); }

  std::string canonicalHostName() const { return m_canonicalName; }

};

IPSocketAddress *IPSocketAddress::makeIPSocketAddress(sockaddr *sockaddr, 
                                                      std::string const &canonicalName) {
  sockaddr_in *addr = (sockaddr_in *)sockaddr;
  if (addr->sin_family == AF_INET) {
    return new IPv4Address(*(sockaddr_in *)sockaddr, canonicalName);
  } else if (addr->sin_family == AF_INET6) {
    return new IPv6SocketAddress(*(sockaddr_in6 *)sockaddr, canonicalName);
  }
  return 0;
}

class AddressInfo {
  addrinfo m_addrinfo;

  AddressInfo(addrinfo const &addrinfo) : 
    m_addrinfo(addrinfo) 
  {
  }
  
};

static char const *sslErrorString(int sslError) {
  switch(sslError) {
  case SSL_ERROR_NONE:
    return "The TLS/SSL I/O operation completed.  This result code is returned if and only if ret > 0.\n";
    break;

  case SSL_ERROR_ZERO_RETURN:
    return "The TLS/SSL connection has been closed.  If the protocol version is SSL 3.0 or TLS 1.0, this result code is returned only if a closure alert has occurred in the protocol, i.e. if the connection has been "
      "closed cleanly. Note that in this case SSL_ERROR_ZERO_RETURN does not necessarily indicate that the underlying transport has been closed.\n";
    break;

  case SSL_ERROR_WANT_READ:
  case SSL_ERROR_WANT_WRITE:
    return "The operation did not complete; the same TLS/SSL I/O function should be called again later.  If, by then, the underlying BIO has data available for reading (if the result code is SSL_ERROR_WANT_READ) or"
      "allows writing data (SSL_ERROR_WANT_WRITE), then some TLS/SSL protocol progress will take place, i.e. at least part of an TLS/SSL record will be read or written.  Note that the retry may again lead to a"
      "SSL_ERROR_WANT_READ or SSL_ERROR_WANT_WRITE condition.  There is no fixed upper limit for the number of iterations that may be necessary until progress becomes visible at application protocol level."
      "For socket BIOs (e.g. when SSL_set_fd() was used), select() or poll() on the underlying socket can be used to find out when the TLS/SSL I/O function should be retried."
      
      "Caveat: Any TLS/SSL I/O function can lead to either of SSL_ERROR_WANT_READ and SSL_ERROR_WANT_WRITE.  In particular, SSL_read() or SSL_peek() may want to write data and SSL_write() may want to read data."
      "This is mainly because TLS/SSL handshakes may occur at any time during the protocol (initiated by either the client or the server); SSL_read(), SSL_peek(), and SSL_write() will handle any pending"
      "handshakes.\n";
      break;

  case SSL_ERROR_WANT_CONNECT:
  case SSL_ERROR_WANT_ACCEPT:
    return "The operation did not complete; the same TLS/SSL I/O function should be called again later. The underlying BIO was not connected yet to the peer and the call would block in connect()/accept(). The SSL"
      "function should be called again when the connection is established. These messages can only appear with a BIO_s_connect() or BIO_s_accept() BIO, respectively.  In order to find out, when the connection"
      "has been successfully established, on many platforms select() or poll() for writing on the socket file descriptor can be used.\n";
    break;

  case SSL_ERROR_WANT_X509_LOOKUP:
    return "The operation did not complete because an application callback set by SSL_CTX_set_client_cert_cb() has asked to be called again.  The TLS/SSL I/O function should be called again later.  Details depend on"
      " the application.\n";
    break;
    
  case SSL_ERROR_SYSCALL:
    return "Some I/O error occurred.  The OpenSSL error queue may contain more information on the error.  If the error queue is empty (i.e. ERR_get_error() returns 0), ret can be used to find out more about the "
      "error: If ret == 0, an EOF was observed that violates the protocol.  If ret == -1, the underlying BIO reported an I/O error (for socket I/O on Unix systems, consult errno for details).\n";
    break;
      
  case SSL_ERROR_SSL:
    return "A failure in the SSL library occurred, usually a protocol error.  The OpenSSL error queue contains more information on the error.\n";
    break;
  }
  return "";
}

struct TCPConnection : public Connection {
  addrinfo m_hints;
  int m_sockFD;
  //  FILE *m_sockFile;

  std::string m_hostname, m_port, m_canonicalHostName;

  IPSocketAddress *m_socketAddress;

  TCPConnection() : m_sockFD(-1) {}

  TCPConnection(std::string const &hostname, std::string const &port, addrinfo const &hints) : 
    m_hints(hints),
    m_sockFD(-1) {

    addrinfo *resultList = 0;
    logger(ls::MAJOR) << "getaddrinfo(" << hostname << ", " << port << ")\n";
    int const gac = getaddrinfo(hostname.c_str(), port.c_str(), &hints, &resultList);
    
    if (gac != 0) {
      logger(ls::ERROR) << "Resolving " << hostname << ": " << gai_strerror(gac) << "\n";
    } else {
      m_hostname = hostname;
      m_port = port;
    }
    
    addrinfo *adrInfo = resultList;
    if (gac == 0 and adrInfo) {
      if (hints.ai_flags & AI_CANONNAME) {
        logger(ls::MAJOR) << "canonical name: " << adrInfo->ai_canonname << "\n";
        m_canonicalHostName = adrInfo->ai_canonname;
      } else {
        m_canonicalHostName = hostname;
      }
    }

    for (adrInfo = resultList; adrInfo != NULL; adrInfo = adrInfo->ai_next) {
      IPSocketAddress *saddr
        = IPSocketAddress::makeIPSocketAddress(adrInfo->ai_addr, m_canonicalHostName);
      logger(ls::MINOR) << "Available address to connect to: " << saddr->toString() << " (" << m_canonicalHostName << ")\n";
      delete saddr;
    }

    int sfd = -1;
    
    for (adrInfo = resultList; adrInfo != NULL; adrInfo = adrInfo->ai_next) {
      IPSocketAddress *saddr
        = IPSocketAddress::makeIPSocketAddress(adrInfo->ai_addr, m_canonicalHostName);
      logger(ls::NORMAL) << "Attempt to connect to " << saddr->toString() << " (" << m_canonicalHostName << ")\n";

      sfd = socket(adrInfo->ai_family, adrInfo->ai_socktype,
                   adrInfo->ai_protocol);
      if (sfd == -1) {
        logger(ls::ERROR) << "socket failed: " << strerror(errno) << "\n";
        continue;
      }
      
      { // DISABLE NAGLE ALGORITHM
        const int val = 1;
#ifdef __WIN32
        int ret = setsockopt(sfd, IPPROTO_TCP, TCP_NODELAY, (char const*) &val, sizeof(val));
#else
        int ret = setsockopt(sfd, IPPROTO_TCP, TCP_NODELAY, &val, sizeof(val));
#endif
        if (ret < 0) {
          logger(ls::CRITICAL) << "setsockopt(TCP_NODELAY): " << strerror(errno) << "\n";
          exit(1);
        }
      }

      if (connect(sfd, adrInfo->ai_addr, adrInfo->ai_addrlen) != -1) {
        /* Success */
        m_socketAddress = saddr;
        break;  
      } else {
        logger(ls::ERROR) << "connect to " << saddr->toString()
                          << " (" << m_canonicalHostName << ") failed: " << strerror(errno) << "\n";
      }
      
      delete saddr;
      ::shutdown(sfd, 2);
      // ::close(sfd);
    }
    
    if (adrInfo == 0) {               /* No address succeeded */
      logger(ls::CRITICAL) << "Could not connect\n";
      exit(EXIT_FAILURE);
    } else {
      m_sockFD = sfd;
      logger(ls::MAJOR) << "Opened socket and connected, fd " << m_sockFD << "\n";
      // m_sockFile = fdopen(m_sockFD, "rwb");
      // if (m_sockFile) {
      //   logger(ls::MINOR) << "Opened file on socket: " << ferror(m_sockFile) << "\n";
      // } else {
      //   logger(ls::ERROR) << "Failed to open file on socket " << m_sockFD << ": " << strerror(errno) << "\n";
      //   exit(EXIT_FAILURE);
      // }
    }
    
    freeaddrinfo(resultList);
  }

  ~TCPConnection() {
    close();
    if (m_socketAddress) {
      delete m_socketAddress;
      m_socketAddress = 0;
    }
  }

  bool isSSL() const { return false; }
  bool isZERO_RETURN(int) const { return false; }

  ssize_t write(char const *buf, size_t const nBytes) {
    errno = 0;
    // if (ferror(m_sockFile)) {
    //   logger(ls::ERROR) << "TCPConnection write: socket has error: " << ferror(m_sockFile) << "\n";
    // }
    return send(m_sockFD, buf, nBytes, 0);
  }
  ssize_t read(char *buf, size_t const nBytes) {
    errno = 0;
    // if (ferror(m_sockFile)) {
    //   logger(ls::ERROR) << "TCPConnection write: socket has error: " << ferror(m_sockFile) << "\n";
    // }
    return recv(m_sockFD, buf, nBytes, 0);
  }
  int close() {
    int c = 0;
    if (m_sockFD != -1) {
      c = shutdown(m_sockFD, 2);
      // c = ::close(m_sockFD);
      if (c != 0) {
        logger(ls::WARNING) << "Failed to close the TCP connection: " << strerror(errno) << "\n";
      }
      m_sockFD = -1;
    }
    return c;
  }
  int getFD() const { 
    return m_sockFD; 
  }
  int getError(int) {
    // sock_extended_err see;
    // ssize_t nread = recv(m_sockFD, &see, sizeof(see), MSG_ERRQUEUE);
    // cerr << "read " << nread << " Bytes of error message\n";
    return errno;
  }
  std::string errorMsg(int errc) const {
    return strerror(errc);
  }
  std::string const &hostname() const { return m_hostname; }
  ssize_t pending() { return 0; }
  IPSocketAddress *getAddress() {
    return m_socketAddress;
  }
  Connection *reconnect() const { return 0; }

};

struct SSLConnection : public Connection {
  Connection *m_connection;
  std::string const m_seedFileName;
  std::string const m_trustFileName;
  std::string const m_ciphers;
  int m_checkCertificate;
  int m_checkCertificateName;
  SSL *m_ssl;
  SSL_CTX *m_ctx;
  static int const m_errorExitCode = 12;

  SSLConnection(Connection *connection,
                std::string const &_seedFileName, 
                std::string const &trustFileName,
                std::string const &ciphers, 
                int _checkCertificate, 
                int checkCertificateName, 
                SSL_SESSION *sess = 0) :
    m_connection(connection),
    m_seedFileName(_seedFileName),
    m_trustFileName(trustFileName),
    m_ciphers(ciphers),
    m_checkCertificate(_checkCertificate),
    m_checkCertificateName(checkCertificateName),
    m_ssl(),
    m_ctx()
  {
    m_ctx = SSL_CTX_new(SSLv3_client_method());
    
#if HAVE_SSL_OP_NO_COMPRESSION != 0
    SSL_CTX_set_options(m_ctx, SSL_OP_NO_COMPRESSION);
#endif

    setupSSLCiphers();

    if (not trustFileName.empty()) {
      if(!SSL_CTX_load_verify_locations(m_ctx, trustFileName.c_str(), NULL)) {
        logger(ls::CRITICAL) << "Could not load trust store \"" << trustFileName << "\"" << endl;
        ERR_print_errors_fp(stderr);
        exit(m_errorExitCode);
      }
    }
    
    std::string seedFileName = _seedFileName;
    if (seedFileName.empty()) {
      size_t const randpl = 10240;
      char randpath[randpl + 1];
      char const *res = RAND_file_name(randpath, randpl);
      if (res) {
        logger(ls::MINOR) << "obtained random seed file name: " << randpath << "\n";
        seedFileName.assign(randpath);
      }
    }
    if (fileExists(seedFileName) or not _seedFileName.empty()) {
      size_t const nread = RAND_load_file(seedFileName.c_str(), 1048576);
      if (nread == 0) {
        logger(ls::CRITICAL) << "Could not read random seed " << seedFileName << ": " << strerror(errno) << endl;
        exit(m_errorExitCode);
      } else {
        logger(ls::MINOR) << "read " << nread << " bytes from random seed file: " << seedFileName << "\n";
      }
    }
    
    m_ssl = SSL_new(m_ctx);
    if (!m_ssl) {
      logger(ls::CRITICAL) << "Could not create SSL object." << endl;
      ERR_print_errors_fp(stderr);
      exit(m_errorExitCode);
    }

    // SSL_set_mode(m_ssl, SSL_MODE_AUTO_RETRY);
    
    if (!SSL_set_fd(m_ssl, m_connection->getFD())) {
      logger(ls::CRITICAL) << "Could not set file handle on SSL." << endl;
      ERR_print_errors_fp(stderr);
      exit(m_errorExitCode);
    }

    if (!SSL_set_tlsext_host_name(m_ssl, hostname().c_str())) {
      logger(ls::CRITICAL) << "Could not enable SNI extension." << endl;
      ERR_print_errors_fp(stderr);
      exit(m_errorExitCode);
    }

    if (sess) {
      logger(ls::MINOR) << "Setting session to resume..." << endl;
      if (!SSL_set_session(m_ssl, sess)) {
        logger(ls::CRITICAL) << "Could not set the given session." << endl;
        ERR_print_errors_fp(stderr);
        exit(m_errorExitCode);
      }
    }
    
    int const sslcc = SSL_connect(m_ssl);
    if (sslcc <= 0) {
      int errc = errno;
      logger(ls::CRITICAL) << "SSL_connect failed: return code " << sslcc << endl;

      int sslError = SSL_get_error(m_ssl, sslcc);
      logger(ls::ERROR) << "SSL_get_error: " << sslError << ": " << sslErrorString(sslError);
      ERR_print_errors_fp(stderr);

      logger(ls::ERROR) << "system error: " << errc << ": " << strerror(errc) << endl;

      exit(m_errorExitCode);
    }
    
    logger(ls::MAJOR) << "SSL version: \"" << SSL_get_version(m_ssl) << "\"" << endl;
    logger(ls::MAJOR) << "SSL cipher: \"" << SSL_get_cipher(m_ssl) << "\"" << endl;
    
    if (not sess) {
      checkCertificate();
    } else {
      logger(ls::MINOR) << "Not checking the certificate, since we are resuming a session..." << endl;
    }

  }

  ~SSLConnection() {
    if (m_ssl) {
      SSL_free(m_ssl);
      m_ssl = 0;
    }
    if (m_ctx) {
      SSL_CTX_free(m_ctx);
      m_ctx = 0;
    }

    if (m_connection) {
      delete m_connection;
      m_connection = 0;
    }
  }

  void checkCertificate() const {

    X509 *peercert = SSL_get_peer_certificate(m_ssl);
    if (peercert == 0) {
      logger(ls::CRITICAL) << "The peer certificate is missing.";
      exit(m_errorExitCode);
    }

    if(SSL_get_verify_result(m_ssl) != X509_V_OK) {
      if (m_checkCertificate) {
        logger(ls::CRITICAL) << "The certificate check has failed." << endl;
        exit(m_errorExitCode);
      } else {
        logger(ls::WARNING) << "The certificate check has failed." << endl;
      }
    } else {
      logger(ls::MAJOR) << "The certificate is valid, good." << endl;
    }

#ifdef HAVE_X509_CHECK_HOST    
    // Check if the server certificate matches the host name used to
    // establish the connection.
    // FIXME: Currently needs OpenSSL 1.1.
    if (X509_check_host(peercert, hostname().c_str(), hostname().size(), 0) != 1
        && !certificate_host_name_override(peercert, host)) {
      logger(ls::CRITICAL) << "SSL certificate does not match host name\n";
      exit(m_errorExitCode);
    }

#else

    char commonName [1024];
    X509_NAME * name = X509_get_subject_name(peercert);
    X509_NAME_get_text_by_NID(name, NID_commonName, commonName, 1024);

    logger(ls::MINOR) << "Certificate CN = " << commonName << "\n";

#ifdef HAVE_STRCASECMP    
    if (strcasecmp(commonName, hostname().c_str()) != 0
        and strcasecmp(commonName, "adimat.sc.rwth-aachen.de") != 0
        ) {
#elif defined HAVE_STRICMP    
    if (stricmp(commonName, hostname().c_str()) != 0
        and stricmp(commonName, "adimat.sc.rwth-aachen.de") != 0
        ) {
#endif
      if (m_checkCertificateName) {
        logger(ls::CRITICAL) << "SSL certificate CN (" << commonName << ") does not match host name (" << hostname() << ")\n";
        exit(m_errorExitCode);
      } else {
        logger(ls::WARNING) << "SSL certificate CN (" << commonName << ") does not match host name (" << hostname() << ")\n";
      }
    }
    
    #endif    
    
    X509_free(peercert);
  }

  void setupSSLCiphers() const {
    BIO *bio_err = BIO_new(BIO_s_mem());

    logger(ls::TALKATIVE) << "selecting ciphers: " << m_ciphers << "\n";

    if (SSL_CTX_set_cipher_list(m_ctx, m_ciphers.c_str()) != 1) {
      logger(ls::CRITICAL) << "Failed to set the initial list of ciphers: " << m_ciphers << "\n";
      ERR_print_errors(bio_err);
      exit(m_errorExitCode);
    }

    {
      // Create a dummy SSL session to obtain the cipher list.
      SSL *ssl = SSL_new(m_ctx);
      if (ssl == NULL) {
        logger(ls::CRITICAL) << "Failed to create a test SSL object\n";
        ERR_print_errors(bio_err);
        exit(m_errorExitCode);
      }
      STACK_OF(SSL_CIPHER) *active_ciphers = SSL_get_ciphers(ssl);
      if (active_ciphers == NULL) {
        logger(ls::CRITICAL) << "Failed to get the cipher list\n";
        ERR_print_errors(bio_err);
        exit(m_errorExitCode);
      }

      // Whitelist of candidate ciphers.
      static const char *const candidates[] =  {
        "AES256-SHA256", // strong ciphers
        "AES128-GCM-SHA256", "AES128-SHA256", // strong ciphers
        "AES128-SHA", "AES256-SHA", // strong ciphers, also in older versions

        "RC4-SHA", "RC4-MD5", // backwards compatibility, supposed to be weak

        "DES-CBC3-SHA", "DES-CBC3-MD5", // more backwards compatibility

        // "CAMELLIA256-SHA", "CAMELLIA128-SHA", // my choice
        NULL
      };

      for (const char *const *c = candidates; *c; ++c) {
        logger(ls::TALKATIVE) << "whitelisted cipher: " << *c << "\n";
      }

      // Actually selected ciphers.
      std::string ciphers;
      for (const char *const *c = candidates; *c; ++c) {
        for (int i = 0; i < sk_SSL_CIPHER_num(active_ciphers); ++i) {
          if (c == candidates) { // first round
            logger(ls::TALKATIVE) << "library supports cipher: " << 
              SSL_CIPHER_get_name(sk_SSL_CIPHER_value(active_ciphers, i)) << "\n";
          }
          if (strcmp(SSL_CIPHER_get_name(sk_SSL_CIPHER_value(active_ciphers, i)),
                     *c) == 0) {
            if (not ciphers.empty()) {
              ciphers += ":";
            }
            ciphers += *c;
          }
        }
      }
      SSL_free(ssl);
      
      logger(ls::MAJOR) << "Selected list of ciphers: " << ciphers << "\n";
      
      // Apply final cipher list.
      if (SSL_CTX_set_cipher_list(m_ctx, ciphers.c_str()) != 1) {
        logger(ls::CRITICAL) << "Failed to set the list of ciphers: " << ciphers << "\n";
        ERR_print_errors(bio_err);
        exit(m_errorExitCode);
      }
    }
    
    BIO_free(bio_err);
    bio_err = 0;
  }

  bool isSSL() const { return true; }
  bool isZERO_RETURN(int c) const { return c == SSL_ERROR_ZERO_RETURN; }

  ssize_t write(char const *buf, size_t const nBytes) {
    return SSL_write(m_ssl, buf, nBytes);
  }

  ssize_t read(char *buf, size_t const nBytes) {
    return SSL_read(m_ssl, buf, nBytes);
  }

  int close() {
    int c = SSL_shutdown(m_ssl);
    logger(ls::MAJOR) << "1. SSL_shutdown: " << c << "\n";
    if (c == 0) {
      int d = SSL_shutdown(m_ssl);
      logger(ls::MAJOR) << "2. SSL_shutdown: " << d << "\n";
    } else if (c == 1) {
      logger(ls::MINOR) << "1. SSL_shutdown: appearently, we're done already...\n";
    } else {
      logger(ls::WARNING) << "1. SSL_shutdown: on the first round, we expect a 0 or 1: " << c << "\n";
    }
    logger(ls::MINOR) << "Closing underlying socket connection...\n";
    m_connection->close();
    return c;
  }

  int getFD() const { 
    return -1; 
  }
  int getError(int errc) {
    return SSL_get_error(m_ssl, errc);
  }
  std::string errorMsg(int errc) const {
    return sslErrorString(errc);
  }
  std::string const &hostname() const { return m_connection->hostname(); }
  ssize_t pending() { return SSL_pending(m_ssl); }
  IPSocketAddress *getAddress() {
    return m_connection->getAddress();
  }
  Connection *reconnect() const {
    logger(ls::MAJOR) << "SSLConnection::reconnect: reconnecting..." << endl;
    SSL_SESSION *sess = SSL_get1_session(m_ssl);
    if (sess) {
      logger(ls::MINOR) << "SSLConnection::reconnect: got session..." << endl;
    }
    TCPConnection *tcpOld = dynamic_cast<TCPConnection *>(m_connection);
    TCPConnection *tcpNew = new TCPConnection(tcpOld->m_hostname, tcpOld->m_port, tcpOld->m_hints);
    SSLConnection *sslNew = new SSLConnection(tcpNew, m_seedFileName, m_trustFileName, m_ciphers, m_checkCertificate, m_checkCertificateName, sess);
    return sslNew;
  }
};

Connection *Connection::makeConnection(std::string const &hostname, 
                                              std::string const &port,
                                              addrinfo const &hints) {
  return new TCPConnection(hostname, port, hints);
}

Connection *Connection::makeSSLConnection(Connection *tcpConn,
                                          std::string const &randFile,
                                          std::string const &trustFile,
                                          std::string const &ciphers,
                                          int checkCertificate, 
                                          int checkCertificateName) {
  return new SSLConnection(tcpConn, randFile, trustFile, ciphers, checkCertificate, checkCertificateName);
}

char const *Connection::SSL_version_string() {
  return SSLeay_version(SSLEAY_VERSION);
}

long int Connection::SSL_compiled_version_number() {
  return OPENSSL_VERSION_NUMBER;
}

long int Connection::SSL_runtime_version_number() {
  return OPENSSL_VERSION_NUMBER;
}

void Connection::SSL_init() {
  logger(ls::MAJOR) << "Initializing OpenSSL library (OPENSSL_config, etc.)...\n";
  OPENSSL_config(0);
  SSL_load_error_strings();
  SSL_library_init();
}

void Connection::SSL_cleanup() {
  logger(ls::MAJOR) << "Shutting down OpenSSL library...\n";
  ERR_remove_state(0);
  ERR_free_strings();
  EVP_cleanup();
  CRYPTO_cleanup_all_ex_data();
  sk_SSL_COMP_free (SSL_COMP_get_compression_methods());
}
