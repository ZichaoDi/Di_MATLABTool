typedef float dtype;     /* data type for parameters */

typedef float mtype;     /* data type for matrix     */ 


typedef struct src_parameter{   /* for source parameter */
  int i;   int j;   int l;      /* i-j-l position of source */
  dtype omega;                  /* modulation frequency */
  dtype beta;                   /* modulation depth     */
} src_param;


typedef struct det_parameter{   /* for detector parameter */
  int i;   int j;   int l;      /* i-j-l position of detector */
} det_param;


typedef struct phys_parameter{
  dtype xmin;    dtype xmax;   int Ni;
  dtype ymin;    dtype ymax;   int Nj;
  dtype zmin;    dtype zmax;   int Nl;
  int K;         int M;
  mtype v; 
} phys_param;


typedef struct prior_parameter{  /* for MRF prior model of x */ 
  double (*rho)(double, double, double, double);  /* potential fn, rho(xi,xj,sigma,p) */
  dtype sigma;
  dtype p;
  int   Nneighbor;  /* Nneighbor=8 for 2D, Nneighbor=26 for 3D          */
  dtype *b;         /* MRF coefficients: pointer to array b[Nneighobor] */
} prior_param;  

