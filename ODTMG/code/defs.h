/***********<< defs.h >>*********************************************************/

#include "structs.h"
#include "listfun.h"
#include <stdio.h>
#include <math.h>
#include <stdarg.h>
#include "allocate.h"
#include "randlib.h"
#include "fileop.h"
#include "textfile.h"
#include <time.h>


/* Compilation option */ 
/*#define SDVERSION  1 */   



#define  DEFAULT_CYCLES  ( 16 )


/* Constants for index u */
#define MUA (0)
#define MUS (1)

#define  round(x)       ((int)(x+0.5))
#define  SG(A,B)        ((A) > (B) ? 1.0 : -1.0)
#define  AbsSquare(R,I) ((R)*(R)+(I)*(I))
#define  cplxmultr(ar,ai,br,bi)  ((ar)*(br)-(ai)*(bi))
#define  cplxmulti(ar,ai,br,bi)  ((ar)*(bi)+(ai)*(br))
#define  min(A,B)       ((A) > (B) ? (B) : (A)) 

#define nfine(Ncoarse)    ((int)(Ncoarse) * 2 - 1)
#define ncoarse(Nfine)    ((int)(Nfine-1) / 2 + 1)        





/******************************************************************/
/***                     fwdsolver3d.f                          ***/
/******************************************************************/

/* FORTRAN function declarations  designed for SUN compilation*/
/* Solves elliptic PDE in form of diffusion equation */
extern int fwd3df_(
     /* Input */
  int *nnx,   /* 3-D array dimensions */
  int *nny, 
  int *nnz,
  float *xmin, /* Ranges of physical coords */
  float *xmax, 
  float *ymin, 
  float *ymax, 
  float *zmin, 
  float *zmax, 
  float *alpha, /* Array containing 1st PDE coeff: In C, alpha[i][j][l][c] 
                 * In FORTRAN, alpha(c+1,l+1,j+1,i+1) */
  float *beta,  /* Array containing 2nd PDE coeff: beta[i][j][l][c] 
                 * In FORTRAN, beta(c+1,l+1,j+1,i+1) */
  float *rhs,   /* Array containing RHS of PDE : rhs[i][j][l][c] 
                 * In FORTRAN, rhs(c+1,l+1,j+1,i+1) */
  int *iguessflag, /* 1 if initial guess should be used, 0 otherwise  */
  double *mudpkworkspace,
  int *mudpkworksize,
  double *rhsworkspace,
  double *phiworkspace,
  int *ncycles,    /* Number of multigrid cycles to be used by MUDPACK
                    * See cud3.d for more details */
  
    /* Input/Output */
  float *phi       /* Input: initial guess, if iguessflag=1.  Should be 
                    *   initialized to zeros otherwise.
                    * Output: solution of PDE.  In C, phi[i][j][l][c]
                    * In FORTRAN, phi(c+1,l+1,j+1,i+1) */
);

/* End FORTRAN declarations */

/******************************************************************/
/***                     fwdsolver.c                            ***/
/******************************************************************/

int add_detector_noise(
  phys_param *physparam, 
  dtype alpha_fixed, 
  mtype **meas, 
  mtype *snr);

int calc_phi(
     /*  Input */
  src_param *sources, /* Info about source locations and frequencies */
  det_param *dets,    /* Info about detector positions */
  mtype ****x,        /* mua and mus array: x[u,i,j,l] */
  phys_param *phys_param, /* Info about physical dimensions of problem */
    /* Output */
  mtype *****phi,     /* Calculated phi for each source: phi[k,i,j,l,c]*/
  mtype **fx         /* Calculated phi at measurement positions: fx[s,c]*/
 );

int calc_green(
     /*  Input */
  src_param *sources, /* Info about source locations and frequencies */
  det_param *dets,    /* Info about detector positions */
  mtype ****x,        /* mua and mus array: x[u,i,j,l] */
  phys_param *phys_param, /* Info about physical dimensions of problem */
    /* Output */
  mtype *****green    /* Calculated green for each source: green[k,i,j,l,c]*/
 );
 
int calc_frechet_col(
  /* Input */
  int u, int i, int j, int l,
  mtype *****phi,
  mtype *****green,
  mtype ****x,
  src_param *sources,
  /* SINGULAR */
  det_param *dets,
  phys_param *phys_param,
    /* Output */
  mtype **At          /* At[s,c] */
);

int calc_frechet_row(
  /* Input */
  int s,
  mtype *****phi,
  mtype *****green,
  mtype ****x,
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam,
  /* Output */
  mtype *****At          /* At[u,i,j,l,c] */
);  


int fwdsolver_3d(
  /* Input */
  phys_param *phys_param, /* Info about physical dimensions of problem */
  src_param *sources, /* Info about source locations and frequencies */
  int k,              /* Index describing which source to use in solution */
  mtype ****x,        /* mua and mus array: x[u,i,j,l] */
  int iguessflag,     /* =1 if initial guess is to be provided, =0 otherwise*/
  int ncycles,        /* Number of multigrid cycles to be used by MUDPACK */
  mtype ****phi       /* Input: initial guess, if iguessflag=1.  Should be
                       *   initialized to zeros otherwise.
                       * Output: solution of PDE.  In C, phi[i][j][l][c]
                       * In FORTRAN, phi(c+1,l+1,j+1,i+1) */
);  




/******************************************************************/
/***                        icd.c                               ***/
/******************************************************************/


prior_param *alloc_prior_param(
  double (*rho)(double, double, double, double), /* potential fn. rho(xi,xj,sigma,p) */
  dtype sigma, 
  dtype p, 
  int Nneighbor, 
  dtype *b);            /* coefficient for neighborhood relation */ 


void free_prior_param(prior_param *priorparam);


/* Calculate RMS error from yerror vector  */ 
double calc_yrmse(
  mtype ***yerror,
  phys_param *physparam);


double calc_rmse_with_lambda(
  mtype **yerror,
  mtype *lambda,
  phys_param *physparam);


/* SUBROUTINE-MG */
int calc_yerror(
  mtype **yerror,
  mtype **y,
  mtype **fx,
  phys_param *physparam,
  src_param *srcparam,
  det_param *detparam 
);


/* SUBROUTINE-MG */
/* Calculate alpha */
double calc_alpha(
  mtype **y,             /* y[s][c]            */
  mtype **fx,            /* fx[s][c]           */ 
  phys_param *physparam,
  src_param *srcparam,
  det_param *detparam);


/* SUBROUTINE-MG */
void calc_lambda_with_alpha(
  mtype **y,
  double alpha,    
  phys_param *physparam,
  mtype *lambda);   /* output */


/* Calculate lambda matrix */
void calc_lambda(
  mtype **y,             /* y[s][c]            */
  mtype **fx,            /* fx[s][c]           */ 
  phys_param *physparam,
  src_param *srcparam,
  det_param *detparam,
  mtype *lambda,    /* lambda[s] : output */
  mtype *alpha1);   /* output */ 


void ICD_params(
  mtype **At,          /* At[s,c]        */
  mtype **yerror,      /* yerror[s,c]    */
  mtype *lambda,       /* lambda[s]      */
  phys_param *physparam,
  src_param *srcparam,
  det_param *detparam,
  double *theta1,       /* output           */
  double *theta2);      /* output           */ 
/* Compute theta1 and theta2 for one-pixel ICD update                     */
/*  1) theta1 = -2 * Re{[col_{u,i,j,l}(At)]^H * rambda * error}           */
/*  2) theta2 = 2 * [col_{u,i,j,l}(At)]^H * rambda * [col_{u,i,j,l}(At)]  */	 
 

/* return the derivative of object funtion at x           */
double dev_obj_fn(
  mtype x,                       /* point being evaluated */ 
  mtype x_prev,                  /* value of last iteration */
  prior_param *priorparam,
  double theta1, 
  double theta2, 
  mtype *neighbor
);


mtype obj_fn_prior_one(
  phys_param *physparam,
  prior_param *priorparam,
  mtype ****x,
  int u,
  config_param *config
);


mtype obj_fn_prior(
  phys_param *physparam,
  prior_param *prior_D,
  prior_param *prior_mua,
  mtype ****x,
  config_param *config
);


mtype obj_fn(
  phys_param *physparam,
  prior_param *prior_D,
  prior_param *prior_mua,
  mtype ****x,
/* LINE-MG */
  mtype alpha,
/* LINE-MG */
  config_param *config
) ;


/* find root of (derivative of object fn)=0 with a half-interval search           */
/* Solves equation (*f)(x,constants) = 0 on x in [a,b].                           */
/* In ODT, (*f)() will point dev_obj_fn().                                        */        
/* Requires that (*f)(a) and (*f)(b) have opposite signs.                         */
/* Returns code=0  if signs are opposite.                                         */
/* Returns code=1  if signs are both positive.                                    */
/* Returns code=-1 if signs are both negative.                                    */
double  root_find(
  double (*fp)(mtype, mtype, prior_param *, double, double, mtype *),
  double a,                /* minimum value of solution */
  double b,                /* maximum value of solution */
  double err,              /* accuarcy of solution */
  int *code,               /* error code */
  prior_param *priorparam, /* From this, the parameters are for (*f)() */
  mtype x_prev,            /* value of previous iteration */
  double theta1, 
  double theta2, 
  mtype *neighbor
);        /* in 3D, neighbor[26] raster-ordered from [-1,-1,-1] to [1,1,1] */


/* store neighborhood pixel of x[u,i,j,l] into neighbor[] */
int get_neighbor(
  int u, int i, int j, int l,  /* center of the neighbor to be obtained */
  prior_param *priorparam,
  mtype ****x,                 /* x[u,i,j,l]   */
  mtype *neighbor,
  phys_param *physparam,
/* LINE-MG */
  config_param *config
);


 
int check_for_src_det_box(
  int i,
  int j,
  int l,
  phys_param *physparam,
  src_param *srcparam,
  det_param *detparam
);   


int check_for_src_det_sphere(
  int i,
  int j,
  int l,
  phys_param *physparam,
  src_param *srcparam,
  det_param *detparam,
  double ddfactor
);
    

int update_border(
  mtype ****x,
  phys_param *physparam,
  config_param *config,
  mtype *mean0,
  mtype *mean1
);    


/* return new value of x[u,i,j,l] obtained by one-pixel ICD  */
double ICD_pixel_update(
  int u, int i, int j, int l,  /* position of pixel being updated */
  mtype **At,                 /* At[c,s] for given u,i,j,l  */
  mtype ****x,                 /* x[u,i,j,l]   */
  mtype **yerror,             /* yerror[c,s]  */
  mtype *lambda,              /* lambda[s]   */
  prior_param *priorparam,
  phys_param *physparam,
  src_param *srcparam,
  det_param *detparam,
/* BEGIN-MG */
  double theta1,
  double theta2,
  config_param *config
/* END-MG */
);


/* Update pixels performing one-cycle ICD iteration 
 * to find x^ = argmin_x { ||yerror-Ax||_rambda ^2 + x^t B x }.
 * One pixel update is performed by calling ICD_pixel_update().  
 * yerror is also updated. */
void ICD_update(
  mtype ****x,          /* initial value x[u][i][j][l] and output */
  mtype **yerror,      /* initial error and output               */   
  mtype *****phi,         /* phi[k][i][j][l][c]                     */ 
  mtype *****green,       /* green[m][i][j][l][c]                   */
  mtype **y,
  mtype **fx,
  mtype *lambda,        
  prior_param *priorparam_D, 
  prior_param *priorparam_mua, 
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam,
  config_param *config,
/* BEGIN-MG */
  mtype ****residual
/* END-MG */
);

 
          
/* Reverse solver using single-grid ICD algorithm.
 * This will be used in multigrid reverse solver subroutine rvssolver_mg().
 * Output : x (that is, mu_a & mu_s) and yerror */
void rvssolver_sg(
  mtype ****x,                 /* initial value of mu_a & mu_s and output */
  mtype **y,                   /* observed phi, that is, desired value of f(x^) */
  phys_param *physparam,       /* physics parameters */ 
  src_param  *srcparam,        /* src_param array */ 
  det_param  *detparam,        /* detpos array    */ 
  prior_param *priorparam_D,        
  prior_param *priorparam_mua,        
  mtype **yerror,
  config_param *config
);            /* output : observ - f(x^)  */


/* Reverse solver using multigrid will be considered in the future.
   This calls rvssolver_sg() */
void rvssolver_mg();


/******************************************************************/
/***                     icdsd.c                                ***/
/******************************************************************/


/* Calculate the derivatives of source weights w.r.t. mua and D.
   Used for updating source weights after each one pixel update.  */   
int calc_dsdx(
/* INPUT */
  int k,
  mtype **y,
  mtype **fx,
  mtype *lambda,
  mtype **At,                  /* At[s][c]  */
  phys_param *physparam,
  src_param *srcparam,
  det_param *detparam,
  config_param *config,
/* OUTPUT */
  mtype **dsdx                 /* dsdx[k][c] */   
);       


/* Calculate the derivatives of detector weights w.r.t. mua and D.
   Used for updating detector weights after each one pixel update.  */
int calc_dddx(
/* INPUT */
  int m,
  mtype **y,
  mtype **fx,
  mtype *lambda,
  mtype **At,                  /* At[s][c]  */
  phys_param *physparam,
  src_param *srcparam,
  det_param *detparam,
  config_param *config,
/* OUTPUT */
  mtype **dddx                 /* dddx[k][c] */
);


/* Update pixels performing one-cycle ICD iteration
   where the ds/dx and dd/dx are considered to calculate the Frechet derivatives dCost/dx.
   This routine does NOT perform the error correction for s-d calibration.
   (See ICD_update_sd2() . ) Actually this routine does not work well, 
   if a proper initialization for the s-d weights are not performed in rvs_solver_sd().
   x^ is found s.t.  x^ = argmin_x { ||yerror-Ax||_lambda ^2 + x^t B x }.
   One pixel update is performed by calling ICD_pixel_update().  */
void ICD_update_sd(
  mtype ****x,            /* initial value x[u][i][j][l] and output */
  mtype **yerror,         /* initial error and output               */
  mtype *****phi,         /* phi[k][i][j][l][c]                     */
  mtype *****green,       /* green[m][i][j][l][c]                   */
  mtype **y,
  mtype **fx,
  mtype *lambda,
  prior_param *priorparam_D,
  prior_param *priorparam_mua,
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam,
  config_param *config
);  


/* Update pixels performing one-cycle ICD iteration
   where the ds/dx and dd/dx are considered to calculate the Frechet derivatives dCost/dx.
   This routine perform the error correction for s-d calibration. (See ICD_update_sd(). )
   x^ is found s.t.  x^ = argmin_x { ||yerror-Ax||_lambda ^2 + x^t B x }.
   One pixel update is performed by calling ICD_pixel_update().  */
void ICD_update_sd2(
  mtype ****x,          /* initial value x[u][i][j][l] and output */
  mtype **yerror,      /* initial error and output               */
  mtype *****phi,         /* phi[k][i][j][l][c]                     */
  mtype *****green,       /* green[m][i][j][l][c]                   */
  mtype **y,
  mtype **fx,
  mtype *lambda,
  prior_param *priorparam_D,
  prior_param *priorparam_mua,
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam,
  config_param *config
);     

/******************************************************************/
/***                     homogeneous.c                          ***/
/******************************************************************/


/* Calculate the derivatives of global weights w.r.t. mua and D.
 * Used for calculate the gradient direction in homogeneous pixel update
 * with consideration of the derivatives of global weights w.r.t. mua and D. */
int calc_dwdx(
/* INPUT */
  mtype **y,
  mtype **fx,
  mtype *lambda,
  mtype ***SumAt,           /* SumAt[u][s][c] */
  phys_param *physparam,
  src_param *srcparam,
  det_param *detparam,
  config_param *config,
/* OUTPUT */
  double dwdx[2][2]);       /* dwdx[u][c] */   


/* Find the direction opposite to the gradient (dCost/dmua, dCost/dD),
   considering the effect of pixel update on the weights.
   This routine is originally designed to be used in Homo_update_Search2().   */
int calc_direction(
  mtype ****x,
  mtype **y,
  mtype **fx,
  mtype *****phi,
  mtype *****green,
  mtype *lambda,
  phys_param *physparam,
  src_param *srcparam,
  det_param *detparam,
  config_param *config,
  double dCdx[2]);          


/* Update pixels performing one-cycle Newton's method
   to find homogeneous x^ = argmin_x { ||yerror-Ax||_lambda ^2 + x^t B x }.
   Only one pixels  are assumed for each of mua and D. */
void Homo_update_Newton(
  mtype ****x,            /* initial value x[u][i][j][l] and output */
  mtype **yerror,         /* initial error and output               */
  mtype *****phi,         /* phi[k][i][j][l][c]                     */
  mtype *****green,       /* green[m][i][j][l][c]                   */
  mtype *lambda,
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam,
  config_param *config);


/* Update pixels performing one-cycle search method
   to find homogeneous x^ = argmin_x { ||yerror-Ax||_lambda ^2 + x^t B x }.
   Only one pixels  are assumed for each of mua and D. i
   In the directional search, the effect of pixel update on the weights
   are NOT considered, and search for mua and D is performed iteratively.
   (Compare this routine with Homo_update_Search2(). )  */
void Homo_update_Search(
  mtype ****x,
  mtype **y,
  mtype *lambda,
  mtype *****phi,         /* phi[k][i][j][l][c]                     */
  mtype *****green,       /* green[m][i][j][l][c]                   */
  mtype **yerror,
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam,
  config_param *config);         


/* Update pixels performing one-cycle search method
   to find homogeneous x^ = argmin_x { ||yerror-Ax||_lambda ^2 + x^t B x }.
   Only one pixels  are assumed for each of mua and D. i
   In the directional search, the effect of pixel update on the weights
   are considered, and search for mua and D is performed
   in the direction opposite to the gradient (dCost/dmua, dCost/dD).
   (Compare this routine with Homo_update_Search(). )  */
void Homo_update_Search2(
  mtype ****x,
  mtype **y,
  mtype **fx,
  mtype *lambda,
  mtype *****phi,         /* phi[k][i][j][l][c]                     */
  mtype *****green,       /* green[m][i][j][l][c]                   */
  mtype **yerror,
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam,
  config_param *config
);  



/******************************************************************/
/***                     calibrate.c                            ***/
/******************************************************************/

int findk(
  phys_param *physparam,
  int s);

int findm(
  phys_param *physparam,
  int s);

int one_src_calibrate(
  int k,
  mtype **y,
  mtype **fx,
  mtype *lambda,
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam);

int one_det_calibrate(
  int m,
  mtype **y,
  mtype **fx,
  mtype *lambda,
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam);

int src_det_calibrate(
  mtype **y,
  mtype **fx,
  mtype *lambda,
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam);

int global_weight_calibrate(
  mtype ****x,
  mtype **y,
  mtype **fx,
  mtype *lambda,
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam); 





/******************************************************************/
/***                     mgutil.c                               ***/
/******************************************************************/


int decimate1Dkernel(
  mtype **kernel,
  int   Nifine);


int decimate1D(
  mtype *xfine,     
  int    Nifine,
  mtype *xcoarse);


int interpolatetranspose1Dkernel(
  mtype **kernel,
  int   Nifine);


int interpolatetranspose1D(
  mtype *xfine,     
  int    Nifine,
  mtype *xcoarse);


int interpolate1Dkernel(
  mtype **kernel,
  int   Nicoarse);


int interpolate1D(
  mtype *xcoarse,   /* x^h       : input, x[i] */
  int   Nicoarse,
  mtype *xfine);     /* x^{(h+1)} : output */


/* decimation for x : x-y-z directions sequentially */
int decimatex(
  mtype ****xfine,     /* x^{(h+1)} : input, x[u][i][j][l] */
  int   Nifine,
  int   Njfine,
  int   Nlfine,
  mtype ****xcoarse);   /* x^h       : output  */


int interpolatetransposex(
  mtype ****xfine,     /* x^{(h+1)} : input, x[u][i][j][l] */
  int   Nifine,
  int   Njfine,
  int   Nlfine,
  mtype ****xcoarse);   /* x^h       : output  */


/* interpolation for x : z-y-x directions sequentially */
int interpolatex(
  mtype ****xcoarse,   /* x^h       : input, x[u][i][j][l] */
  int   Nicoarse,
  int   Njcoarse,
  int   Nlcoarse,
  mtype ****xfine);    /* x^{(h+1)} : output */
 

int decimator(
  mtype ****xfine,   /* x^h       : input, x[u][i][j][l] */
  int   Nifine,
  int   Njfine,
  int   Nlfine,
  mtype ****xcoarse,     /* x^{(h+1)} : output */
  config_param *config_fine);


int interpolatortranspose(
  mtype ****xfine,   /* x^h       : input, x[u][i][j][l] */
  int   Nifine,
  int   Njfine,
  int   Nlfine,
  mtype ****xcoarse,     /* x^{(h+1)} : output */
  config_param *config_fine);


int interpolator(
  mtype ****xcoarse,   /* x^h       : input, x[u][i][j][l] */
  int   Nicoarse,
  int   Njcoarse,
  int   Nlcoarse,
  mtype ****xfine,     /* x^{(h+1)} : output */
  config_param *config_coarse);

 

/******************************************************************/
/***                     multigrid.c                            ***/
/******************************************************************/


/*******
Consideration for possible Future Code Extension
  0. Allow both Inverse-Forward Multigrid and Inverse-only Multigrid.
  1. Extension to the multigrid for source and detector weights.
  2. Make it possible to choose general interpolation/decimation operators.
  3. Coarse scale cost function should be able to have different parameters
     according to the scale.
***********/


/* Coarse Grid Correction :
 *       x = max{0, x+interpolate(x(h+1)-x_dec)}
 */
int coarse_correction(
  int h,
  mtype ****x,       /* input and output */
  int Ni,            /* Ni for x */
  int Nj,            /* Nj for x */
  int Nl,            /* Nl for x */
  mtype ****xhplus1,
  config_param *config
);


int set_params_fine(
  phys_param *physparam,
  prior_param *prior_mua,
  prior_param *prior_D,
  config_param *config 
); 


int set_params_coarse(
  phys_param *physparam,
  prior_param *prior_mua,
  prior_param *prior_D,
  config_param *config 
);  


mtype calc_gradc_prior_pixel(
  int u, int i, int j, int l,  
  mtype ****x,
  phys_param *physparam,       
  prior_param *priorparam,     
  config_param *config
);



int calc_gradc_prior(
  mtype ****gradc_prior,
  mtype ****x,
  phys_param *physparam,
  prior_param *prior_mua,
  prior_param *prior_D,
  config_param *config
);



int calc_yerror_coarse(
  mtype ****x,
  mtype ******A,
  phys_param *physparam,
  mtype **yerror,
  mtype **yerror_coarse,
  config_param *config
);



int multigrid_main(
  mtype ****x,
  mtype **y,                   /* observed phi, that is, desired value of f(x^) */
  phys_param *physparam,       /* physics parameters */
  src_param  *srcparam,        /* src_param array */
  det_param  *detparam,        /* det_param array */
  prior_param *prior_mua,
  prior_param *prior_D,  
  mtype **yerror, 
  config_param *config
);





