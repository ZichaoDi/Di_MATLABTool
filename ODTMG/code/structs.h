#include "liststructs.h"

typedef double dtype;     /* data type for parameters */

typedef float  mtype;     /* data type for matrix     */ 


typedef struct src_parameter{   /* for source parameter */
  dtype x; dtype y; dtype z;    /* x-y-z position of source */
  dtype omega;                  /* modulation frequency */
  dtype beta;                   /* modulation depth     */
  dtype calir;                  /* real part of calibration */
  dtype calii;                  /* imaginary part of calibration */
} src_param;


typedef struct det_parameter{   /* for detector parameter */
  dtype x; dtype y; dtype z;    /* x-y-z position of detector */
  dtype omega;
  dtype calir;                  /* real part of calibration */
  dtype calii;                  /* imaginary part of calibration */
} det_param;


typedef struct phys_parameter{
  dtype xmin;    dtype xmax;   int Ni;
  dtype ymin;    dtype ymax;   int Nj;
  dtype zmin;    dtype zmax;   int Nl;
  int K;         int M;
  int S;  /* Number of measurements, not nec. K*M */

  LINK2D sparse;
 
  mtype v; 

  mtype wgtr;
  mtype wgti;

} phys_param;


typedef struct prior_parameter{  /* for MRF prior model of x */ 
  double (*rho)(double, double, double, double);  /* potential fn, rho(xi,xj,sigma,p) */
  dtype sigma;
  dtype p;
  int   Nneighbor;  /* Nneighbor=8 for 2D, Nneighbor=26 for 3D          */
  dtype *b;         /* MRF coefficients: pointer to array b[Nneighobor] */
} prior_param;  

typedef struct config_info{
  int borderi;
  int borderj;
  int borderl;

  int niterations;
  double rmse_tol;
  double alpha_bound;

  double mua_backg;
  double D_backg;
 
  double init_wgtr; 
  double init_wgti; 

  char muhatpath[255];
  int  mu_store_flag;
  char resultpath[255];
  
  char init_guess_path[255];
  char init_guess_varname[255];      

  char phys_file[255];
  char prior_D_file[255];
  char prior_mua_file[255];
  char meas_file[255];

  int calibration_flag;
  int homogeneous_flag;
  int mua_flag;
  int D_flag;

  int global_weight_flag;
  int init_guess_flag;     
  int border_update_flag;
 
  int hmax;

} config_param;
