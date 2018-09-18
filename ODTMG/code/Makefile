
# directory setting
BIN = .

# Fortran compiler settings
F77 = f77 -g 
OPT77 = -c 

#OS = HP-UX
OS = Linux
#OS = Solaris

CC_HP-UX = gcc
CC_Linux = gcc
CC_Solaris = gcc

# Choose the appropriate library and include path depending on the
# matlab version and architecture

LIBS_HP-UX   = -lm
LIBS_Linux   = -lm 
LIBS_Solaris = -lm 


CFLAGS_HP-UX   = -O -Wall -ansi -Werror
#CFLAGS_Linux   = -V 2.7.2.3 -g -Wall -ansi -Werror
CFLAGS_Linux   =-g -Wall -pedantic
CFLAGS_Solaris = -O -Wall -ansi

LIBS    = $(LIBS_$(OS))
INCLUDE = $(INCLUDE_$(OS))
CFLAGS  = $(CFLAGS_$(OS))

CC      = $(CC_$(OS))



LIB_OBJS = allocate.o randlib.o fileop.o textfile.o listfun.o
OBJ  = $(LIB_OBJS) cud3.o cudcom.o cud3ln.o cud3pn.o fwdsolver3d.o frechet.o calibrate.o homogeneous.o icd.o mgutil.o multigrid.o icdmain.o



# executible


all     : icdmain

clean:
	rm -f *.o  

icdmain : $(OBJ) 
	$(F77) -o $(BIN)/icdmain $(OBJ) $(LIBS)

allocate.o : allocate.c allocate.h
	$(CC) $(CFLAGS)  $(INCLUDE) -c allocate.c -o $@

randlib.o : randlib.c randlib.h
	$(CC) $(CFLAGS)  $(INCLUDE) -c randlib.c -o $@

fileop.o : fileop.c  fileop.h
	$(CC) $(CFLAGS)  $(INCLUDE) -c fileop.c -o $@

textfile.o : textfile.c  textfile.h
	$(CC) $(CFLAGS)  $(INCLUDE) -c textfile.c -o $@

listfun.o : listfun.c  listfun.h  liststructs.h
	$(CC) $(CFLAGS)  $(INCLUDE) -c listfun.c -o $@

cudcom.o : cudcom.f 
	$(F77) $(OPT77)  cudcom.f

cud3ln.o : cud3ln.f
	$(F77) $(OPT77)  cud3ln.f

cud3pn.o : cud3pn.f
	$(F77) $(OPT77)  cud3pn.f

cud3.o : cud3.f
	$(F77) $(OPT77)  cud3.f

fwdsolver3d.o : fwdsolver3d.f
	$(F77) $(OPT77)  fwdsolver3d.f

frechet.o : frechet.c $(LIB_OBJS) textfile.c fileop.c listfun.c  structs.h defs.h
	$(CC) $(CFLAGS)  $(INCLUDE) -c frechet.c $(LIB_OBJS) $(LIBS)

calibrate.o : calibrate.c $(LIB_OBJS) frechet.c fwdsolver3d.f listfun.c  structs.h defs.h
	$(CC) $(CFLAGS)  $(INCLUDE) -c calibrate.c $(LIB_OBJS) $(LIBS)

homogeneous.o : homogeneous.c $(LIB_OBJS) fileop.c textfile.c listfun.c structs.h defs.h 
	$(CC) $(CFLAGS)  $(INCLUDE) -c homogeneous.c $(LIB_OBJS) $(LIBS)

icd.o : icd.c $(LIB_OBJS) fileop.c textfile.c listfun.c structs.h defs.h 
	$(CC) $(CFLAGS)  $(INCLUDE) -c icd.c $(LIB_OBJS) $(LIBS)

mgutil.o : mgutil.c $(LIB_OBJS) fileop.c textfile.c listfun.c structs.h defs.h 
	$(CC) $(CFLAGS)  $(INCLUDE) -c mgutil.c $(LIB_OBJS) $(LIBS)

multigrid.o : multigrid.c $(LIB_OBJS) fileop.c textfile.c listfun.c structs.h defs.h 
	$(CC) $(CFLAGS)  $(INCLUDE) -c multigrid.c $(LIB_OBJS) $(LIBS)

icdmain.o : icdmain.c $(LIB_OBJS) fileop.c  textfile.c listfun.c structs.h defs.h 
	$(CC) $(CFLAGS)  $(INCLUDE) -c icdmain.c $(LIB_OBJS) $(LIBS)

