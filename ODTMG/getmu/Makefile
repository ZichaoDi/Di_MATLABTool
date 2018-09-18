
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

#CC      = $(CC_$(OS))
CC      = gcc 


LIB_OBJS = fileop.o randlib.o 
OBJ  = $(LIB_OBJS) gen_x.o 



# executible


all     : gen_x

clean:
	rm -f *.o  

randlib.o : randlib.c randlib.h  
	$(CC) $(CFLAGS)  $(INCLUDE) -c randlib.c 

fileop.o : fileop.c fileop.h  
	$(CC) $(CFLAGS)  $(INCLUDE) -c fileop.c 

gen_x.o : gen_x.c defs.h 
	$(CC) $(CFLAGS)  $(INCLUDE) -c gen_x.c

gen_x : gen_x.o fileop.o randlib.o defs.h 
#	$(CC) $(CFLAGS)  $(OBJ) $(LIBS) 
	$(CC) $(CFLAGS) $(INCLUDE) -o $(BIN)/getmu $(OBJ) $(LIBS) -lm



