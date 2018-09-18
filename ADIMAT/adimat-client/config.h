/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.ac by autoheader.  */

#include "config_pre.h"

/* The default ADiMat home directory. */
#define ADIMAT_DEFAULT_HOME "/Users/Wendydi/Documents/MATLAB/ADIMAT/adimat"

/* The base URI of the ADiMat web server. */
#define ADIMAT_SERVER_BASE "/"

/* 1: static build */
#define ADIMAT_STATIC_BUILD 0

/* A string describing the current ADiMat version as a floating point number.
   */
#define ADIMAT_VERSION_NUMBER 0.60

/* Whether we use the old mingw cross complier */
/* #undef AD_MINGW32_WINNT_0501 */

/* Define to 1 if you have the `atexit' function. */
#define HAVE_ATEXIT 1

/* Define to 1 if you have the <cctype> header file. */
/* #undef HAVE_CCTYPE */

/* Define to 1 if you have the <cfloat> header file. */
/* #undef HAVE_CFLOAT */

/* Define to 1 if you have the <cstdlib> header file. */
/* #undef HAVE_CSTDLIB */

/* Define to 1 if you have the <cstring> header file. */
/* #undef HAVE_CSTRING */

/* Define to 1 if you have the <cunistd> header file. */
/* #undef HAVE_CUNISTD */

/* Define to 1 if you have the <fcntl.h> header file. */
#define HAVE_FCNTL_H 1

/* Define to 1 if you have the `getenv' function. */
#define HAVE_GETENV 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if the system has the type `long double'. */
#define HAVE_LONG_DOUBLE 1

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if you have the `memset' function. */
#define HAVE_MEMSET 1

/* define if the compiler implements namespaces */
#define HAVE_NAMESPACES /**/

/* Define to 1 if you have the `open' function. */
#define HAVE_OPEN 1

/* Define to 1 if you have the <openssl/ssl.h> header file. */
#define HAVE_OPENSSL_SSL_H 1

/* Define to 1 if you have the `setenv' function. */
#define HAVE_SETENV 1

/* 1: OpenSSL >= 0.9.9 */
#define HAVE_SSL_OP_NO_COMPRESSION 0

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* define if the compiler supports Standard Template Library */
#define HAVE_STL /**/

/* Define to 1 if you have the `strcasecmp' function. */
#define HAVE_STRCASECMP 1

/* Define to 1 if you have the `strchr' function. */
#define HAVE_STRCHR 1

/* Define to 1 if you have the `strdup' function. */
#define HAVE_STRDUP 1

/* Define to 1 if you have the `strerror' function. */
#define HAVE_STRERROR 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the `strrchr' function. */
#define HAVE_STRRCHR 1

/* Define to 1 if you have the `strstr' function. */
#define HAVE_STRSTR 1

/* Define to 1 if you have the `strtod' function. */
#define HAVE_STRTOD 1

/* Define to 1 if you have the `strtol' function. */
#define HAVE_STRTOL 1

/* Define to 1 if you have the `strtoul' function. */
#define HAVE_STRTOUL 1

/* Define to 1 if you have the <sys/socket.h> header file. */
#define HAVE_SYS_SOCKET_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have <sys/wait.h> that is POSIX.1 compatible. */
#define HAVE_SYS_WAIT_H 1

/* Define to 1 if the system has the type `uint32_t'. */
#define HAVE_UINT32_T 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to 1 if you have the <w32api.h> header file. */
/* #undef HAVE_W32API_H */

/* Define to 1 if you have the <windows.h> header file. */
/* #undef HAVE_WINDOWS_H */

/* Define to 1 if you have the `wordexp' function. */
#define HAVE_WORDEXP 1

/* Define to 1 if you have the `X509_check_host' function. */
/* #undef HAVE_X509_CHECK_HOST */

/* Host id string. */
#define HOST_ARCH "x86_64-apple-darwin13.4.0"

/* Host cpu type */
#define HOST_CPU "x86_64"

/* Long host operating system type */
#define HOST_OS_LONG "darwin13.4.0"

/* Short host os type */
#define HOST_OS_SHORT "darwin13.4.0"

/* Host vendor type */
#define HOST_VENDOR "apple"

/* Name of package */
#define PACKAGE "adimat-client"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "adimat-users@lists.sc.informatik.tu-darmstadt.de"

/* Define to the full name of this package. */
#define PACKAGE_NAME "ADiMat-Client"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "ADiMat-Client 0.6.0"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "adimat-client"

/* Define to the home page for this package. */
#define PACKAGE_URL "http://www.adimat.de/"

/* Define to the version of this package. */
#define PACKAGE_VERSION "0.6.0"

/* The size of `unsigned int', as computed by sizeof. */
#define SIZEOF_UNSIGNED_INT 4

/* The size of `unsigned long', as computed by sizeof. */
#define SIZEOF_UNSIGNED_LONG 8

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* whether wordexp should be used */
#define USE_WORDEXP 1

/* Version number of package */
#define VERSION "0.6.0"

/* Define to empty if `const' does not conform to ANSI C. */
/* #undef const */

/* Define to `__inline__' or `__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef __cplusplus
/* #undef inline */
#endif

/* The prefix where ADiMat is installed. */
#define install_prefix "/Users/Wendydi/Documents/MATLAB/ADIMAT/adimat"

/* Define to `int' if <sys/types.h> does not define. */
/* #undef pid_t */

/* Define to `unsigned int' if <sys/types.h> does not define. */
/* #undef size_t */
