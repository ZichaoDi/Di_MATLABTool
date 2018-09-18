SUBDIRS = util src

project_files=

EXTRA_DIST = adimatc-client.spec Makefile.am missing aclocal.m4 configure.ac install-sh

instdir = $(datadir)/doc/$(PACKAGE)

inst_DATA= $(project_files)

install-recursive all-recursive: svn-version.txt

svn-version.txt: . 
	if ! svn info > /dev/null; then \
	   echo "files are exported"; \
	else \
	   svnversion . > $@.tmp; \
	   if ! diff $@.tmp $@ > /dev/null; then cp $@.tmp $@; else echo "$@ is unchanged"; fi; \
	   $(RM) $@.tmp; \
	fi

clean-local:
	$(RM) -f *.xml

distclean-local:
	$(RM) -f svn-version.txt

M4_FILES= $(top_srcdir)/config/AC_CXX_HAVE_STL.m4 \
	$(top_srcdir)/config/AC_CXX_NAMESPACES.m4 \
	$(top_srcdir)/config/av_CONDITIONAL_WIN32.m4 \
	$(top_srcdir)/config/av_DEBUG.m4 \
	$(top_srcdir)/config/acx_pthread.m4

$(top_srcdir)/acinclude.m4: $(M4_FILES)
	cat >$(top_srcdir)/acinclude.m4 $(M4_FILES)

METASOURCES = AUTO
