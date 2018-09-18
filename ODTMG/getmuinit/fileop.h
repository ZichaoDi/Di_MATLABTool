#define BIGEND (0)
#define SMALLEND (1)

#define HEADERSIZE (1024)
#define FOERR (-1)
#define NAMESIZE (80)

int byte_order_test(void);
/* 
Tests to see if machine stores data in big-endian or 
little-endian format, and returns BIGEND or SMALLEND 
(These names, rather than "BIG_ENDIAN" or the like, were 
chosen to avoid apparent conflicts with flags defined in
 the standard header files.)
*/

int write_int(
 /* IN */
  FILE *fp, 
  int byte_order, /* Byte order flag obtained from 
                       byte_order_test() */
  int writeme     /* Integer to be written */
);
/* 
Writes one integer (in little-endian format, regardless
of which machine is running this code) into a binary file 
*/


int write_float(
 /* IN */
  FILE *fp, 
  int byte_order, /* Byte order flag obtained from
                       byte_order_test() */
  float writeme   /* float to be written */
);
/* 
Writes one single-precision float 
(in little-endian format, regardless of which machine is 
running this code) into a binary file 
*/


int read_int(
 /* IN */
  FILE *fp, 
  int byte_order, /* Byte order flag obtained from
                       byte_order_test() */
 /* OUT */
  int *readme     /* Ptr to int to int read from file */
);
/* 
Reads one integer
(in little-endian format, regardless of which machine is 
running this code) from a binary file 
*/


int read_float(
 /* IN */
  FILE *fp,       
  int byte_order, /* Byte order flag obtained from
                       byte_order_test() */
 /* OUT */
  float *readme   /* Ptr to float read from file */
);
/* 
Reads one float 
(in little-endian format, regardless of which machine is 
running this code) from a binary file 
*/


int write_float_array(
 /* IN */
  FILE *fp,     
  char *name,   /* String containing data's variable name */
  float *data,  /* Address of zeroeth data element */
  int ndims,    /* The number of array dimensions, followed
                 by the dimensions themselves, in varargs list*/
  ...
);
/* 
Writes a multidimensional float array to a binary file. 
Note that even for an N-dimensional array, the data is 
assumed to be stored contiguously in memory (and in the
data file), in the same manner as the multialloc() function 
from the allocate library.  Hence, the data is passed 
as the address of the zeroeth array element.
(i.e., the argument list above has 
  float *data,
not 
  float ****...*data
which would have been needlessly more difficult to code using
the varargs data to determine the dimensions. 

Before actually writing the array, a line is appended to the
file's text header which shows the array's variable "name",
and its dimensions.  The data is then appended to the end of
of the file, with a preceding integer 0 used as an error-
checking place-holder. 
*/


int read_float_array(
 /* IN */
  FILE *fp, 
  char *name,  /* String containing data's variable name */
 /* OUT */
  float *data, /* Address of zeroeth data element */
 /* IN */
  int ndims,   /* Number of array dimensions, followd by the
                 dimensions themselves, in varargs list */
  ...
);
/*
Reads a multidimensional float array from a binary file. 
Note that even for an N-dimensional array, the data is 
assumed to be stored contiguously in memory (and in the
data file), in the same manner as the multialloc() function 
from the allocate library.  Hence, the data is passed 
as the address of the zeroeth array element.
(i.e., the argument list above has 
  float *data,
not 
  float ****...*data
which would have been needlessly more difficult to code using
the varargs data to determine the dimensions. 

Before actually reading the array, the file's text header is
scanned for the variable called "name" to determine 
where in the file the data resides (based on the size of the
arrays which precede it in the file).  Once
this is found, the appropriate portion of the file is accessed
and the data is read.
*/


int add_line_to_header(
 /* IN */
  FILE *fp,
  char *name, /* Variable name written to header */
  int *dims   /* Array describing dimensions of array, which
               are written to the text header.  
               dims[0] is the number of dimensions, and 
               dims[1], dims[2], ... are the dimensions
               themselves, in order */
);
/* 
Appends a line to the text header of the data file.
(Strictly speaking, nothing is actually appended to the
header.  A blank header consists of HEADER_SIZE '_'
characters.  This function overwrites an appropriate 
number of those, but doesn't actually increase the header
size.)  The new line of text in the file looks like:
name Ndims Dim1 Dim2 ... '\n'
where name is the string "name" representing a variable name,
Ndims is an integer representing the number of dimensions, and
Dim1, Dim2, ... are the dimensions themselves.
If header is full, FOERR is returned.  Otherwise, 0.
*/

void initialize_header(
 /* IN */
  FILE *fp
);
/*
Prints HEADERSIZE '_' characters into a file. These are 
overwritten when items are added to the header. 
*/

int find_array_with_name(
 /* IN,  OUT */
  FILE *fp,  
 /* IN */
  char *name, 
  int *dims
);
/* 
Looks for an item labeled "name" in the header, and moves
the file position indicator to the beginning of the data
corresponding to this header label.  (Hence, fp is both an
input and output variable.)  Note that each data array is 
preceded by an integer 0 as an error-checking placeholder.
The file position indicator is moved to

( HEADERSIZE )
+ (# of preceding arrays)*sizeof(int)  
+ (# of combined data elements in all preceding arrays)*
  sizeof(float)

where the second term corresponds to the number of
placeholding integer zeros, and the 3rd term corresponds
to the number of floats in all preceding arrays.
At this point, if all is well, the file position indicator
should now be sitting right on an integer zero, preceding
the desired data.  This is checked.  If OK, the file pos.
indicator is advanced to the first element of the data
and 0 is returned.  Otherwise, FOERR is returned because
something is wrong.
*/


FILE *datOpen(
 /* IN */
  char *filename, 
  char *mode
);
/*
Just like fopen(), but it also writes an initially blank
text header (full of '_') to the file.
*/

void datClose(
 /* IN */
  FILE *fp
);
/*
Just a glorified fclose()
*/
