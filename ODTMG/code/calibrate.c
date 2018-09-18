#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "defs.h"


int findk(
  phys_param *physparam,
  int s
)
{
  int k,ss;
  LINK2D cur2D;
 
  cur2D = physparam->sparse;
  k=0; ss=0;
  while(cur2D!=NULL) {
    ss += count_elements(cur2D->d);
    if (ss-1>=s)
      break;
    cur2D = cur2D->next;
    k++;
  }
 
  return(k);
}
 
 
int findm(
  phys_param *physparam,
  int s
)
{
  int m,k,ss;
  LINK2D cur2D;
  LINK cur;
 
  cur2D = physparam->sparse;
  k=0;  ss=0;
  while(cur2D!=NULL) {
    ss += count_elements(cur2D->d);
    if (ss-1>=s)
      break;
    cur2D = cur2D->next;
    k++;
  }
 
  cur = cur2D->d;
  m=0;
  ss -= count_elements(cur2D->d);
  while(cur!=NULL) {
    if (ss+m>=s)
      break;
    cur = cur->next;
    m++;
  }
 
  return(cur->d);
}                 


int one_src_calibrate(
  int k,
  mtype **y,
  mtype **fx,
  mtype *lambda,
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam) 
{
  int    m, i;
  int   *s,*mm,s0,Ndet;
  double temp1r, temp1i;
  double a, br, bi;
  LINK2D cur2D;  
  LINK   cur;

  s  = (int *) malloc(sizeof(int) * physparam->M);
  mm = (int *) malloc(sizeof(int) * physparam->M);

  cur2D = physparam->sparse;
  s0 = 0;
  for (i=0; i<k; i++) {
    s0 += count_elements(cur2D->d);
    cur2D = cur2D->next;
  }
 
  cur = cur2D->d;
  Ndet = count_elements(cur);
  m=0;
  while(cur!=NULL) {
    s[m] = s0;
    mm[m] = cur->d;
    cur = cur->next;
    s0++;
    m++;
  }

  a = 0.0;
  br = 0.0;
  bi = 0.0;

  for (m=0; m<Ndet; m++) {
      temp1r = cplxmultr(detparam[mm[m]].calir, detparam[mm[m]].calii,
                         fx[s[m]][0], fx[s[m]][1]); 
      temp1i = cplxmulti(detparam[mm[m]].calir, detparam[mm[m]].calii,
                         fx[s[m]][0], fx[s[m]][1]); 
      a  +=  lambda[s[m]] * cplxmultr(temp1r, -temp1i, temp1r, temp1i); 
      br +=  lambda[s[m]] * cplxmultr(temp1r, -temp1i, y[s[m]][0], y[s[m]][1]);
      bi +=  lambda[s[m]] * cplxmulti(temp1r, -temp1i, y[s[m]][0], y[s[m]][1]);
  }

  srcparam[k].calir = br / a; 
  srcparam[k].calii = bi / a;

  free(s);
  free(mm);
 
  return 0;
}


int one_det_calibrate(
  int m,
  mtype **y,
  mtype **fx,
  mtype *lambda,
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam) 
{
  int    k,ss, Nsrc;
  int   *s,*kk;
  double temp1r, temp1i;
  double a, br, bi;
  LINK2D cur2D;
  LINK   cur;

  s  = (int *) malloc(sizeof(int) * physparam->K);
  kk = (int *) malloc(sizeof(int) * physparam->K);

  cur2D = physparam->sparse;
  k=0; Nsrc=0; ss=0;
  while(cur2D!=NULL) {
    cur = cur2D->d;
    while(cur!=NULL) { 
      if(cur->d==m) {
        kk[Nsrc] = k;
        s[Nsrc] = ss;
        Nsrc++; 
      }  
      cur = cur->next;
      ss++;  
    }  
    cur2D = cur2D->next;
    k++;
  }


  a = 0.0;
  br = 0.0;
  bi = 0.0;

  for (k=0; k<Nsrc; k++) { 
    if (s[k]>=0) {
      temp1r = cplxmultr(srcparam[kk[k]].calir, srcparam[kk[k]].calii,
                         fx[s[k]][0], fx[s[k]][1]); 
      temp1i = cplxmulti(srcparam[kk[k]].calir, srcparam[kk[k]].calii,
                         fx[s[k]][0], fx[s[k]][1]); 

      a  +=  lambda[s[k]] * cplxmultr(temp1r, -temp1i, temp1r, temp1i); 
      br +=  lambda[s[k]] * cplxmultr(temp1r, -temp1i, y[s[k]][0], y[s[k]][1]);
      bi +=  lambda[s[k]] * cplxmulti(temp1r, -temp1i, y[s[k]][0], y[s[k]][1]);
    }
  }

  detparam[m].calir = br / a;
  detparam[m].calii = bi / a;

  free(s);
  free(kk);

  return 0;
}


int src_det_calibrate(
  mtype **y,
  mtype **fx,
  mtype *lambda,
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam) 
{
  int i,k,m;
  double temp;

  i = 0;
  while (i<5) {
    for (k=0; k<physparam->K; k++) 
      one_src_calibrate(k, y, fx, lambda, srcparam, detparam, physparam);

    for (k=1; k<physparam->K; k++) {
      temp = cplxmultr(srcparam[0].calir,  srcparam[0].calii, 
                       srcparam[0].calir, -srcparam[0].calii);
      srcparam[k].calir = cplxmultr(srcparam[k].calir, srcparam[k].calii, 
                                    srcparam[0].calir, -srcparam[0].calii) / temp;
      srcparam[k].calii = cplxmulti(srcparam[k].calir, srcparam[k].calii, 
                                    srcparam[0].calir, -srcparam[0].calii) / temp;
    }

    srcparam[0].calir = 1.0; 
    srcparam[0].calii = 0.0;

    for (m=0; m<physparam->M; m++)
      one_det_calibrate(m, y, fx, lambda, srcparam, detparam, physparam);
    
/*
    for (k=0; k<physparam->K;k++)
      fprintf(stderr,"source %2d :   %f  %f \n",  k, srcparam[k].calir, srcparam[k].calii);
 
    for (m=0; m<physparam->M;m++)
      fprintf(stderr,"detector %2d :  %f  %f \n", m, detparam[m].calir, detparam[m].calii); 

    yerror = (mtype **) multialloc(sizeof(mtype), 2, physparam->S, 2);

    for (s=0; s<physparam->S; s++) {            
      k = findk(physparam,s);
      m = findm(physparam,s);
      temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                         detparam[m].calir, detparam[m].calii);
      temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                         detparam[m].calir, detparam[m].calii);
      yerror[s][0] = y[s][0] - cplxmultr(fx[s][0],fx[s][1],temp1r,temp1i);
      yerror[s][1] = y[s][1] - cplxmulti(fx[s][0],fx[s][1],temp1r,temp1i);      
    }
  
    fprintf(stderr, "rms error = %f\n", calc_rmse_with_lambda(yerror, lambda, physparam));
 
    multifree(yerror, 2);  
 
*/
    i++;
  } 

/*
  for (k=0; k<physparam->K; k++) {
    srcparam[k].calir = 1.0;
    srcparam[k].calii = 0.0;
  } 

  for (m=0; m<physparam->M; m++) {
    detparam[m].calir = 1.0;
    detparam[m].calii = 0.0;
  } 

  srcparam[1].calir = 1.1;
  srcparam[1].calii =-0.4;
  srcparam[2].calir = 0.7;
  srcparam[2].calii = 0.1;
  srcparam[3].calir = 1.2;
  srcparam[3].calii = 0.2;
 
  detparam[0].calir = 1.2;
  detparam[0].calii = 0.2;
  detparam[3].calir = 1.3;
  detparam[3].calii = 0.1;
  detparam[4].calir = 0.9;
  detparam[4].calii = 0.1;
  detparam[5].calir = 1.3;
  detparam[5].calii =-0.1;
  detparam[6].calir = 0.8;
  detparam[6].calii = 0.4;         
*/
  return 0;
}

 
/* Milstein */ 
int global_weight_calibrate(
  mtype ****x,
  mtype **y,
  mtype **fx,
  mtype *lambda,
  src_param *srcparam,
  det_param *detparam,
  phys_param *physparam)
{
  int k,m,s;
  mtype numr=0.0, numi=0.0,  den=0.0;
  mtype temp1r, temp1i, temp2r, temp2i;
 
  for(s=0; s<physparam->S; s++)
  {
    k = findk(physparam, s);
    m = findm(physparam, s);
    temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp2r = cplxmultr(fx[s][0], fx[s][1], temp1r, temp1i);
    temp2i = cplxmulti(fx[s][0], fx[s][1], temp1r, temp1i);

    numr += lambda[s]*cplxmultr(temp2r , -temp2i, y[s][0], y[s][1]);
    numi += lambda[s]*cplxmulti(temp2r , -temp2i, y[s][0], y[s][1]);
 
    den += AbsSquare(temp2r, temp2i) * lambda[s];
  }
 
  physparam->wgtr=numr/den;
  physparam->wgti=numi/den;
/*
  fprintf(stderr, "wgtr= %f   wgti = %f\n", physparam->wgtr, physparam->wgti);
*/
/* DEBUG-OHS *
  physparam->wgtr=1.5;
  physparam->wgti=0.5;
*/
  return 0;
}                 
