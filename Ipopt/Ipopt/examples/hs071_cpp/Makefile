# Copyright (C) 2005, 2010 International Business Machines and others.
# All Rights Reserved.
# This file is distributed under the Eclipse Public License.

# $Id: Makefile.in 2016 2011-06-15 08:53:32Z stefan $

##########################################################################
#    You can modify this example makefile to fit for your own program.   #
#    Usually, you only need to change the five CHANGEME entries below.   #
##########################################################################

# CHANGEME: This should be the name of your executable
EXE = hs071_cpp

# CHANGEME: Here is the name of all object files corresponding to the source
#           code that you wrote in order to define the problem statement
OBJS = hs071_main.o \
	hs071_nlp.o

# CHANGEME: Additional libraries
ADDLIBS =

# CHANGEME: Additional flags for compilation (e.g., include flags)
ADDINCFLAGS =

##########################################################################
#  Usually, you don't have to change anything below.  Note that if you   #
#  change certain compiler options, you might have to recompile Ipopt.   #
##########################################################################

# C++ Compiler command
CXX = g++

# C++ Compiler options
CXXFLAGS = -O3 -pipe -DNDEBUG -Wparentheses -Wreturn-type -Wcast-qual -Wall -Wpointer-arith -Wwrite-strings -Wconversion -Wno-unknown-pragmas -Wno-long-long   -DIPOPT_BUILD

# additional C++ Compiler options for linking
CXXLINKFLAGS = 

# Include directories (we use the CYGPATH_W variables to allow compilation with Windows compilers)
INCL = `PKG_CONFIG_PATH=/nfs2/wendydi/Documents/Research/Di_MATLABtool/Ipopt/lib64/pkgconfig:/nfs2/wendydi/Documents/Research/Di_MATLABtool/Ipopt/lib/pkgconfig:/nfs2/wendydi/Documents/Research/Di_MATLABtool/Ipopt/share/pkgconfig: pkg-config --cflags ipopt` $(ADDINCFLAGS)
#INCL = -I`$(CYGPATH_W) /nfs2/wendydi/Documents/Research/Di_MATLABtool/Ipopt/include/coin`  $(ADDINCFLAGS)

# Linker flags
LIBS = `PKG_CONFIG_PATH=/nfs2/wendydi/Documents/Research/Di_MATLABtool/Ipopt/lib64/pkgconfig:/nfs2/wendydi/Documents/Research/Di_MATLABtool/Ipopt/lib/pkgconfig:/nfs2/wendydi/Documents/Research/Di_MATLABtool/Ipopt/share/pkgconfig: pkg-config --libs ipopt`
##LIBS = -link -libpath:`$(CYGPATH_W) /nfs2/wendydi/Documents/Research/Di_MATLABtool/Ipopt/lib` libipopt.lib -lm  -ldl
#LIBS = -L/nfs2/wendydi/Documents/Research/Di_MATLABtool/Ipopt/lib -lipopt -lm  -ldl

# The following is necessary under cygwin, if native compilers are used
CYGPATH_W = echo

all: $(EXE)

.SUFFIXES: .cpp .c .o .obj

$(EXE): $(OBJS)
	bla=;\
	for file in $(OBJS); do bla="$$bla `$(CYGPATH_W) $$file`"; done; \
	$(CXX) $(CXXLINKFLAGS) $(CXXFLAGS) -o $@ $$bla $(ADDLIBS) $(LIBS)

clean:
	rm -rf $(EXE) $(OBJS) ipopt.out

.cpp.o:
	$(CXX) $(CXXFLAGS) $(INCL) -c -o $@ $<


.cpp.obj:
	$(CXX) $(CXXFLAGS) $(INCL) -c -o $@ `$(CYGPATH_W) '$<'`
