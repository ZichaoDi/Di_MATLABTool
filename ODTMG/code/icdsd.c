/* This file contains some trial subroutines 
   for simultaneous weights-image updates */


#include <stdio.h>
#include <math.h>
#include "defs.h"


/* Calculate the derivatives of source weights w.r.t. mua and D.
   Used for updating source weights after each one pixel update.  */
int calc_dsdx(
/* INPUT */
  int k,
  mtype **y,
  mtype **fx, 
  mtype *lambda, 
  mtype **At,                 /* At[s][c]  */
  phys_param *physparam, 
  src_param *srcparam, 
  det_param *detparam, 
  config_param *config, 
/* OUTPUT */
  mtype **dsdx)              /* dsdx[k][c] */  
{
  int    i, m;
  double temp2r, temp2i; 
  double temp4r, temp4i, temp5r, temp5i; 
  double a[2],b,c[2],d;
  int   *s, *mm, s0, Ndet;  
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


  a[0]=0; a[1]=0; b=0; c[0]=0; c[1]=0; d=0; 

  for (m=0; m<Ndet; m++) {
    temp2r = cplxmultr(detparam[mm[m]].calir, detparam[mm[m]].calii, 
                       physparam->wgtr, physparam->wgti);
    temp2i = cplxmulti(detparam[mm[m]].calir, detparam[mm[m]].calii, 
                       physparam->wgtr, physparam->wgti);
    temp4r = cplxmultr(temp2r, temp2i, fx[s[m]][0], fx[s[m]][1]);
    temp4i = cplxmulti(temp2r, temp2i, fx[s[m]][0], fx[s[m]][1]);
    temp5r = cplxmultr(temp2r, temp2i, At[s[m]][0], At[s[m]][1]);
    temp5i = cplxmulti(temp2r, temp2i, At[s[m]][0], At[s[m]][1]);

    a[0] += cplxmultr(y[s[m]][0], y[s[m]][1], temp5r, -temp5i) * lambda[s[m]];
    a[1] += cplxmulti(y[s[m]][0], y[s[m]][1], temp5r, -temp5i) * lambda[s[m]];
    d    += 2 * cplxmultr(temp4r, -temp4i, temp5r, temp5i) * lambda[s[m]]; 
   
    b    += AbsSquare(temp4r, temp4i) * lambda[s[m]];
    c[0] += cplxmultr(y[s[m]][0], y[s[m]][1], temp4r, -temp4i) * lambda[s[m]];
    c[1] += cplxmulti(y[s[m]][0], y[s[m]][1], temp4r, -temp4i) * lambda[s[m]];
  }

  dsdx[k][0] = (a[0]*b-c[0]*d)/(b*b);
  dsdx[k][1] = (a[1]*b-c[1]*d)/(b*b);

  free(s);
  free(mm);  

  return 0;
} 


/* Calculate the derivatives of detector weights w.r.t. mua and D.
   Used for updating detector weights after each one pixel update.  */
int calc_dddx(
/* INPUT */
  int m,
  mtype **y,
  mtype **fx, 
  mtype *lambda, 
  mtype **At,            /* At[s][c]  */ 
  phys_param *physparam, 
  src_param *srcparam, 
  det_param *detparam, 
  config_param *config, 
/* OUTPUT */
  mtype **dddx)          /* dddx[k][c] */    
{
  int   *s,*kk, Nsrc, k, ss;
  double temp2r, temp2i, temp4r, temp4i, temp5r, temp5i; 
  double a[2],b,c[2],d;

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
                  
  a[0]=0; a[1]=0; b=0; c[0]=0; c[1]=0; d=0; 

  for (k=0; k<Nsrc; k++) {
    temp2r = cplxmultr(srcparam[kk[k]].calir, srcparam[kk[k]].calii, 
                       physparam->wgtr, physparam->wgti);
    temp2i = cplxmulti(srcparam[kk[k]].calir, srcparam[kk[k]].calii, 
                       physparam->wgtr, physparam->wgti);
    temp4r = cplxmultr(temp2r, temp2i, fx[s[k]][0], fx[s[k]][1]);
    temp4i = cplxmulti(temp2r, temp2i, fx[s[k]][0], fx[s[k]][1]);
    temp5r = cplxmultr(temp2r, temp2i, At[s[k]][0], At[s[k]][1]);
    temp5i = cplxmulti(temp2r, temp2i, At[s[k]][0], At[s[k]][1]);

    a[0] += cplxmultr(y[s[k]][0], y[s[k]][1], temp5r, -temp5i) * lambda[s[k]];
    a[1] += cplxmulti(y[s[k]][0], y[s[k]][1], temp5r, -temp5i) * lambda[s[k]];
    d += 2 * cplxmultr(temp4r, -temp4i, temp5r, temp5i) * lambda[s[k]]; 

    b += AbsSquare(temp4r, temp4i) * lambda[s[k]];
    c[0] += cplxmultr(y[s[k]][0], y[s[k]][1], temp4r, -temp4i) * lambda[s[k]];
    c[1] += cplxmulti(y[s[k]][0], y[s[k]][1], temp4r, -temp4i) * lambda[s[k]];
  }

  dddx[m][0] = (a[0]*b-c[0]*d)/(b*b);
  dddx[m][1] = (a[1]*b-c[1]*d)/(b*b);
 
  free(s);
  free(kk);

  return 0;
} 



/* Update pixels performing one-cycle ICD iteration 
   where the ds/dx and dd/dx are considered to calculate the Frechet derivatives dCost/dx. 
   This routine does NOT perform the error correction for s-d calibration.
   (See ICD_update_sd2() . )
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
  config_param *config)
{
  int u,i,j,l,ubegin,uend;
  int q,t,rand_index;
  int Ni,Nj,Nl;
  int Nq;
  mtype **At, **Ats, **Atd, **Atall;
  dtype **srchat, **dethat; 
  double xhat;
  int s;
  int *rand_update_mask=NULL;
  double temp1r, temp1i, temp2r, temp2i, temp3r, temp3i;    
  int k,m;

  Ni=physparam->Ni;
  Nj=physparam->Nj;
  Nl=physparam->Nl;
  Nq=(Ni-2*config->borderi)*(Nj-2*config->borderj)*(Nl-2*config->borderl);
  
  At     = multialloc(sizeof(mtype), 2, physparam->S, 2);
  Ats    = multialloc(sizeof(mtype), 2, physparam->K, 2);
  Atd    = multialloc(sizeof(mtype), 2, physparam->M, 2);
  Atall  = multialloc(sizeof(mtype), 2, physparam->S, 2);
  srchat = multialloc(sizeof(dtype), 2, physparam->K, 2);
  dethat = multialloc(sizeof(dtype), 2, physparam->M, 2);
                
  rand_update_mask = (int *)malloc(Nq*sizeof(int));

  if (config->mua_flag && config->D_flag) {
    ubegin = 0; 
    uend = 1;
  } 
  else if (config->mua_flag && !config->D_flag) {
    ubegin = 0; 
    uend = 0;
  } 
  else if (!config->mua_flag && config->D_flag) {
    ubegin = 1; 
    uend = 1;
  }
  else {
    fprintf(stderr,"Error! Both mua_flag and D_flag are 0!!!\n");
    exit(1);
  }

  for (u=ubegin; u<uend+1; u++){     
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

      l = config->borderl +  q%(Nl-2*config->borderl);
      j = config->borderj + (q/(Nl-2*config->borderl)) % (Nj-2*config->borderj);
      i = config->borderi + (q/((Nl-2*config->borderl) * (Nj-2*config->borderj)))
          % (Ni-2*config->borderi);

      calc_frechet_col(u, i, j, l, phi, green, x, srcparam, detparam, physparam, At);

      for (k=0; k<physparam->K; k++) 
        calc_dsdx(k, y, fx, lambda, At, physparam, srcparam, detparam, config, Ats);

      for (m=0; m<physparam->M; m++) 
        calc_dddx(m, y, fx, lambda, At, physparam, srcparam, detparam, config, Atd);

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
          Atall[s][0] = temp3r;
          Atall[s][1] = temp3i;

          temp1r = cplxmultr(Ats[k][0], Ats[k][1], detparam[m].calir, detparam[m].calii);
          temp1i = cplxmulti(Ats[k][0], Ats[k][1], detparam[m].calir, detparam[m].calii);
          temp2r = cplxmultr(fx[s][0], fx[s][1], temp1r, temp1i);
          temp2i = cplxmulti(fx[s][0], fx[s][1], temp1r, temp1i);
          temp3r = cplxmultr(temp2r, temp2i, physparam->wgtr, physparam->wgti);
          temp3i = cplxmulti(temp2r, temp2i, physparam->wgtr, physparam->wgti);
          Atall[s][0] += temp3r;
          Atall[s][1] += temp3i;

          temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii, Atd[m][0], Atd[m][1]);
          temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii, Atd[m][0], Atd[m][1]);
          temp2r = cplxmultr(fx[s][0], fx[s][1], temp1r, temp1i);
          temp2i = cplxmulti(fx[s][0], fx[s][1], temp1r, temp1i);
          temp3r = cplxmultr(temp2r, temp2i, physparam->wgtr, physparam->wgti);
          temp3i = cplxmulti(temp2r, temp2i, physparam->wgtr, physparam->wgti);
          Atall[s][0] += temp3r;
          Atall[s][1] += temp3i;
      }


      if(u==MUA)
        xhat = ICD_pixel_update(u, i, j, l, Atall, x, yerror, lambda,
                                priorparam_mua, physparam, srcparam, detparam);
      else
        xhat = ICD_pixel_update(u, i, j, l, Atall, x, yerror, lambda,
                                priorparam_D, physparam, srcparam, detparam);

      for (k=0; k<physparam->K; k++) {
        srchat[k][0] = srcparam[k].calir + Ats[k][0] * (xhat-x[u][i][j][l]); 
        srchat[k][1] = srcparam[k].calii + Ats[k][1] * (xhat-x[u][i][j][l]);  
      }

      for (m=0; m<physparam->M; m++) {
        dethat[m][0] = detparam[m].calir + Atd[m][0] * (xhat-x[u][i][j][l]); 
        dethat[m][1] = detparam[m].calii + Atd[m][1] * (xhat-x[u][i][j][l]);
      }  

      for (k=0; k<physparam->K; k++) {
        srchat[k][0] = srcparam[k].calir;
        srchat[k][1] = srcparam[k].calii;
      }

      for (m=0; m<physparam->M; m++) {
        dethat[m][0] = detparam[m].calir; 
        dethat[m][1] = detparam[m].calii;
      }  


      for (s=0; s<physparam->S; s++) {
        k = findk(physparam, s);
        m = findm(physparam, s);

        temp1r = cplxmultr(srchat[k][0], srchat[k][1], dethat[m][0], dethat[m][1]); 
        temp1i = cplxmulti(srchat[k][0], srchat[k][1], dethat[m][0], dethat[m][1]); 
        temp2r = cplxmultr(temp1r, temp1i, physparam->wgtr, physparam->wgti);
        temp2i = cplxmulti(temp1r, temp1i, physparam->wgtr, physparam->wgti);
        yerror[s][0] -= cplxmultr(fx[s][0]+At[s][0]*(xhat-x[u][i][j][l]), 
                                  fx[s][1]+At[s][1]*(xhat-x[u][i][j][l]), temp2r, temp2i);
        yerror[s][1] -= cplxmulti(fx[s][0]+At[s][0]*(xhat-x[u][i][j][l]), 
                                  fx[s][1]+At[s][1]*(xhat-x[u][i][j][l]), temp2r, temp2i);

        temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                           detparam[m].calir, detparam[m].calii);
        temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                           detparam[m].calir, detparam[m].calii);
        temp2r = cplxmultr(temp1r, temp1i, physparam->wgtr, physparam->wgti);
        temp2i = cplxmulti(temp1r, temp1i, physparam->wgtr, physparam->wgti);
        yerror[s][0] += cplxmultr(fx[s][0], fx[s][1], temp2r, temp2i);
        yerror[s][1] += cplxmulti(fx[s][0], fx[s][1], temp2r, temp2i);
      }

      x[u][i][j][l] = xhat;

      for (k=0; k<physparam->K; k++) {
        srcparam[k].calir = srchat[k][0];
        srcparam[k].calii = srchat[k][1]; 
      }

      for (m=0; m<physparam->M; m++) {
        detparam[m].calir = dethat[m][0]; 
        detparam[m].calii = dethat[m][1]; 
      }  
    }

    printf("yerror=(%e %e)    At=%e\n", yerror[0][0],yerror[0][1], At[0][0]); 

    /* Crude debugging */
    for (q=0; q<Nq; q++){
      if(rand_update_mask[q]!=1){
         printf("Error!!!!!!!!!!!!!!!!!!\n");
         exit(1);
      }
    }
    /*End Crude debugging*/
  }


  free(rand_update_mask);
  multifree(At, 2);
  multifree(Ats, 2);
  multifree(Atd, 2);
  multifree(Atall, 2);
  multifree(srchat, 2);
  multifree(dethat, 2);
}                              


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
  config_param *config)
{
  int u,i,j,l,ubegin,uend;
  int q,t,rand_index;
  int Ni,Nj,Nl;
  int Nq;
  mtype **At, **Ats, **Atd, **Atall;
  dtype **srcold, **detold; 
  double xhat;
  int s;
  int *rand_update_mask=NULL;
  double temp1r, temp1i, temp2r, temp2i, temp3r, temp3i;    
  int k,m;

  Ni=physparam->Ni;
  Nj=physparam->Nj;
  Nl=physparam->Nl;
  Nq=(Ni-2*config->borderi)*(Nj-2*config->borderj)*(Nl-2*config->borderl);
  
  At     = multialloc(sizeof(mtype), 2, physparam->S, 2);
  Ats    = multialloc(sizeof(mtype), 2, physparam->K, 2);
  Atd    = multialloc(sizeof(mtype), 2, physparam->M, 2);
  Atall  = multialloc(sizeof(mtype), 2, physparam->S, 2);
  srcold = multialloc(sizeof(dtype), 2, physparam->K, 2);
  detold = multialloc(sizeof(dtype), 2, physparam->M, 2);
                
  rand_update_mask = (int *)malloc(Nq*sizeof(int));

  if (config->mua_flag && config->D_flag) {
    ubegin = 0; 
    uend = 1;
  } 
  else if (config->mua_flag && !config->D_flag) {
    ubegin = 0; 
    uend = 0;
  } 
  else if (!config->mua_flag && config->D_flag) {
    ubegin = 1; 
    uend = 1;
  }
  else {
    fprintf(stderr,"Error! Both mua_flag and D_flag are 0!!!\n");
    exit(1);
  }

  for (u=ubegin; u<uend+1; u++){     
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

      l = config->borderl +  q%(Nl-2*config->borderl);
      j = config->borderj + (q/(Nl-2*config->borderl)) % (Nj-2*config->borderj);
      i = config->borderi + (q/((Nl-2*config->borderl) * (Nj-2*config->borderj)))
          % (Ni-2*config->borderi);

      calc_frechet_col(u, i, j, l, phi, green, x, srcparam, detparam, physparam, At);

      for (k=0; k<physparam->K; k++) 
        calc_dsdx(k, y, fx, lambda, At, physparam, srcparam, detparam, config, Ats);

      for (m=0; m<physparam->M; m++) 
        calc_dddx(m, y, fx, lambda, At, physparam, srcparam, detparam, config, Atd);

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
          Atall[s][0] = temp3r;
          Atall[s][1] = temp3i;

          temp1r = cplxmultr(Ats[k][0], Ats[k][1], detparam[m].calir, detparam[m].calii);
          temp1i = cplxmulti(Ats[k][0], Ats[k][1], detparam[m].calir, detparam[m].calii);
          temp2r = cplxmultr(fx[s][0], fx[s][1], temp1r, temp1i);
          temp2i = cplxmulti(fx[s][0], fx[s][1], temp1r, temp1i);
          temp3r = cplxmultr(temp2r, temp2i, physparam->wgtr, physparam->wgti);
          temp3i = cplxmulti(temp2r, temp2i, physparam->wgtr, physparam->wgti);
          Atall[s][0] += temp3r;
          Atall[s][1] += temp3i;

          temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii, Atd[m][0], Atd[m][1]);
          temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii, Atd[m][0], Atd[m][1]);
          temp2r = cplxmultr(fx[s][0], fx[s][1], temp1r, temp1i);
          temp2i = cplxmulti(fx[s][0], fx[s][1], temp1r, temp1i);
          temp3r = cplxmultr(temp2r, temp2i, physparam->wgtr, physparam->wgti);
          temp3i = cplxmulti(temp2r, temp2i, physparam->wgtr, physparam->wgti);
          Atall[s][0] += temp3r;
          Atall[s][1] += temp3i;
      }


      if(u==MUA)
        xhat = ICD_pixel_update(u, i, j, l, Atall, x, yerror, lambda,
                                priorparam_mua, physparam, srcparam, detparam);
      else
        xhat = ICD_pixel_update(u, i, j, l, Atall, x, yerror, lambda,
                                priorparam_D, physparam, srcparam, detparam);


      for (k=0; k<physparam->K; k++) {
        srcold[k][0] = srcparam[k].calir;
        srcold[k][1] = srcparam[k].calii;
      }

      for (m=0; m<physparam->M; m++) {
        detold[m][0] = detparam[m].calir; 
        detold[m][1] = detparam[m].calii;
      }  

      src_det_calibrate(y, fx, lambda, srcparam, detparam, physparam);

      for (s=0; s<physparam->S; s++) {
        k = findk(physparam, s);
        m = findm(physparam, s);

        temp1r = cplxmultr(srcold[k][0], srcold[k][1], detold[m][0], detold[m][1]); 
        temp1i = cplxmulti(srcold[k][0], srcold[k][1], detold[m][0], detold[m][1]); 
        temp2r = cplxmultr(temp1r, temp1i, physparam->wgtr, physparam->wgti);
        temp2i = cplxmulti(temp1r, temp1i, physparam->wgtr, physparam->wgti);
        yerror[s][0] += cplxmultr(fx[s][0], fx[s][1], temp2r, temp2i);
        yerror[s][1] += cplxmulti(fx[s][0], fx[s][1], temp2r, temp2i);

        temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                           detparam[m].calir, detparam[m].calii);
        temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                           detparam[m].calir, detparam[m].calii);
        temp2r = cplxmultr(temp1r, temp1i, physparam->wgtr, physparam->wgti);
        temp2i = cplxmulti(temp1r, temp1i, physparam->wgtr, physparam->wgti);
        yerror[s][0] -= cplxmultr(fx[s][0]+At[s][0]*(xhat-x[u][i][j][l]), 
                                  fx[s][1]+At[s][1]*(xhat-x[u][i][j][l]), temp2r, temp2i);
        yerror[s][1] -= cplxmulti(fx[s][0]+At[s][0]*(xhat-x[u][i][j][l]), 
                                  fx[s][1]+At[s][1]*(xhat-x[u][i][j][l]), temp2r, temp2i);
      }

      x[u][i][j][l] = xhat;
    }

    printf("yerror=(%e %e)    At=%e\n", yerror[0][0],yerror[0][1], At[0][0]); 

    /* Crude debugging */
    for (q=0; q<Nq; q++){
      if(rand_update_mask[q]!=1){
         printf("Error!!!!!!!!!!!!!!!!!!\n");
         exit(1);
      }
    }
    /*End Crude debugging*/
  }

  free(rand_update_mask);
  multifree(At, 2);
  multifree(Ats, 2);
  multifree(Atd, 2);
  multifree(Atall, 2);
  multifree(srcold, 2);
  multifree(detold, 2);
}                              

