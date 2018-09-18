#include <stdio.h>
#include <math.h>
#include "defs.h"


mtype obj_fn2( /* with alpha fixed */
  phys_param *physparam,
  prior_param *prior_D,
  prior_param *prior_mua,
  mtype ****x,
  mtype alpha,
/* LINE-MG */
  mtype alpha_fixed,
  config_param *config
)
{
  int u,i,j,l,n,S;
  mtype x_curr;
  mtype *neighbor;
  mtype prior[2];
  prior_param *priorparam;
  

  for(u=0; u<2; u++){
    if(u==0){
      priorparam=prior_mua;
    }
    else{
      priorparam=prior_D;
    }

    neighbor = (mtype *) malloc(sizeof(mtype)*priorparam->Nneighbor);

    prior[u]=0.0;


/* MILSTEIN - changed [1,Ni-1] to [0,Ni] , etc.*/
    for(i=0; i<physparam->Ni; i++)
    for(j=0; j<physparam->Nj; j++)
    for(l=0; l<physparam->Nl; l++){     
      x_curr=x[u][i][j][l];
/* MODIFY-MG - add config arg */
      get_neighbor(u,i,j,l, priorparam, x, neighbor,
                   physparam, config); /* MILSTEIN - added last arg */ 
      for (n=0; n<priorparam->Nneighbor; n++)
        prior[u] += priorparam->b[n]
               * pow( fabs(x_curr-neighbor[n]), priorparam->p ) ;
    }
    prior[u]= prior[u]/pow(priorparam->sigma,priorparam->p)/priorparam->p;
    free(neighbor);
  }

  S=physparam->S;

  return(S*alpha/alpha_fixed+.5*prior[0]+.5*prior[1]);
}


mtype obj_fn_prior_one(  
  phys_param *physparam,
  prior_param *priorparam,
  mtype ****x,
  int u,
  config_param *config
)
{
  int i,j,l,n;
  mtype x_curr;
  mtype *neighbor;
  mtype prior;

  neighbor = (mtype *) malloc(sizeof(mtype)*priorparam->Nneighbor);

  prior=0.0;

  for(i=0; i<physparam->Ni; i++)
  for(j=0; j<physparam->Nj; j++)
  for(l=0; l<physparam->Nl; l++){     
    x_curr=x[u][i][j][l];
    get_neighbor(u,i,j,l, priorparam, x, neighbor, physparam, config); 
    for (n=0; n<priorparam->Nneighbor; n++)
      prior += priorparam->b[n]
             * pow( fabs(x_curr-neighbor[n]), priorparam->p ) ;
  }

  prior= 0.5 * prior/pow(priorparam->sigma,priorparam->p)/priorparam->p;
  free(neighbor);

  return(prior);
}


mtype obj_fn_prior(  
  phys_param *physparam,
  prior_param *prior_D,
  prior_param *prior_mua,
  mtype ****x,
  config_param *config
)
{
  return(obj_fn_prior_one(physparam, prior_mua, x, 0, config)
        +obj_fn_prior_one(physparam, prior_D, x, 1, config)); 
}


mtype obj_fn(   /* when alpha is varied */
  phys_param *physparam,
  prior_param *prior_D,
  prior_param *prior_mua,
  mtype ****x,
  /* LINE-MG */
  mtype alpha,
  /* LINE-MG */
  config_param *config
)
{
  int S=physparam->S;

  return(S+S*log(alpha)+ obj_fn_prior(physparam, prior_D, prior_mua, x, config));
}



prior_param *alloc_prior_param(
  double (*rho)(double,double,double,double), /* potential fn. rho(xi,xj,sigma,p) */
  dtype sigma, dtype p, 
  int Nneighbor, dtype *b)
{
  int i;
  prior_param *priorparam;
	
  priorparam = (prior_param *) malloc(sizeof(prior_param));
  priorparam->rho   = rho;
  priorparam->sigma = sigma;
  priorparam->p     = p;  
  priorparam->Nneighbor = Nneighbor;

  priorparam->b = (dtype *) malloc(sizeof(dtype)*Nneighbor);  
  for (i=0; i<Nneighbor; i++)
    priorparam->b[i] = b[i];  

  return(priorparam);
}


void free_prior_param(prior_param *priorparam)
{
  free(priorparam->b);
  free(priorparam); 
}


double calc_rmse(
  mtype **yerror,
  phys_param *physparam)
{
  int s;
  double error=0.0;

  for(s=0; s<physparam->S; s++)
    error += AbsSquare(yerror[s][0], yerror[s][1]);

  return(sqrt(error/(physparam->S)));
}


double calc_rmse_with_lambda(
  mtype **yerror,
  mtype *lambda,
  phys_param *physparam)
{
  int s;
  double error=0.0;

  for(s=0; s<physparam->S; s++)
    error += lambda[s] * AbsSquare(yerror[s][0], yerror[s][1]);

  return(sqrt(error/(physparam->S)));
}


/* SUBROUTINE-MG */
int calc_yerror(
  mtype **yerror,
  mtype **y,
  mtype **fx,
  phys_param *physparam,
  src_param *srcparam, 
  det_param *detparam 
)
{
  int s, k, m;
  double temp1r, temp1i, temp2r, temp2i; 

#ifndef SDVERSION  
  for (s=0; s<physparam->S; s++) {
    yerror[s][0] = y[s][0] - fx[s][0];
    yerror[s][1] = y[s][1] - fx[s][1];
  }
#else
  for (s=0; s<physparam->S; s++) {
    k = findk(physparam, s);
    m = findm(physparam, s);
    temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp2r = cplxmultr(temp1r, temp1i, physparam->wgtr, physparam->wgti);
    temp2i = cplxmulti(temp1r, temp1i, physparam->wgtr, physparam->wgti);
    yerror[s][0] = y[s][0] - cplxmultr(fx[s][0],fx[s][1],temp2r,temp2i);
    yerror[s][1] = y[s][1] - cplxmulti(fx[s][0],fx[s][1],temp2r,temp2i);
  }
#endif

  return 0;
}


/* NEW-MG */
double calc_alpha(
  mtype **y,
  mtype **fx, 
  phys_param *physparam,
  src_param *srcparam,
  det_param *detparam)
{
  int s,k,m;
  double alpha;
  double temp1r, temp1i;
  double temp2r, temp2i;  
 
  alpha = 0.0;
  
#ifndef SDVERSION
  for(s=0; s<physparam->S; s++)
  {
    alpha += AbsSquare(y[s][0] - fx[s][0], y[s][1] - fx[s][1])
            / sqrt(AbsSquare(y[s][0], y[s][1]));
  }
#else
  for(s=0; s<physparam->S; s++)
  {
    k = findk(physparam, s);
    m = findm(physparam, s);
    temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp2r=cplxmultr(temp1r, temp1i, physparam->wgtr, physparam->wgti);
    temp2i=cplxmulti(temp1r, temp1i, physparam->wgtr, physparam->wgti);

    alpha += AbsSquare(y[s][0] - cplxmultr(fx[s][0],fx[s][1], temp2r, temp2i),
                       y[s][1] - cplxmulti(fx[s][0],fx[s][1], temp2r, temp2i))
            / sqrt(AbsSquare(y[s][0], y[s][1]));
  }
#endif
  
  alpha /= (physparam->S);

  return(alpha);  
}      


/* NEW-MG */
void calc_lambda_with_alpha(
  mtype **y,
  double alpha,    
  phys_param *physparam,
  mtype *lambda)  /* output */
{
  int s;

  for(s=0; s<physparam->S; s++) 
    lambda[s] = 1.0 / (alpha * sqrt(AbsSquare(y[s][0], y[s][1]))); 
}      


/* MODIFIED-MG */
void calc_lambda(
  mtype **y,
  mtype **fx, 
  phys_param *physparam,
  src_param *srcparam,
  det_param *detparam,
  mtype *lambda,  /* output */
  mtype *alpha1)    /* output */ 
{
  int s;
  double alpha;
 
  alpha = calc_alpha(y, fx, physparam, srcparam, detparam);

  for(s=0; s<physparam->S; s++) 
    lambda[s] = 1.0 / (alpha * sqrt(AbsSquare(y[s][0], y[s][1]))); 
  
  *alpha1=alpha;
}      


/* compute theta1 and theta2 for one-pixel ICD update */
/*  1) theta1 = -2 * Re{At^H * lambda * yerror}    */
/*  2) theta2 = 2 * At^H * lambda * At            */	 
void ICD_params(
  mtype **At,           /* At[s,c]        */
  mtype **yerror,      /* yerror[s,c]    */
  mtype *lambda,       /* lambda[s]      */
  phys_param *physparam,
  src_param *srcparam,
  det_param *detparam,
  double *theta1,       /* output           */
  double *theta2)       /* output           */ 
{
  int s,k,m;
  double temp1r, temp1i, temp2r, temp2i;
  /* Milstein */
  double temp3r, temp3i; 
 
  *theta1 = 0.0;
  *theta2 = 0.0;

#ifndef SDVERSION
  for(s=0; s<physparam->S; s++)
  {
     *theta1 += (At[s][0] * yerror[s][0] + At[s][1] * yerror[s][1]) * lambda[s];
     *theta2 += AbsSquare(At[s][0], At[s][1]) * lambda[s];
  }
#else
  for(s=0; s<physparam->S; s++)
  {
      k = findk(physparam, s);
      m = findm(physparam, s);
      temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                         detparam[m].calir, detparam[m].calii);
      temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                         detparam[m].calir, detparam[m].calii);
      temp2r = cplxmultr(At[s][0], At[s][1], temp1r, temp1i);
      temp2i = cplxmulti(At[s][0], At[s][1], temp1r, temp1i);

   /* Milstein - Begin */
      temp3r = cplxmultr(temp2r, temp2i, physparam->wgtr, physparam->wgti);
      temp3i = cplxmulti(temp2r, temp2i, physparam->wgtr, physparam->wgti);
 
     *theta1 += (temp3r * yerror[s][0] + temp3i * yerror[s][1]) * lambda[s];
     *theta2 += AbsSquare(temp3r, temp3i) * lambda[s];
   /* Milstein - End */  
  }
#endif
  
  *theta1 *= (-2.0);
  *theta2 *= (2.0);
}
 

int get_neighbor(
  int u, int i, int j, int l,  /* position of pixel being updated */
  prior_param *priorparam,
  mtype ****x,                 /* x[][u,i,j,l]   */
  mtype *neighbor,
  /* MILSTEIN - added extra arg to allow bounds checking */
  phys_param *physparam,
  /* LINE-MG */
  config_param *config  
)
{
  int p,q,r,ss=0;

/* MILSTEIN  begin */
  int nnx, nny, nnz;
 
  nnx=physparam->Ni;
  nny=physparam->Nj;
  nnz=physparam->Nl;
/* MILSTEIN end */   

  if (priorparam->Nneighbor==8) {
    for (p=-1; p<2; p++)
    for (q=-1; q<2; q++)
      if (!(p==0 && q==0)) 
        neighbor[ss++] = x[u][i+p][j+q][l]; 
  }
  else if (priorparam->Nneighbor==26) {
    for (p=-1; p<2; p++)
    for (q=-1; q<2; q++)
    for (r=-1; r<2; r++) {
      if (!(p==0 && q==0 && r==0)) {
/* MILSTEIN - bounds checking */
/* BEGIN-DELETE-MG  *
        if((i+p)>=0  && (j+q)>=0  && (l+r)>=0  &&
           (i+p)<nnx  && (j+q)<nny  && (l+r)<nnz){
* END-DELETE-MG */
/* BEGIN-MG */
        if((i+p)>=config->borderi  && (i+p)<nnx-config->borderi && 
           (j+q)>=config->borderj  && (j+q)<nny-config->borderj && 
           (l+r)>=config->borderl  && (l+r)<nnz-config->borderl) {
/* END-MG */
           neighbor[ss++] = x[u][i+p][j+q][l+r];
        }
        else{
           neighbor[ss++] = x[u][i][j][l];
        }
      } /* end if */
    } /* end for */
  } /* end elseif */
 
  else {
    fprintf(stderr, "Invalid number of neighborhood pixels.\n");
    exit(1);
  }                      
  return 0; 
}


double dev_obj_fn(
  mtype x,                       /* point being evaluated */ 
  mtype x_prev,                  /* value of last iteration */
  prior_param *priorparam,
  double theta1, 
  double theta2, 
  mtype *neighbor
)
{
  double prior = 0.0;
  int i; 

  /* calculate prior-model-related part of derivative of object function */ 
  for (i=0; i<priorparam->Nneighbor; i++) 
    prior += priorparam->b[i] 
             * pow( fabs(x-neighbor[i]), priorparam->p-1 ) * SG(x,neighbor[i]); 

  return(theta1+theta2*(x-x_prev)+prior/pow(priorparam->sigma,priorparam->p));
}


/* find root of (derivative of object fn)=0 with a half-interval search */
double  root_find(
  double (*fp)(mtype, mtype, prior_param *, double, double, mtype *), 
  double a,                /* minimum value of solution */
  double b,                /* maximum value of solution */
  double err,              /* accuarcy of solution */
  int *code,               /* error code */
  prior_param *priorparam, /* From this, the parameters are for (*f)() */
  mtype x_prev,           /* value of last iteration */
  double theta1, 
  double theta2, 
  mtype *neighbor         /* in 3D, neighbor[26] raster-ordered from [-1,-1,-1] to [1,1,1] */
)
/* Solves equation (*f)(x,constants) = 0 on x in [a,b]. Uses half interval method.*/
/* In ODT, (*f)() will point dev_obj_fn().                                        */        
/* Requires that (*f)(a) and (*f)(b) have opposite signs.                         */
/* Returns code=0  if signs are opposite.                                         */
/* Returns code=1  if signs are both positive.                                    */
/* Returns code=-1 if signs are both positive and code=-1 for both negative.      */
{
  int     signa,signb,signc;
  double  fa,fb,fc,c,  signaling_nan();
  double  dist;

  fa = dev_obj_fn(a, x_prev, priorparam, theta1, theta2, neighbor); 
  signa = fa>0;

  fb = dev_obj_fn(b, x_prev, priorparam, theta1, theta2, neighbor); 
  signb = fb>0;

  /* check starting conditions */
  if( signa==signb ) {
    if(signa==1) *code =  1;
    else         *code = -1;
    return(0.0);
  }
  else *code = 0;


  /* half interval search */
  if( (dist=b-a)<0 )
    dist = -dist;

  while(dist>err) {
    c = (b+a)/2;
    fc = dev_obj_fn(c, x_prev, priorparam, theta1, theta2, neighbor); 
    signc = fc>0;

    if(signa == signc)
    {
      a = c;
      fa = fc;
    }
    else
    {
      b = c;
      fb = fc;
    }

    if( (dist=b-a)<0 )
      dist = -dist;
  }

  /* linear interpolation */
  if( (fb-fa)==0 )
    return(a);
  else {
    c = (a*fb - b*fa)/(fb-fa);
    return(c);
  }
}


double ICD_pixel_update(
  int u, int i, int j, int l,  /* position of pixel being updated */
  mtype **At,                 /* At[u,i,j,l][c,s] for given u,i,j,l  */
  mtype ****x,                 /* x[][u,i,j,l]   */
  mtype **yerror,             /* yerror[s,c]  */
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
)
{
/* DELETE-LINE-MG *
  double theta1, theta2;
*/
  double a, b, xhat;
  mtype  *neighbor; 
  int    n, errcode; 

  neighbor = (mtype *) malloc(sizeof(mtype)*priorparam->Nneighbor);

/* DELETE-LINE-MG *
  ICD_params(At, yerror, lambda, physparam, srcparam, detparam, &theta1, &theta2);
*/

  /* MILSTEIN - added extra arg to allow bounds checking */
  /* MODIFY-MG - add config arg */ 
  get_neighbor(u,i,j,l, priorparam, x, neighbor,
                        physparam, config);             

  /* set half interval search range [a,b] for find_root().  */
  if(theta2==0.0) {
    fprintf(stderr, "Divided by theta2=0 in root_df().\n");
    return(x[u][i][j][l]);
  }

  a = x[u][i][j][l] - theta1/theta2;
  b = x[u][i][j][l] - theta1/theta2;

  for(n=0;n<priorparam->Nneighbor;n++)
  {
    if(a > neighbor[n])
      a = neighbor[n];
    else if(b < neighbor[n])
      b = neighbor[n];
  }

  xhat = root_find(dev_obj_fn, a, b, 0.00001, &errcode,  
                   priorparam, x[u][i][j][l], theta1, theta2, neighbor); 

  /* Some error handling for errcode!=0 or negative xhat */
  if (errcode!=0) {
    xhat = x[u][i][j][l]; 
    fprintf(stderr, "1"); 
  }

  if (xhat <0.00001) {
    xhat = 0.00001;
    fprintf(stderr, "2"); 
  } 

  free(neighbor);

  return(xhat); 
}


int check_for_src_det_box(int i,
                  int j,
                  int l,
                  phys_param *physparam,
                  src_param *srcparam,
                  det_param *detparam){
 
  int nnx, nny, nnz, k, m, i_l, j_l, l_l, i_h, j_h, l_h;
  double x_s, x_d, y_s, y_d, z_s, z_d;
  dtype dx,dy,dz;
  float xmin, xmax, ymin, ymax,zmin, zmax;
 
 
  nnx=physparam->Ni;
  nny=physparam->Nj;
  nnz=physparam->Nl;
 
  xmin=(float)(physparam->xmin);
  xmax=(float)(physparam->xmax);
  ymin=(float)(physparam->ymin);
  ymax=(float)(physparam->ymax);
  zmin=(float)(physparam->zmin);
  zmax=(float)(physparam->zmax);
 
  dx=(xmax-xmin)/((dtype)(nnx-1.));
  dy=(ymax-ymin)/((dtype)(nny-1.));
  dz=(zmax-zmin)/((dtype)(nnz-1.));
 
  for(k=0; k<physparam->K; k++){
    x_s=srcparam[k].x;
    y_s=srcparam[k].y;
    z_s=srcparam[k].z;
 
    i_l=(int)floor((x_s-xmin)/dx);
    j_l=(int)floor((y_s-ymin)/dy);
    l_l=(int)floor((z_s-zmin)/dz);
    i_h=i_l+1;
    j_h=j_l+1;
    l_h=l_l+1;
 
    if( (i==i_l && j==j_l && l==l_l) ||
        (i==i_l && j==j_l && l==l_h) ||
        (i==i_l && j==j_h && l==l_l) ||
        (i==i_l && j==j_h && l==l_h) ||
        (i==i_h && j==j_l && l==l_l) ||
        (i==i_h && j==j_l && l==l_h) ||
        (i==i_h && j==j_h && l==l_l) ||
        (i==i_h && j==j_h && l==l_h) ){
 
      return 1;               
    }
  }
 
  for(m=0; m<physparam->M; m++){
    x_d=detparam[m].x;
    y_d=detparam[m].y;
    z_d=detparam[m].z;
 
    i_l=(int)floor((x_d-xmin)/dx);
    j_l=(int)floor((y_d-ymin)/dy);
    l_l=(int)floor((z_d-zmin)/dz);
    i_h=i_l+1;
    j_h=j_l+1;
    l_h=l_l+1;
 
    if( (i==i_l && j==j_l && l==l_l) ||
        (i==i_l && j==j_l && l==l_h) ||
        (i==i_l && j==j_h && l==l_l) ||
        (i==i_l && j==j_h && l==l_h) ||
        (i==i_h && j==j_l && l==l_l) ||
        (i==i_h && j==j_l && l==l_h) ||
        (i==i_h && j==j_h && l==l_l) ||
        (i==i_h && j==j_h && l==l_h) ){
 
      return 2;
    }
  }
  return 0;
}
 
 
 
int check_for_src_det_sphere(int i,
                  int j,
                  int l,
                  phys_param *physparam,
                  src_param *srcparam,
                  det_param *detparam,
                  double ddfactor)
{
  int nnx, nny, nnz, k, m;
  dtype x_s, x_d, y_s, y_d, z_s, z_d;
  dtype x_curr, y_curr, z_curr;
  dtype dx,dy,dz,  dd, dist;
  float xmin, xmax, ymin, ymax,zmin, zmax;
 
 
  nnx=physparam->Ni;
  nny=physparam->Nj;
  nnz=physparam->Nl;                          

  xmin=(float)(physparam->xmin);
  xmax=(float)(physparam->xmax);
  ymin=(float)(physparam->ymin);
  ymax=(float)(physparam->ymax);
  zmin=(float)(physparam->zmin);
  zmax=(float)(physparam->zmax);
 
  dx=(xmax-xmin)/((dtype)(nnx-1.));
  dy=(ymax-ymin)/((dtype)(nny-1.));
  dz=(zmax-zmin)/((dtype)(nnz-1.));
 
  dd=sqrt(dx*dx+dy*dy+dz*dz);
 
 
  for(k=0; k<physparam->K; k++){
    x_s=srcparam[k].x;
    y_s=srcparam[k].y;
    z_s=srcparam[k].z;
 
    x_curr=xmin+dx*(float)i;
    y_curr=ymin+dy*(float)j;
    z_curr=zmin+dz*(float)l;
 
    dist=sqrt( (x_s-x_curr)*(x_s-x_curr)+
                (y_s-y_curr)*(y_s-y_curr)+
                (z_s-z_curr)*(z_s-z_curr) );
    if(dist<(ddfactor*dd))
      return 1;
  }
 
  for(m=0; m<physparam->M; m++){
    x_d=detparam[m].x;
    y_d=detparam[m].y;
    z_d=detparam[m].z;
 
    x_curr=xmin+dx*(float)i;
    y_curr=ymin+dy*(float)j;
    z_curr=zmin+dz*(float)l;
 
    dist=sqrt( (x_d-x_curr)*(x_d-x_curr)+
                (y_d-y_curr)*(y_d-y_curr)+
                (z_d-z_curr)*(z_d-z_curr) );
    if(dist<(ddfactor*dd))
      return 2;
  }

  return 0;
}
 

int update_border(
  mtype ****x,
  phys_param *physparam,
  config_param *config,
  mtype *mean0,
  mtype *mean1)
{
  int u,i,j,l,Ni,Nj,Nl,borderi,borderj,borderl; 
  mtype mean[2];
  int npixel[2];
 
  Ni = physparam->Ni;    borderi = config->borderi; 
  Nj = physparam->Nj;    borderj = config->borderj; 
  Nl = physparam->Nl;    borderl = config->borderl; 

  for (u=0; u<2; u++) {
    mean[u]=0;
    npixel[u]=0;

    for (i=0; i<Ni; i++)
    for (j=0; j<Nj; j++)
    for (l=0; l<Nj; l++) {
/*      if ( !(i<borderi || i>=Ni-borderi || j<borderj || j>=Nj-borderj
             || l<borderl || l>=Nl-borderl) ) {
 */
        mean[u] += x[u][i][j][l];
        npixel[u]++;
/*      } */
    }

    mean[u] = mean[u] / npixel[u]; 
  }

  for (u=0; u<2; u++) 
  for (i=0; i<Ni; i++)
  for (j=0; j<Nj; j++)
  for (l=0; l<Nj; l++) {
    if ( i<borderi || i>=Ni-borderi || j<borderj || j>=Nj-borderj
         || l<borderl || l>=Nl-borderl) 
      x[u][i][j][l] = mean[u];
  }

  *mean0=mean[0];
  *mean1=mean[1];

  return 0;
}


void ICD_update(
  mtype ****x,          /* initial value x[u][i][j][l] and output */
  mtype **yerror,      /* initial error and output               */   
  mtype *****phi,         /* phi[k][i][j][l][c]                     */ 
  mtype *****green,       /* green[m][i][j][l][c]                   */
  /* BEGIN-NEWCALI */
  mtype **y,
  mtype **fx,
  /* END-NEWCALI */
  mtype *lambda,        
  prior_param *priorparam_D, 
  prior_param *priorparam_mua, 
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam,
  config_param *config,
/* LINE-MG */
  mtype ****residual  
)
{
  int u,i,j,l,ubegin,uend;
  int q,t,rand_index;
  int Ni,Nj,Nl,Nq;
  mtype **At, mean[2];
  double xhat;
  int k,m,s,c, *rand_update_mask=NULL;
  double temp1r, temp1i, temp2r, temp2i, temp3r, temp3i;    
  double theta1, theta2;  
/* LINE-MG */
  prior_param *priorparam;

  Ni=physparam->Ni;
  Nj=physparam->Nj;
  Nl=physparam->Nl;
  Nq=(Ni-2*config->borderi)*(Nj-2*config->borderj)*(Nl-2*config->borderl);
  
  At = multialloc(sizeof(mtype), 2, physparam->S, 2);

/* BEGIN-NEWCALI *
  fx = multialloc(sizeof(double), 2, physparam->S, 2);
 
  for (s=0; s<physparam->S; s++)
  for (c=0; c<2; c++) 
    fx[s][c] = y[s][c] - yerror[s][c];
* END-NEWCALI */
                
  rand_update_mask = (int *)malloc(Nq*sizeof(int));

  if (config->mua_flag && config->D_flag) {
    ubegin = 0;    uend = 1;
  } 
  else if (config->mua_flag && !config->D_flag) {
    ubegin = 0;    uend = 0;
  } 
  else if (!config->mua_flag && config->D_flag) {
    ubegin = 1;    uend = 1;
  }
  else {
    fprintf(stderr,"Error! Both mua_flag and D_flag are 0!!!\n");
    exit(1);
  }

  for (u=ubegin; u<uend+1; u++){     
    if (config->border_update_flag == 1)
      update_border(x, physparam, config, &mean[0], &mean[1]);

    for (q=0; q<Nq; q++){
      rand_update_mask[q]=0;
    }
    for (t=0; t<Nq; t++){
      srand(time(NULL));
      rand_index=rand()%(Nq-t);
      q=-1;
      while(rand_index>=0){
        q++;
        while(rand_update_mask[q]) q++;
        rand_index--;
      }
      rand_update_mask[q]=1;

      l = config->borderl + q%(Nl-2*config->borderl);
      j = config->borderj + (q/(Nl-2*config->borderl)) % (Nj-2*config->borderj);
      i = config->borderi + (q/((Nl-2*config->borderl) * (Nj-2*config->borderj)))
          % (Ni-2*config->borderi);

      /* MILSTEIN-begin */
      if (1)  /* (0==(check_for_src_det_sphere(i,j,l,physparam,srcparam,detparam, 1.8))) */  {
        calc_frechet_col(u, i, j, l, phi, green, x, srcparam, detparam, physparam, At);

/* DELETE-BEGIN-MG *
        if(u==MUA)
          xhat = ICD_pixel_update(u, i, j, l, At, x, yerror, lambda,
                                  priorparam_mua, physparam, srcparam, detparam);
        else
          xhat = ICD_pixel_update(u, i, j, l, At, x, yerror, lambda,
                                  priorparam_D, physparam, srcparam, detparam); 
* DELETE-END-MG */

/* BEGIN-MG */
        ICD_params(At, yerror, lambda, physparam, srcparam, detparam, &theta1, &theta2);

        if(u==MUA)
          priorparam = priorparam_mua; 
        else
          priorparam = priorparam_D; 

        xhat = ICD_pixel_update(u, i, j, l, At, x, yerror, lambda,
                                priorparam, physparam, srcparam, detparam, 
                                theta1-residual[u][i][j][l], theta2, config);
/* END-MG */
      }
      else{
/*
        if (config->border_update_flag == 1)
          xhat = mean[u];
        else 
*/ 
         xhat=x[u][i][j][l];
      }         
      /* MILSTEIN-end */

      /* update yerror: yerror -= At[u,i,j,l] * delta_x.   */

/* TEST_NO_ERRORUPDATE */ 
      if (config->homogeneous_flag==0) {
#ifndef SDVERSION
        for (s=0; s<physparam->S; s++) {
          yerror[s][0] -= At[s][0] * (xhat-x[u][i][j][l]);
          yerror[s][1] -= At[s][1] * (xhat-x[u][i][j][l]);
        }
#else
        for (s=0; s<physparam->S; s++) {
          k = findk(physparam, s);
          m = findm(physparam, s);
          temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                             detparam[m].calir, detparam[m].calii);
          temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                             detparam[m].calir, detparam[m].calii);
          temp2r = cplxmultr(At[s][0], At[s][1], temp1r, temp1i);
          temp2i = cplxmulti(At[s][0], At[s][1], temp1r, temp1i);
          temp3r = cplxmultr(temp2r, temp2i, physparam->wgtr, physparam->wgti);
          temp3i = cplxmulti(temp2r, temp2i, physparam->wgtr, physparam->wgti);
   
          yerror[s][0] -= temp3r * (xhat-x[u][i][j][l]);
          yerror[s][1] -= temp3i * (xhat-x[u][i][j][l]);
        }
#endif
      }
/**/
      /* update pixel */
      x[u][i][j][l] = xhat;
    }
  }

  /* BEGIN-TEST : Fill all voxels with mean value */
  if (config->homogeneous_flag==1) {
    mean[0] = 0.0;
    mean[1] = 0.0;

    for (u=0; u<2; u++)
    for (i= config->borderi; i<Ni-config->borderi; i++)
    for (j= config->borderj; j<Nj-config->borderj; j++)
    for (l= config->borderl; l<Nl-config->borderl; l++) {
      mean[u] += x[u][i][j][l];
    }

    for (u=0; u<2; u++) {
      mean[u] /= (Nl-2*config->borderl) * (Nj-2*config->borderj) * (Ni-2*config->borderi);

      for (i=0; i<Ni; i++)
      for (j=0; j<Nj; j++)
      for (l=0; l<Nl; l++) {
#ifndef SDVERSION
        for (s=0; s<physparam->S; s++) {
          yerror[s][0] -= At[s][0] * (xhat-x[u][i][j][l]);
          yerror[s][1] -= At[s][1] * (xhat-x[u][i][j][l]);
        }
#else
        for (s=0; s<physparam->S; s++) {
          k = findk(physparam, s);
          m = findm(physparam, s);
          temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                             detparam[m].calir, detparam[m].calii);
          temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                             detparam[m].calir, detparam[m].calii);
          temp2r = cplxmultr(At[s][0], At[s][1], temp1r, temp1i);
          temp2i = cplxmulti(At[s][0], At[s][1], temp1r, temp1i);
          temp3r = cplxmultr(temp2r, temp2i, physparam->wgtr, physparam->wgti);
          temp3i = cplxmulti(temp2r, temp2i, physparam->wgtr, physparam->wgti);
   
          yerror[s][0] -= temp3r * (mean[u]-x[u][i][j][l]);
          yerror[s][1] -= temp3i * (mean[u]-x[u][i][j][l]);
        }
#endif
      }
    }

    fprintf(stderr, "%f    %f \n", mean[0], mean[1]); 
  }
  /* END-TEST */

  free(rand_update_mask);
  multifree(At, 2);
}                              




