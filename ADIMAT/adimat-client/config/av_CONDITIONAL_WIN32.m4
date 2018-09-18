
# av_CONDITIONAL_WIN32
# --------------------
#
# Check if the target system is win*** and set TARGET_WIN32 if it is
AC_DEFUN([av_CONDITIONAL_WIN32], [
    AC_REQUIRE([AC_CANONICAL_TARGET]) dnl
    AC_MSG_CHECKING([if target is cygwin or mingw])
    case $target in
      i686-w64-mingw* )
        av_local_target_win32="yes"
        AM_CFLAGS="-O3 -m32"
        AC_SUBST(AM_CFLAGS)
        AM_CXXFLAGS="-O3 -m32"
        AC_SUBST(AM_CXXFLAGS)
      ;;
      x86_64-w64-mingw* )
        av_local_target_win32="yes"
        AM_CFLAGS="-O3 -m64"
        AC_SUBST(AM_CFLAGS)
        AM_CXXFLAGS="-O3 -m64"
        AC_SUBST(AM_CXXFLAGS)
      ;;
      *-*-cygwin* | *-*-mingw* )
        av_local_target_win32="yes"
        case $build in
          *-*-cygwin* | *-*-mingw* )
            av_local_build_win32="yes"
            AC_MSG_RESULT([yes])
          ;;
          * )
            AC_MSG_WARN([Cross compiling for win32. Build is usable, but setup.exe can not be generated!])
          ;;
        esac
        AM_CFLAGS=" "
        AC_SUBST(AM_CFLAGS)
        AM_CXXFLAGS=" "
        AC_DEFINE_UNQUOTED(AD_MINGW32_WINNT_0501, 1, [Whether we use the old mingw cross complier])
        AC_SUBST(AM_CXXFLAGS)
      ;;
      * )
        AC_MSG_RESULT([no])
      ;;
    esac
    AM_CONDITIONAL(TARGET_WIN32, test "x$av_local_target_win32" = "xyes" )
    AM_CONDITIONAL(BUILD_WIN32, test "x$av_local_build_win32" = "xyes" )
])

