/***********<< defs.h >>*********************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdarg.h>
#include <time.h>
#include <string.h>
#include "structs.h"
#include "randlib.h"

#define  DEFAULT_CYCLES  ( 16 )


/* Constants for index u */
#define MUA (0)
#define MUS (1)


#define  round(x)       ((int)(x+0.5))
#define  SG(A,B)        ((A) > (B) ? 1.0 : -1.0)
#define  AbsSquare(R,I) ((R)*(R)+(I)*(I))


