# av_DEBUG
# ----------
#
# Check if the --enable-debug-flag was given, add -g to CFLAGS 
# and CXXFLAGS then, and add -DDEBUG and -DSTATS to CPPFLAGS

AC_DEFUN([av_DEBUG], [
    AC_REQUIRE([AC_PROG_CC])
    AC_REQUIRE([AC_PROG_CXX])
    AC_REQUIRE([AC_CANONICAL_TARGET])
    AC_ARG_ENABLE([debug], [  --enable-debug          Add debug symbols to the executable (CFLAGS-='-g') and set some debugging defines.
  --disable-debug         Does nothing.], [
      AC_MSG_CHECKING([whether --enable-debug was given])
      CPPFLAGS="$CPPFLAGS -DDEBUG -DSTATS"
      CFLAGS="$CFLAGS -g"
      CXXFLAGS="$CXXFLAGS -g"
      AC_SUBST([ADIMAT_DEBUG], [yes])
      AC_MSG_RESULT([yes, CPPFLAGS='$CPPFLAGS', CFLAGS='${CFLAGS}', CXXFLAGS='${CXXFLAGS}', LDFLAGS='${LDFLAGS}'])
    ],  [ 
      AC_MSG_CHECKING([whether --enable-debug was given])
      AC_SUBST([ADIMAT_DEBUG], [no])
      AC_MSG_RESULT([no])
])
])

