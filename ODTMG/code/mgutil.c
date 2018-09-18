#include <stdio.h>
#include <math.h>
#include "defs.h"


int decimate1Dkernel(
  mtype **kernel,
  int   Nifine)
{
  int i,j,Nicoarse;

  Nicoarse = ncoarse(Nifine);

  for (i=0; i<Nicoarse; i++) 
  for (j=0; j<Nifine; j++) 
    kernel[i][j] = 0.0;    

  for (i=1; i<Nicoarse-1; i++) {
    kernel[i][i*2-1] = 0.25;    
    kernel[i][i*2]   = 0.5;    
    kernel[i][i*2+1] = 0.25;    
  }
 
  kernel[0][0]= 0.75;
  kernel[0][1]= 0.25;
  kernel[Nicoarse-1][Nifine-2]= 0.25;
  kernel[Nicoarse-1][Nifine-1]= 0.75;

  return 0; 
}


int decimate1D(
  mtype *xfine,     
  int    Nifine,
  mtype *xcoarse)     
{
  int i,j,Nicoarse;
  mtype **kernel;

  Nicoarse = ncoarse(Nifine);
  kernel = multialloc(sizeof(mtype), 2, Nicoarse, Nifine);

  decimate1Dkernel(kernel, Nifine);

  for (i=0; i<Nicoarse; i++) {
    xcoarse[i] = 0.0;
    for (j=0; j<Nifine; j++) 
      xcoarse[i] += xfine[j] * kernel[i][j];
  }

  multifree(kernel, 2);

  return 0; 
}


int interpolatetranspose1Dkernel(
  mtype **kernel,
  int   Nifine)
{
  int i,j,Nicoarse;

  Nicoarse = ncoarse(Nifine);

  decimate1Dkernel(kernel, Nifine);
   
  kernel[0][0]= 0.5;
  kernel[Nicoarse-1][Nifine-1]= 0.5;

  for (i=0; i<Nicoarse; i++) 
  for (j=0; j<Nifine; j++) 
    kernel[i][j] *= 2.0;

  return 0; 
}


int interpolatetranspose1D(
  mtype *xfine,     
  int    Nifine,
  mtype *xcoarse)     
{
  int i,j,Nicoarse;
  mtype **kernel;

  Nicoarse = ncoarse(Nifine);
  kernel = multialloc(sizeof(mtype), 2, Nicoarse, Nifine);

  interpolatetranspose1Dkernel(kernel, Nifine);

  for (i=0; i<Nicoarse; i++) {
    xcoarse[i] = 0.0;
    for (j=0; j<Nifine; j++) 
      xcoarse[i] += xfine[j] * kernel[i][j];
  }

  multifree(kernel, 2);

  return 0; 
}


int interpolate1Dkernel(
  mtype **kernel,
  int   Nicoarse)
{
  int i,j,Nifine;
  mtype **kernel4dec;

  Nifine = nfine(Nicoarse);
  kernel4dec = multialloc(sizeof(mtype), 2, Nicoarse, Nifine);

  decimate1Dkernel(kernel4dec, Nifine);
   
  for (i=0; i<Nifine; i++) 
  for (j=0; j<Nicoarse; j++) 
    kernel[i][j] = 2.0 * kernel4dec[j][i];    

  kernel[0][0]= 1.0;
  kernel[Nifine-1][Nicoarse-1]= 1.0;

  multifree(kernel4dec, 2);

  return 0; 
}



int interpolate1D(
  mtype *xcoarse,   /* x^h       : input, x[i] */
  int   Nicoarse,
  mtype *xfine)     /* x^{(h+1)} : output */
{
  int i,j,Nifine;
  mtype **kernel;

  Nifine = nfine(Nicoarse);
  kernel = multialloc(sizeof(mtype), 2, Nifine, Nicoarse);

  interpolate1Dkernel(kernel, Nicoarse);

  for (i=0; i<Nifine; i++) {
    xfine[i] = 0.0;
    for (j=0; j<Nicoarse; j++) 
      xfine[i] += xcoarse[j] * kernel[i][j];
  }

  multifree(kernel, 2);

  return 0; 
}


/* decimation for x : x-y-z directions sequentially */
int decimatex(
  mtype ****xfine,     /* x^{(h+1)} : input, x[u][i][j][l] */
  int   Nifine,
  int   Njfine,
  int   Nlfine,
  mtype ****xcoarse)   /* x^h       : output  */
{
  int u,i,j,l;
  int Nicoarse, Njcoarse, Nlcoarse;
  mtype ****xt1, ****xt2;
  mtype *xicoarse, *xifine, *xjcoarse, *xjfine, *xlcoarse, *xlfine;

  Nicoarse = ncoarse(Nifine); 
  Njcoarse = ncoarse(Njfine); 
  Nlcoarse = ncoarse(Nlfine);

  xt1 = multialloc(sizeof(mtype), 4, 2, Nicoarse, Njfine, Nlfine);
  xt2 = multialloc(sizeof(mtype), 4, 2, Nicoarse, Njcoarse, Nlfine);
  xifine = (mtype *) malloc(sizeof(mtype)*Nifine); 
  xjfine = (mtype *) malloc(sizeof(mtype)*Njfine); 
  xlfine = (mtype *) malloc(sizeof(mtype)*Nlfine); 
  xicoarse = (mtype *) malloc(sizeof(mtype)*Nicoarse); 
  xjcoarse = (mtype *) malloc(sizeof(mtype)*Njcoarse); 
  xlcoarse = (mtype *) malloc(sizeof(mtype)*Nlcoarse); 


  for (u=0; u<2; u++) {
    for (j=0; j<Njfine; j++)
    for (l=0; l<Nlfine; l++) {
      for (i=0; i<Nifine; i++)
        xifine[i] = xfine[u][i][j][l];
 
      decimate1D(xifine, Nifine, xicoarse);

      for (i=0; i<Nicoarse; i++)
        xt1[u][i][j][l] = xicoarse[i];
    }

    for (i=0; i<Nicoarse; i++)
    for (l=0; l<Nlfine; l++) {
      for (j=0; j<Njfine; j++)
        xjfine[j] = xt1[u][i][j][l];
 
      decimate1D(xjfine, Njfine, xjcoarse);

      for (j=0; j<Njcoarse; j++)
        xt2[u][i][j][l] = xjcoarse[j];
    }

    for (i=0; i<Nicoarse; i++)
    for (j=0; j<Njcoarse; j++) {
      for (l=0; l<Nlfine; l++) 
        xlfine[l] = xt2[u][i][j][l];

      decimate1D(xlfine, Nlfine, xlcoarse);

      for (l=0; l<Nlcoarse; l++)
        xcoarse[u][i][j][l] = xlcoarse[l];
    }
  }

  multifree(xt1, 4);
  multifree(xt2, 4);
  free(xifine);
  free(xjfine);
  free(xlfine);
  free(xicoarse);
  free(xjcoarse);
  free(xlcoarse);

  return 0;
}


int interpolatetransposex(
  mtype ****xfine,     /* x^{(h+1)} : input, x[u][i][j][l] */
  int   Nifine,
  int   Njfine,
  int   Nlfine,
  mtype ****xcoarse)   /* x^h       : output  */
{
  int u,i,j,l;
  int Nicoarse, Njcoarse, Nlcoarse;
  mtype ****xt1, ****xt2;
  mtype *xicoarse, *xifine, *xjcoarse, *xjfine, *xlcoarse, *xlfine;

  Nicoarse = ncoarse(Nifine); 
  Njcoarse = ncoarse(Njfine); 
  Nlcoarse = ncoarse(Nlfine);

  xt1 = multialloc(sizeof(mtype), 4, 2, Nicoarse, Njfine, Nlfine);
  xt2 = multialloc(sizeof(mtype), 4, 2, Nicoarse, Njcoarse, Nlfine);
  xifine = (mtype *) malloc(sizeof(mtype)*Nifine); 
  xjfine = (mtype *) malloc(sizeof(mtype)*Njfine); 
  xlfine = (mtype *) malloc(sizeof(mtype)*Nlfine); 
  xicoarse = (mtype *) malloc(sizeof(mtype)*Nicoarse); 
  xjcoarse = (mtype *) malloc(sizeof(mtype)*Njcoarse); 
  xlcoarse = (mtype *) malloc(sizeof(mtype)*Nlcoarse); 


  for (u=0; u<2; u++) {
    for (j=0; j<Njfine; j++)
    for (l=0; l<Nlfine; l++) {
      for (i=0; i<Nifine; i++)
        xifine[i] = xfine[u][i][j][l];
 
      interpolatetranspose1D(xifine, Nifine, xicoarse);

      for (i=0; i<Nicoarse; i++)
        xt1[u][i][j][l] = xicoarse[i];
    }

    for (i=0; i<Nicoarse; i++)
    for (l=0; l<Nlfine; l++) {
      for (j=0; j<Njfine; j++)
        xjfine[j] = xt1[u][i][j][l];
 
      interpolatetranspose1D(xjfine, Njfine, xjcoarse);

      for (j=0; j<Njcoarse; j++)
        xt2[u][i][j][l] = xjcoarse[j];
    }

    for (i=0; i<Nicoarse; i++)
    for (j=0; j<Njcoarse; j++) {
      for (l=0; l<Nlfine; l++) 
        xlfine[l] = xt2[u][i][j][l];

      interpolatetranspose1D(xlfine, Nlfine, xlcoarse);

      for (l=0; l<Nlcoarse; l++)
        xcoarse[u][i][j][l] = xlcoarse[l];
    }
  }

  multifree(xt1, 4);
  multifree(xt2, 4);
  free(xifine);
  free(xjfine);
  free(xlfine);
  free(xicoarse);
  free(xjcoarse);
  free(xlcoarse);

  return 0;
}


/* interpolation for x : z-y-x directions sequentially */
int interpolatex(
  mtype ****xcoarse,   /* x^h       : input, x[u][i][j][l] */
  int   Nicoarse,
  int   Njcoarse,
  int   Nlcoarse,
  mtype ****xfine)     /* x^{(h+1)} : output */
{
  int u,i,j,l;
  int Nifine, Njfine, Nlfine;
  mtype ****xt1, ****xt2;
  mtype *xicoarse, *xifine, *xjcoarse, *xjfine, *xlcoarse, *xlfine;

  Nifine = nfine(Nicoarse);
  Njfine = nfine(Njcoarse); 
  Nlfine = nfine(Nlcoarse);
  
  xt1 = multialloc(sizeof(mtype), 4, 2, Nicoarse, Njcoarse, Nlfine);
  xt2 = multialloc(sizeof(mtype), 4, 2, Nicoarse, Njfine, Nlfine);
  xifine   = (mtype *) malloc(sizeof(mtype)*Nifine); 
  xjfine   = (mtype *) malloc(sizeof(mtype)*Njfine); 
  xlfine   = (mtype *) malloc(sizeof(mtype)*Nlfine); 
  xicoarse = (mtype *) malloc(sizeof(mtype)*Nicoarse); 
  xjcoarse = (mtype *) malloc(sizeof(mtype)*Njcoarse); 
  xlcoarse = (mtype *) malloc(sizeof(mtype)*Nlcoarse); 


  for (u=0; u<2; u++) {
    for (i=0; i<Nicoarse; i++)
    for (j=0; j<Njcoarse; j++) {
      for (l=0; l<Nlcoarse; l++) 
        xlcoarse[l] = xcoarse[u][i][j][l];

      interpolate1D(xlcoarse, Nlcoarse, xlfine);

      for (l=0; l<Nlfine; l++) 
        xt1[u][i][j][l] = xlfine[l];
    }

    for (i=0; i<Nicoarse; i++)
    for (l=0; l<Nlfine; l++) {
      for (j=0; j<Njcoarse; j++)
        xjcoarse[j] = xt1[u][i][j][l];

      interpolate1D(xjcoarse, Njcoarse, xjfine);

      for (j=0; j<Njfine; j++) 
        xt2[u][i][j][l] = xjfine[j];
    }

    for (j=0; j<Njfine; j++)
    for (l=0; l<Nlfine; l++) {
      for (i=0; i<Nicoarse; i++)
        xicoarse[i] = xt2[u][i][j][l];

      interpolate1D(xicoarse, Nicoarse, xifine);

      for (i=0; i<Nifine; i++)
        xfine[u][i][j][l] = xifine[i];
    } 
  }

  multifree(xt1,4);
  multifree(xt2,4);
  free(xifine);
  free(xjfine);
  free(xlfine);
  free(xicoarse);
  free(xjcoarse);
  free(xlcoarse);

  return 0;
}
 

int interpolatortranspose(
  mtype ****xfine,   /* x^h       : input, x[u][i][j][l] */
  int   Nifine,
  int   Njfine,
  int   Nlfine,
  mtype ****xcoarse,     /* x^{(h+1)} : output */
  config_param *config_fine)
{
  mtype ****in_xcoarse, ****in_xfine;
  int u,i,j,l;
  int Nicoarse, Njcoarse, Nlcoarse;
  int bi_fine, bj_fine, bl_fine, bi_coarse, bj_coarse, bl_coarse;

  Nicoarse = ncoarse(Nifine); 
  Njcoarse = ncoarse(Njfine); 
  Nlcoarse = ncoarse(Nlfine);
  
  bi_fine   = config_fine->borderi;
  bj_fine   = config_fine->borderj;
  bl_fine   = config_fine->borderl;
  bi_coarse = bi_fine / 2;
  bj_coarse = bj_fine / 2;
  bl_coarse = bl_fine / 2;

  in_xcoarse = multialloc(sizeof(mtype), 4, 2, 
                  Nicoarse-2*bi_coarse, Njcoarse-2*bj_coarse, Nlcoarse-2*bl_coarse);
  in_xfine   = multialloc(sizeof(mtype), 4, 2, 
                  Nifine-2*bi_fine, Njfine-2*bj_fine, Nlfine-2*bl_fine);

  for (u=0; u<2; u++)
  for (i=0; i<Nifine-2*bi_fine; i++)
  for (j=0; j<Njfine-2*bj_fine; j++)
  for (l=0; l<Nlfine-2*bl_fine; l++) 
    in_xfine[u][i][j][l] = xfine[u][i+bi_fine][j+bj_fine][l+bl_fine];

  interpolatetransposex(in_xfine, Nifine-2*bi_fine, Njfine-2*bj_fine, 
                        Nlfine-2*bl_fine, in_xcoarse);  

  for (u=0; u<2; u++)
  for (i=0; i<Nicoarse; i++)
  for (j=0; j<Njcoarse; j++)
  for (l=0; l<Nlcoarse; l++) 
    xcoarse[u][i][j][l] = xfine[u][0][0][0];

  for (u=0; u<2; u++)
  for (i=0; i<Nicoarse-2*bi_coarse; i++)
  for (j=0; j<Njcoarse-2*bj_coarse; j++)
  for (l=0; l<Nlcoarse-2*bl_coarse; l++) 
    xcoarse[u][i+bi_coarse][j+bj_coarse][l+bl_coarse] = in_xcoarse[u][i][j][l];

  multifree(in_xcoarse, 4);
  multifree(in_xfine, 4);

  return 0;
}


int decimator(
  mtype ****xfine,   /* x^h       : input, x[u][i][j][l] */
  int   Nifine,
  int   Njfine,
  int   Nlfine,
  mtype ****xcoarse,     /* x^{(h+1)} : output */
  config_param *config_fine)
{
  mtype ****in_xcoarse, ****in_xfine;
  int u,i,j,l;
  int Nicoarse, Njcoarse, Nlcoarse;
  int bi_fine, bj_fine, bl_fine, bi_coarse, bj_coarse, bl_coarse;

  Nicoarse = ncoarse(Nifine); 
  Njcoarse = ncoarse(Njfine); 
  Nlcoarse = ncoarse(Nlfine);
  
  bi_fine   = config_fine->borderi;
  bj_fine   = config_fine->borderj;
  bl_fine   = config_fine->borderl;
  bi_coarse = bi_fine / 2;
  bj_coarse = bj_fine / 2;
  bl_coarse = bl_fine / 2;

  in_xcoarse = multialloc(sizeof(mtype), 4, 2, 
                  Nicoarse-2*bi_coarse, Njcoarse-2*bj_coarse, Nlcoarse-2*bl_coarse);
  in_xfine   = multialloc(sizeof(mtype), 4, 2, 
                  Nifine-2*bi_fine, Njfine-2*bj_fine, Nlfine-2*bl_fine);

  for (u=0; u<2; u++)
  for (i=0; i<Nifine-2*bi_fine; i++)
  for (j=0; j<Njfine-2*bj_fine; j++)
  for (l=0; l<Nlfine-2*bl_fine; l++) 
    in_xfine[u][i][j][l] = xfine[u][i+bi_fine][j+bj_fine][l+bl_fine];

  decimatex(in_xfine, Nifine-2*bi_fine, Njfine-2*bj_fine, Nlfine-2*bl_fine, in_xcoarse);  

  for (u=0; u<2; u++)
  for (i=0; i<Nicoarse; i++)
  for (j=0; j<Njcoarse; j++)
  for (l=0; l<Nlcoarse; l++) 
    xcoarse[u][i][j][l] = xfine[u][0][0][0];

  for (u=0; u<2; u++)
  for (i=0; i<Nicoarse-2*bi_coarse; i++)
  for (j=0; j<Njcoarse-2*bj_coarse; j++)
  for (l=0; l<Nlcoarse-2*bl_coarse; l++) 
    xcoarse[u][i+bi_coarse][j+bj_coarse][l+bl_coarse] = in_xcoarse[u][i][j][l];

  multifree(in_xcoarse, 4);
  multifree(in_xfine, 4);

  return 0;
}


int interpolator(
  mtype ****xcoarse,   /* x^h       : input, x[u][i][j][l] */
  int   Nicoarse,
  int   Njcoarse,
  int   Nlcoarse,
  mtype ****xfine,     /* x^{(h+1)} : output */
  config_param *config_coarse)
{
  mtype ****in_xcoarse, ****in_xfine;
  int u,i,j,l;
  int Nifine, Njfine, Nlfine;
  int bi_fine, bj_fine, bl_fine, bi_coarse, bj_coarse, bl_coarse;

  Nifine = nfine(Nicoarse);
  Njfine = nfine(Njcoarse); 
  Nlfine = nfine(Nlcoarse);

  bi_coarse = config_coarse->borderi;
  bj_coarse = config_coarse->borderj;
  bl_coarse = config_coarse->borderl;
  bi_fine   = 2 * bi_coarse;
  bj_fine   = 2 * bj_coarse;
  bl_fine   = 2 * bl_coarse;
  
  in_xcoarse = multialloc(sizeof(mtype), 4, 2, 
                  Nicoarse-2*bi_coarse, Njcoarse-2*bj_coarse, Nlcoarse-2*bl_coarse);
  in_xfine   = multialloc(sizeof(mtype), 4, 2, 
                  Nifine-2*bi_fine, Njfine-2*bj_fine, Nlfine-2*bl_fine);

  for (u=0; u<2; u++)
  for (i=0; i<Nicoarse-2*bi_coarse; i++)
  for (j=0; j<Njcoarse-2*bj_coarse; j++)
  for (l=0; l<Nlcoarse-2*bl_coarse; l++) 
    in_xcoarse[u][i][j][l] = xcoarse[u][i+bi_coarse][j+bj_coarse][l+bl_coarse];

  interpolatex(in_xcoarse, Nicoarse-2*bi_coarse, 
               Njcoarse-2*bj_coarse, Nlcoarse-2*bl_coarse, in_xfine);  

  for (u=0; u<2; u++)
  for (i=0; i<Nifine; i++)
  for (j=0; j<Njfine; j++)
  for (l=0; l<Nlfine; l++) 
    xfine[u][i][j][l] = xcoarse[u][0][0][0];

  for (u=0; u<2; u++)
  for (i=0; i<Nifine-2*bi_fine; i++)
  for (j=0; j<Njfine-2*bj_fine; j++)
  for (l=0; l<Nlfine-2*bl_fine; l++) 
    xfine[u][i+bi_fine][j+bj_fine][l+bl_fine] = in_xfine[u][i][j][l];

  multifree(in_xcoarse, 4);
  multifree(in_xfine, 4);

  return 0;
}

 
