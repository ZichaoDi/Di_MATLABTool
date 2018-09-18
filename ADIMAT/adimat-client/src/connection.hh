#ifndef adimat_connection_hh
#define adimat_connection_hh

#include <string>

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef __WIN32
#ifdef AD_MINGW32_WINNT_0501
#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0501
#endif
#include <winsock2.h>
#include <windows.h>
#include <ws2tcpip.h>
#include <w32api.h>
#include <io.h>
// #define close _close
// #define read _read
// #define write _write
#undef ERROR
#undef SearchPath
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <netinet/tcp.h>
#endif

struct IPSocketAddress {
  virtual ~IPSocketAddress() {}
  virtual std::string toString() const = 0;
  virtual std::string addressToString() const = 0;
  virtual std::string portToString() const = 0;
  static IPSocketAddress *makeIPSocketAddress(sockaddr*sockaddr, 
                                              std::string const &canonicalName);
  virtual std::string canonicalHostName() const = 0;
};

struct Connection {
  virtual ~Connection() {}
  virtual ssize_t write(char const *buf, size_t nBytes) = 0;
  virtual ssize_t read(char *buf, size_t nBytes) = 0;
  virtual int close() = 0;
  virtual int getFD() const = 0;
  virtual int getError(int errc) = 0;
  virtual std::string const &hostname() const = 0;
  virtual std::string errorMsg(int errc) const = 0;
  virtual ssize_t pending() = 0;
  virtual IPSocketAddress *getAddress() = 0;
  virtual bool isSSL() const = 0;
  virtual bool isZERO_RETURN(int) const = 0;
  virtual Connection *reconnect() const = 0;
  static Connection *makeConnection(std::string const &hostname, 
                                    std::string const &port, 
                                    addrinfo const &hints);
  static Connection *makeSSLConnection(Connection *, 
                                       std::string const &randFile,
                                       std::string const &trustFile,
                                       std::string const &ciphers,
                                       int checkCertificate, 
                                       int checkCertificateName);
  static char const *SSL_version_string();
  static long int SSL_compiled_version_number();
  static long int SSL_runtime_version_number();
  static void SSL_init();
  static void SSL_cleanup();
};

#endif
