# Process this file with autoconf to produce a configure script.
AC_INIT(ADiMat-Client, 0.6.0, [adimat-users@lists.sc.informatik.tu-darmstadt.de], 
          adimat-client, [http://www.adimat.de/])

AC_CONFIG_AUX_DIR(config)
AC_CANONICAL_TARGET
AH_TOP([#include "config_pre.h"])
AM_CONFIG_HEADER([config.h])
AM_INIT_AUTOMAKE()

AC_PROG_MAKE_SET
AC_PROG_AWK
# Checks for programs.
AC_PROG_CXX
AC_PROG_CC
AC_PROG_CPP
AC_PROG_LN_S
#AC_PROG_LD
AC_PROG_RANLIB
#AC_PROG_INSTALL

AC_CHECK_TOOL([STRIP], [strip], [strip-for-host-system-was-not-found])

AC_CHECK_PROGS([CP], [cp copy])
AC_CHECK_PROGS([RM], [rm del])
AC_CHECK_PROGS([MV], [mv rename])
AC_CHECK_PROGS([BASENAME], [basename])
AC_CHECK_PROGS([SGML2HTML], ['linuxdoc -B html' sgml2html])
AC_CHECK_PROGS([SGML2INFO], ['linuxdoc -B info' sgml2info])
AC_CHECK_PROGS([UNIX2DOS], [u2d unix2dos])
AC_CHECK_PROGS([GHEAD], [ghead head])

AC_ARG_ENABLE([adimat-home], [  --enable-adimat-home    Set adimat-home different from install prefix. This should be only used by package builders.
  --disable-adimat-home   Sets adimat_home to \$prefix.], [
      adimat_home=$enableval
], [ 
      adimat_home=${prefix} 
])
AC_MSG_CHECKING([setting adimat_home])
AC_MSG_RESULT([adimat_home=$adimat_home])
AC_SUBST(adimat_home)

AC_ARG_ENABLE([static], [  --enable-static         Build statically linked executables.
  --disable-static        Build dynamically linked executables.], [
      static_build=$enableval
], [ 
      static_build=no
])
AC_MSG_CHECKING([setting static_build])
AC_MSG_RESULT([static_build=$static_build])
if test "$static_build" = "yes"; then
   LDFLAGS="$LDFLAGS -static"
   defval_STATIC_BUILD=1
else
   defval_STATIC_BUILD=0
fi
AC_DEFINE_UNQUOTED([ADIMAT_STATIC_BUILD], [$defval_STATIC_BUILD], [1: static build])
AM_CONDITIONAL(acond_STATIC_BUILD, [test "x$static_build" = "xyes"])

av_DEBUG
AM_CONDITIONAL(acond_ADIMAT_DEBUG, [test "x$ADIMAT_DEBUG" = "xyes"])

AM_CONDITIONAL(SGML2HTML_EXISTS, [test ! "x$SGML2HTML" = "x"])
av_CONDITIONAL_WIN32

# Checks for header files.
AC_HEADER_STDC
#AC_HEADER_DIRENT
#AC_HEADER_STDBOOL no bool in C-files
AC_HEADER_SYS_WAIT
#AC_CHECK_HEADERS([], , AC_MSG_ERROR([mandatory header file not found!]))
AC_CHECK_HEADERS([cfloat cstdlib cstring cctype cunistd])
AC_CXX_HAVE_STL

# Create variables telling the operating system name in a string.
AC_DEFINE_UNQUOTED(HOST_ARCH, "$target", [Host id string.])
AC_DEFINE_UNQUOTED(HOST_CPU, "$target_cpu", [Host cpu type])
AC_DEFINE_UNQUOTED(HOST_VENDOR, "$target_vendor", [Host vendor type])
AC_DEFINE_UNQUOTED(HOST_OS_LONG, "$target_os", [Long host operating system type])
target_os_short=`echo "$target_os" |sed -e s/-.*//`
AC_DEFINE_UNQUOTED(HOST_OS_SHORT, "$target_os_short", [Short host os type])
AC_DEFINE_UNQUOTED(install_prefix, "$prefix", [The prefix where ADiMat is installed.])
AC_DEFINE_UNQUOTED(ADIMAT_DEFAULT_HOME, "$adimat_home", [The default ADiMat home directory.])

if test -z "$SVN_REVISION"; then
   echo "obtaining svnversion"
   SVN_REVISION=`svnversion .`
fi                         
AC_MSG_CHECKING([value for SVN_REVISION])
AC_MSG_RESULT([$SVN_REVISION])
AC_SUBST([SVN_REVISION])

echo "creating svn-version.txt"
echo "$SVN_REVISION" > svn-version.txt
av_LONG_VERSION="$VERSION-`cat svn-version.txt | tr ':' '_'`"
AC_MSG_CHECKING([value for LONG_VERSION])
AC_MSG_RESULT([$av_LONG_VERSION])

echo "creating VERSION_NUMBER"
VERSION_NUMBER=`echo "$VERSION" | sed -e 's/\.//2'`
AC_DEFINE_UNQUOTED(ADIMAT_VERSION_NUMBER, $VERSION_NUMBER, [A string describing the current ADiMat version as a floating point number.])
AC_SUBST(VERSION_NUMBER)
AC_MSG_CHECKING([value for VERSION_NUMBER])
AC_MSG_RESULT([$VERSION_NUMBER])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_C_INLINE
AC_TYPE_SIZE_T
AC_TYPE_PID_T
AC_CHECK_TYPES(long double)
# Find a type that is 32 bit wide
AC_CHECK_TYPES(uint32_t)
AC_CHECK_SIZEOF(unsigned int)
AC_CHECK_SIZEOF(unsigned long)

AC_CHECK_FUNCS([strchr strerror strrchr strstr strtol strtod strtoul], ,AC_MSG_ERROR([mandatory function not found!]))
av_store_CFLAGS="$CFLAGS"
CFLAGS="$AM_CFLAGS $CFLAGS"
AC_CHECK_FUNCS([atexit setenv getenv strdup strcasecmp memset])

# check for presence of the open function and its header fcntl.h
AC_CHECK_HEADERS([sys/types.h])
AC_CHECK_HEADERS([sys/stat.h])
AC_CHECK_HEADERS([sys/socket.h])
AC_CHECK_HEADERS([fcntl.h])
AC_CHECK_FUNCS([open])

AC_MSG_CHECKING([Whether adimat-client should ask for confirmation (enable-confirmation)])
AC_ARG_ENABLE(confirmation, [  --enable-confirmation   Ask for confirmation before sending files over the internet.],
                            [  enable_confirmation=$enableval  ],
                            [  enable_confirmation=yes ])
if test "x${enable_confirmation}" = "xyes"; then
   AC_MSG_RESULT([yes])
   confirmation_value="false()"
else
   AC_MSG_RESULT([no])
   confirmation_value="true()"
fi
AC_SUBST(confirmation_value)

AC_ARG_ENABLE([server-base], [  --enable-server-base    Set server-base different from /adimat/.
  --disable-server-base   Sets adimat_home to /adimat/], [
      server_base=$enableval
], [ 
      server_base="/"
])
if ! test "${server_base:0:1}" = "/"; then
   server_base=/$server_base
fi
AC_MSG_CHECKING([setting server_base])
AC_MSG_RESULT([server_base=$server_base])
AC_SUBST(server_base)
AC_DEFINE_UNQUOTED(ADIMAT_SERVER_BASE, "$server_base", [The base URI of the ADiMat web server.])

AC_ARG_ENABLE([cgi-suffix], [  --enable-cgi-suffix     Set cgi-suffix different from ".fcgi".
  --disable-cgi-suffix    Sets cgi_suffix to ".fcgi"], [
      cgi_suffix=$enableval
], [ 
      cgi_suffix=".fcgi"
])
AC_MSG_CHECKING([setting cgi_suffix])
AC_MSG_RESULT([cgi_suffix=$cgi_suffix])
AC_SUBST(cgi_suffix)

AC_ARG_ENABLE([server-name], [  --enable-server-name    Set server-name.
  --disable-server-name   Sets server_name to nb-willkomm.rz.rwth-aachen.de], [
      server_name=$enableval
], [ 
      server_name="adimat.sc.informatik.tu-darmstadt.de"
])
AC_MSG_CHECKING([setting server_name])
AC_MSG_RESULT([server_name=$server_name])
AC_SUBST(server_name)

AC_CHECK_FUNCS([wordexp])
AC_MSG_CHECKING([if wordexp should be used if present])
AC_ARG_ENABLE([wordexp], [  --enable-wordexp        Use the wordexp function to expand variables search path strings.
  --disable-wordexp       Do not use wordexp.], [
  case "${enableval}" in
      yes) use_wordexp=1; AC_MSG_RESULT([yes]) ;;
      no)  use_wordexp=0; AC_MSG_RESULT([no]) ;;
      *) AC_MSG_ERROR([bad value ${enableval} for --enable-wordexp]) ;;
  esac
], [ 
      AC_MSG_RESULT([yes])
      use_wordexp=1
])
if test "x$use_wordexp" = "x1"; then
   AC_DEFINE_UNQUOTED(USE_WORDEXP, $use_wordexp, [whether wordexp should be used])
fi

CFLAGS="${av_store_CFLAGS}"

AC_CHECK_PROGS([GENGETOPT], [gengetopt])
if test "x$GENGETOPT" = "x"; then
   AC_MSG_ERROR([mandatory program gengetopt was not found])
fi

AC_SEARCH_LIBS([dlopen],[dl],[av_LIBDL_FOUND=yes],[av_LIBDL_FOUND=no])

if test "$av_local_target_win32" = "yes"; then
   echo "Looking for networking functions on Win32..."
   AC_CHECK_HEADERS([windows.h w32api.h])
#   AC_SEARCH_LIBS([WSAStartup@8], [ws2_32], [WINSOCK_FOUND=yes], [WINSOCK2_FOUND=no], [${PTHREAD_CFLAGS} ${PTHREAD_LIBS}])                                                                                                                                                    
   WIN32_LIBS="-lws2_32 -lgdi32"
   AC_SUBST(WIN32_LIBS)
fi

AX_LIB_OPENSSL

save_CPPFLAGS=$CPPFLAGS
CPPFLAGS=$OPENSSL_CFLAGS
AC_CHECK_DECL(SSL_OP_NO_COMPRESSION, [av_ssl_no_comp_found=1], [av_ssl_no_comp_found=0], [#include <openssl/ssl.h>])
CPPFLAGS=$save_CPPFLAGS

AC_DEFINE_UNQUOTED([HAVE_SSL_OP_NO_COMPRESSION], [$av_ssl_no_comp_found], [1: OpenSSL >= 0.9.9])


AC_ARG_WITH([libxml2], [  --with-libxml2=path     Specify the path where the libxml2 resides.],
      [if test ! "x$withval" = "x" ; then
         LIBXML2="$withval"
      fi
      AC_SUBST(LIBXML2)]
)
AC_MSG_CHECKING([using libxml2])
AC_MSG_RESULT([LIBXML2=$LIBXML2])

AC_PATH_PROGS([XML2CONFIG], [xml2-config], 
  [xml2-config-was-not-found], [$LIBXML2/bin:$PATH])
AC_SUBST(XML2CONFIG)
LIBXML2_CFLAGS=$($XML2CONFIG --cflags)
AC_SUBST(LIBXML2_CFLAGS)
if test "$static_build" = "yes"; then
   if $XML2CONFIG --help | grep static > /dev/null; then
      LIBXML2_LDFLAGS=$($XML2CONFIG --libs --static)
   else  
      LIBXML2_LDFLAGS=$($XML2CONFIG --libs)
   fi
else
   LIBXML2_LDFLAGS=$($XML2CONFIG --libs)
fi
dnl AC_SUBST(LIBXML2_LDFLAGS)

LIBXML2_STATIC_LDFLAGS=""
if test "$static_build" = "yes"; then
   if test "${LIBXML2_LDFLAGS#*pthread}" != "$LIBXML2_LDFLAGS"; then
dnl whatever the combination of PTHREAD_LIBS/PTHREAD_CFLAGS is, we assume
dnl there exists a libpthread.a which we can include wholly into the
dnl executable (necessary for libxml2, else crash)
      LIBXML2_STATIC_LDFLAGS="$(echo $LIBXML2_LDFLAGS | sed 's/-lpthread//') -Wl,--whole-archive -lpthread -Wl,--no-whole-archive"
      LIBXML2_LDFLAGS="$LIBXML2_STATIC_LDFLAGS"
   fi
   if test "$av_local_target_win32" != "yes"; then
      LIBXML2_LDFLAGS="$LIBXML2_LDFLAGS -llzma"
   fi
fi
dnl AC_SUBST(LIBXML2_STATIC_LDFLAGS)
AC_SUBST(LIBXML2_LDFLAGS)


AC_CONFIG_FILES([Makefile
                 src/Makefile
                 src/adimat-client-opts.ggo
                 util/Makefile
                 ])

AC_OUTPUT

echo ""
echo "configure is finished"
echo " PREFIX = $prefix"
echo " PACKAGE_NAME = $PACKAGE_NAME"
echo " VERSION = $VERSION"
echo " LONG_VERSION = $av_LONG_VERSION"
echo ""
echo "Compiler settings"
echo " CXX = $CXX"
echo " CXX_VERSION = `$CXX --version`"
echo " CPPFLAGS = $CPPFLAGS"
echo " DEFS = $DEFS"
echo " CFLAGS = $CFLAGS"
echo " CXXFLAGS = $CXXFLAGS"
echo " LDFLAGS = $LDFLAGS"
echo " LIBS = $LIBS"
echo ""
echo " SGML2INFO = $SGML2INFO"
echo " GENGETOPT = $GENGETOPT"
echo ""
echo " PTHREAD_CFLAGS = $PTHREAD_CFLAGS"
echo " PTHREAD_LIBS = $PTHREAD_LIBS"
echo ""
echo " OPENSSL_CFLAGS = $OPENSSL_CFLAGS"
echo " OPENSSL_LDFLAGS = $OPENSSL_LDFLAGS"
echo " OPENSSL_LIBS = $OPENSSL_LIBS"
echo ""
echo " LIBXML2 = $LIBXML2"
echo " XML2CONFIG = $XML2CONFIG"
echo " LIBXML2_CFLAGS = $LIBXML2_CFLAGS"
echo " LIBXML2_LDFLAGS = $LIBXML2_LDFLAGS"
echo ""
echo " LIBXML2_STATIC_LDFLAGS = $LIBXML2_STATIC_LDFLAGS"
echo ""
echo " WIN32_LIBS = $WIN32_LIBS"
echo ""
echo " DBBUILD = $DBBUILD"
echo " static_build = $static_build"
echo " adimat_home = $adimat_home"

echo ""
echo "No run make to compile, make install to install"
echo ""
