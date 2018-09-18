bin_PROGRAMS = adimat-client
if acond_ADIMAT_DEBUG
bin_PROGRAMS += adimat-xml-test
bin_PROGRAMS += adimat-ssl-test
endif

#SUBDIRS = docs

adimat_client_CXXFLAGS = $(LIBXML2_CFLAGS) $(OPENSSL_CFLAGS)
adimat_client_SOURCES = adimat-client-opts.cpp adimat-client.cpp connection.cpp statics-adimat-client.cpp
adimat_client_LDADD = -lclientutil $(LIBXML2_LDFLAGS) $(OPENSSL_LIBS) $(WIN32_LIBS)
adimat_client_LDFLAGS = -L $(top_builddir)/util $(OPENSSL_LDFLAGS)
adimat_client_DEPENDENCIES = $(top_builddir)/util/libclientutil.a

adimat_xml_test_SOURCES = adimat-xml-test.cpp
adimat_xml_test_CPPFLAGS = $(LIBXML2_CFLAGS)
adimat_xml_test_LDADD = -lclientutil $(LIBXML2_LDFLAGS) $(WIN32_LIBS)
adimat_xml_test_LDFLAGS = -L $(top_builddir)/util
adimat_xml_test_DEPENDENCIES = $(top_builddir)/util/libclientutil.a

adimat_ssl_test_CXXFLAGS = $(OPENSSL_CFLAGS)
adimat_ssl_test_SOURCES = adimat-ssl-test.cpp
adimat_ssl_test_LDADD = $(OPENSSL_LIBS) $(WIN32_LIBS)
adimat_ssl_test_LDFLAGS = $(OPENSSL_LDFLAGS)

# The headerfile of the commandline arguments parser is generated from
# the .ggo file.
adimat-client-opts.hh: adimat-client-opts.cpp
adimat-client-opts.cpp: adimat-client-opts.ggo
	$(GENGETOPT) -F $(*F) -c cpp -H hh -C --no-handle-version \
               --no-handle-help --no-handle-error -i $< --unamed-opts
adimat-client.o: adimat-client-opts.hh

param-case-stmt.hh: $(top_srcdir)/xsl/gen-param-case-stmt-cpp.xsl $(top_srcdir)/xml/adimat-flags.xml
	xsltproc -o $@ $^

param-case-stmt.sh: $(top_srcdir)/xsl/gen-param-case-stmt.xsl $(top_srcdir)/xml/adimat-flags.xml
	xsltproc -o $@ $^

AM_CPPFLAGS= -I$(top_srcdir)/util $(PTHREAD_CFLAGS) 

all-am-local:

instbasedir=$(pkgdatadir)
instdir= $(instbasedir)

inst_DATA =

clean-local:
	-$(RM) adimat-client-opts.cpp adimat-client-opts.hh #param-case-stmt.sh param-case-stmt.hh

FORCE:


