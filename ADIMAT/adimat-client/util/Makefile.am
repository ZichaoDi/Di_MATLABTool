
long-version.h: $(top_srcdir)/svn-version.txt
	echo "#define ADIMAT_LONG_VERSION \"$(VERSION)-`cat $<`\"" > $@

adimat-version.cpp: long-version.h

noinst_LIBRARIES = libclientutil.a

libclientutil_a_SOURCES = client-util.cpp stringtable.cpp		\
	mindnode.cpp mindlist.cpp searchpath.cpp item_searchpath.cpp	\
	fmt_ofstream.cpp loggingstream.cpp adimat-version.cpp		\
	windows-util.cpp libxml-util.cpp

libclientutil_a_CXXFLAGS = $(LIBXML2_CFLAGS)

clean-local:
	$(RM) -f long-version.h