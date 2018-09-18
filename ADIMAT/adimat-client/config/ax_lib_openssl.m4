# ===========================================================================
#             http://autoconf-archive.cryp.to/ax_lib_openssl.html
# ===========================================================================
#
# SYNOPSIS
#
#   AX_LIB_OPENSSL()
#
# DESCRIPTION
#
#   Test for the OpenSSL library
#
#   If no intallation prefix to the installed SQLite library is given the
#   macro searches under /usr, /usr/local, and /opt.
#
#   This macro calls:
#
#     AC_SUBST(OPENSSL_CFLAGS)
#     AC_SUBST(OPENSSL_LDFLAGS)
#     AC_SUBST(OPENSSL_LIBS)
#
#   And sets:
#
#     HAVE_OPENSSL_H
#
# LAST MODIFICATION
#
#   2010-02-22
#
# COPYLEFT
#
#   Copyright (c) 2010 Johannes Willkomm <johannes.willkomm@rwth-aachen.de>
#   Copyright (c) 2008 Mateusz Loskot <mateusz@loskot.net>
#
#   Copying and distribution of this file, with or without modification, are
#   permitted in any medium without royalty provided the copyright notice
#   and this notice are preserved.

AC_DEFUN([AX_LIB_OPENSSL],
[
    AC_ARG_WITH([openssl],
        AC_HELP_STRING(
            [--with-openssl=@<:@ARG@:>@],
            [use OpenSSL @<:@default=yes@:>@, optionally specify the prefix for OpenSSL library]
        ),
        [
        if test "$withval" = "no"; then
            WANT_OPENSSL="no"
        elif test "$withval" = "yes"; then
            WANT_OPENSSL="yes"
            ac_openssl_path=""
        else
            WANT_OPENSSL="yes"
            ac_openssl_path="$withval"
        fi
        ],
        [WANT_OPENSSL="yes"]
    )

    OPENSSL_CFLAGS=""
    OPENSSL_LDFLAGS=""
    OPENSSL_LIBS=""

    if test "x$WANT_OPENSSL" = "xyes"; then

        saved_CPPFLAGS="$CPPFLAGS"
        saved_LDFLAGS="$LDFLAGS"
        saved_LIBS="$LIBS"

        if test "$ac_openssl_path" != ""; then
            ac_openssl_ldflags="-L$ac_openssl_path/lib"
            ac_openssl_cppflags="-I$ac_openssl_path/include"
        fi

        CPPFLAGS="$CPPFLAGS $ac_openssl_cppflags"
        LDFLAGS="$LDFLAGS $ac_openssl_ldflags"

        AC_SEARCH_LIBS([inflateEnd], [z], [ac_openssl_z_found=yes], [ac_openssl_z_found=no], [${PTHREAD_CFLAGS} ${PTHREAD_LIBS} ${WIN32_LIBS}])
        
        REQ_LIBS=""
        if test "$ac_openssl_z_found" = "yes"; then
                REQ_LIBS="${ac_cv_search_inflateEnd}"
        fi

        # First, check for the function SSL_CTX_free in -lssl
        # this will set LIBS = "-lopenssl" if it succeeds
        # it succeeds when the functions can be linked against
        #  note that CPPFLAGS and LDFLAGS are set with the supposedly proper flags
        #  using the value of ac_openssl_path obtained from --with-openssl
        # if it failes it means there is no adequate openssl library for the compiler
        AC_SEARCH_LIBS([X509_TRUST_add], [crypto], [ac_openssl_crypto_found=yes], [ac_openssl_crypto_found=no], [${PTHREAD_CFLAGS} ${PTHREAD_LIBS} ${REQ_LIBS} ${WIN32_LIBS}])
        REQ_LIBS="${ac_cv_search_X509_TRUST_add} ${REQ_LIBS}"

        AC_SEARCH_LIBS([SSL_CTX_free], [ssl], [ac_openssl_found=yes], [ac_openssl_found=no], [${PTHREAD_CFLAGS} ${PTHREAD_LIBS} ${REQ_LIBS} ${WIN32_LIBS}])

        ac_openssl_libs="${ac_cv_search_SSL_CTX_free} $REQ_LIBS"

        # Now do AC_CHECK_HEADERS. this is a repeated joke, but it 
        # gives us the HAVE_OPENSSL_SSL_H define.
        AC_CHECK_HEADERS([openssl/ssl.h])

        # Now do check for X509_check_host, which will come out with OpenSSL 1.1.
        AC_CHECK_FUNCS(X509_check_host, [ac_openssl_X509_check_host_found=yes], [ac_openssl_X509_check_host_found=no])

        CPPFLAGS="$saved_CPPFLAGS"
        LDFLAGS="$saved_LDFLAGS"
        LIBS="$saved_LIBS"

        if test "$ac_openssl_found" = "yes"; then

            OPENSSL_CFLAGS="$ac_openssl_cppflags"
            OPENSSL_LDFLAGS="$ac_openssl_ldflags"
            OPENSSL_LIBS="$ac_openssl_libs"

            AC_SUBST(OPENSSL_CFLAGS)
            AC_SUBST(OPENSSL_LDFLAGS)
            AC_SUBST(OPENSSL_LIBS)
        fi
    fi
])
