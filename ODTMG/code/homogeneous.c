#include <stdio.h>
#include <math.h>
#include "defs.h"

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
  double dwdx[2][2])        /* dwdx[u][c] */
{
  int u,k,m,s,S;
  double temp1r, temp1i, temp2r, temp2i, temp3r, temp3i;
  double temp4r, temp4i, temp5r[2], temp5i[2];
  double a[2][2],b,c[2],d[2];
 
  S = physparam->S;
  a[0][0]=0; a[0][1]=0; a[1][0]=0; a[1][1]=0;
  b=0; c[0]=0; c[1]=0; d[0]=0; d[1]=0;
 
  for (s=0; s<S; s++) {
    k = findk(physparam, s);
    m = findm(physparam, s);
 
    temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp2r = cplxmultr(temp1r, temp1i, physparam->wgtr, physparam->wgti);
    temp2i = cplxmulti(temp1r, temp1i, physparam->wgtr, physparam->wgti);
    temp3r = cplxmultr(temp2r, temp2i, y[s][0], y[s][1]);
    temp3i = cplxmulti(temp2r, temp2i, y[s][0], y[s][1]);
    temp4r = cplxmultr(temp2r, temp2i, fx[s][0], fx[s][1]);
    temp4i = cplxmulti(temp2r, temp2i, fx[s][0], fx[s][1]);
    for (u=0; u<2; u++) {
      temp5r[u] = cplxmultr(temp2r, temp2i, SumAt[u][s][0], SumAt[u][s][1]);
      temp5i[u] = cplxmulti(temp2r, temp2i, SumAt[u][s][0], SumAt[u][s][1]);
    }
 
    for (u=0; u<2; u++) {
      a[u][0] += cplxmultr(temp3r, temp3i, temp5r[u], -temp5i[u]) * lambda[s];
      a[u][1] += cplxmulti(temp3r, temp3i, temp5r[u], -temp5i[u]) * lambda[s];
      d[u] += 2 * cplxmultr(temp4r, -temp4i, temp5r[u], temp5i[u]) * lambda[s];
    }
    b += AbsSquare(temp4r, temp4i) * lambda[s];
    c[0] += cplxmultr(temp3r, temp3i, temp4r, -temp4i) * lambda[s];
    c[1] += cplxmulti(temp3r, temp3i, temp4r, -temp4i) * lambda[s];
  }
 
  for (u=0; u<2; u++) {
    dwdx[u][0] = (a[u][0]*b-c[0]*d[u])/(b*b);
    dwdx[u][1] = (a[u][1]*b-c[1]*d[u])/(b*b);
  }                                        
 
  return 0;
}    


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
  double dCdx[2])
{
  int u,i,j,l,k,m,s,c;
  int Ni,Nj,Nl,S;
  double temp1r, temp1i, temp2r, temp2i, temp3r, temp3i; 
  double temp4r, temp4i, temp5r, temp5i, temp6r[2], temp6i[2];
  double d[2][2], dwdmua[2][2];
  mtype ***SumAt, *****At;

  Ni = physparam->Ni;
  Nj = physparam->Nj;
  Nl = physparam->Nl;
  S  = physparam->S;

  At = multialloc(sizeof(mtype), 5, 2, Ni, Nj, Nl, 2);
  SumAt = multialloc(sizeof(double), 3, 2, S, 2); 

  d[0][0] = 0;   d[0][1] = 0;
  d[1][0] = 0;   d[1][1] = 0;

  for (s=0; s<S; s++) {
    k = findk(physparam, s);
    m = findm(physparam, s);

    calc_frechet_row(s, phi, green, x, srcparam, detparam, physparam, At);
    
    for(u=0; u<2; u++)
    for(c=0; c<2; c++) 
      SumAt[u][s][c] = 0.0;

    for(u=0; u<2 ; u++)
    for(i=0; i<Ni; i++)
    for(j=0; j<Nj; j++)
    for(l=0; l<Nl; l++)
    for(c=0; c<2 ; c++) 
      SumAt[u][s][c] += At[u][i][j][l][c];  
  }

  calc_dwdx(y, fx, lambda, SumAt, physparam, srcparam, detparam, config, dwdmua); 

  for (s=0; s<S; s++) {
    k = findk(physparam, s);
    m = findm(physparam, s);

    temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp2r = cplxmultr(temp1r, temp1i, physparam->wgtr, physparam->wgti);
    temp2i = cplxmulti(temp1r, temp1i, physparam->wgtr, physparam->wgti);
    temp3r = cplxmultr(temp2r, temp2i, fx[s][0], fx[s][1]);
    temp3i = cplxmulti(temp2r, temp2i, fx[s][0], fx[s][1]);
    temp4r = (y[s][0]-temp3r) * lambda[s];
    temp4i = (y[s][1]-temp3i) * lambda[s];
    for (u=0; u<2; u++) {
      temp5r = cplxmultr(temp1r, temp1i, SumAt[u][s][0], SumAt[u][s][1]);
      temp5i = cplxmulti(temp1r, temp1i, SumAt[u][s][0], SumAt[u][s][1]);
      temp6r[u] = cplxmultr(dwdmua[u][0], dwdmua[u][1], temp3r, temp3i)
                 +cplxmultr(physparam->wgtr, physparam->wgti, temp5r, temp5i);
      temp6i[u] = cplxmulti(dwdmua[u][0], dwdmua[u][1], temp3r, temp3i)
                 +cplxmulti(physparam->wgtr, physparam->wgti, temp5r, temp5i);
      dCdx[u] += cplxmultr(temp4r, temp4i, temp6r[u], -temp6i[u]);
    }
  }

  dCdx[0] *= -2.0;
  dCdx[1] *= -2.0;

  multifree(At,5);
  multifree(SumAt,3);

  return 0;
}

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
  config_param *config)
{
  int s,u,i,j,l,k,m;
  int Ni,Nj,Nl,S;
  double temp1r, temp1i, temp2r, temp2i, temp3r, temp3i;
  double a[2],b[2],newa[2],newb[2],max[2],min[2],d[2]; 
  mtype alphaa, alphab; 
  mtype ****xtemp, *lambdatemp, *****phitemp, **fxtemp, *****At;
  int flag;
  
  max[0] = 0.1;     min[0] = 0.001;  
  max[1] = 0.1;     min[1] = 0.001;  

  Ni = physparam->Ni;
  Nj = physparam->Nj;
  Nl = physparam->Nl;
  S  = physparam->S;

  lambdatemp = (mtype *) malloc(sizeof(mtype) * S);
  xtemp = multialloc(sizeof(mtype), 4, 2, Ni, Nj, Nl);
  phitemp = multialloc(sizeof(mtype), 5, physparam->K, Ni, Nj, Nl, 2);
  fxtemp = multialloc(sizeof(mtype), 2, physparam->S, 2);
  At = multialloc(sizeof(mtype), 5, 2, Ni, Nj, Nl, 2);

  for(u=0; u<2; u++) 
  for(i=0; i<Ni; i++)
  for(j=0; j<Nj; j++)
  for(l=0; l<Nl; l++) 
    xtemp[u][i][j][l] = x[u][i][j][l]; 

  calc_direction(xtemp, y, fx, phi, green, lambda, 
                 physparam, srcparam, detparam, config, d);

  /* Calculate the search range. */
  a[0] = xtemp[0][(int)(Ni/2)][(int)(Nj/2)][(int)(Nl/2)]; 
  a[1] = xtemp[1][(int)(Ni/2)][(int)(Nj/2)][(int)(Nl/2)]; 

  if (d[0]>0 && d[1]>0) {
    if ((min[1]-a[1])*d[0]/d[1]+a[0]>=0) {
      b[0] = (min[1]-a[1])*d[0]/d[1]+a[0];
      b[1] = min[1];
    }
    else {
      b[0] = min[0];
      b[1] = (min[0]-a[0])*d[1]/d[0]+a[1];
    }
  }
  else if (d[0]>0 && d[1]<0) {
    if ((min[0]-a[0])*d[1]/d[0]+a[1]<=1) {
      b[0] = min[0];
      b[1] = (min[0]-a[0])*d[1]/d[0]+a[1];
    }
    else {
      b[0] = (max[1]-a[1])*d[0]/d[1]+a[0];
      b[1] = max[1];
    }
  }
  else if (d[0]<0 && d[1]>0) {
    if ((min[1]-a[1])*d[0]/d[1]+a[0]<=1) {
      b[0] = (min[1]-a[1])*d[0]/d[1]+a[0];
      b[1] = min[1];
    }
    else {
      b[0] = max[0];
      b[1] = (max[0]-a[0])*d[1]/d[0]+a[1];
    }
  }
  else if (d[0]<0 && d[1]<0) {
    if ((max[0]-a[0])*d[1]/d[0]+a[1]<=1) {
      b[0] = max[0];
      b[1] = (max[0]-a[0])*d[1]/d[0]+a[1];
    }
    else {
      b[0] = (max[1]-a[1])*d[0]/d[1]+a[0];
      b[1] = max[1];
    }
  }
  else if (d[0]==0 && d[1]>0) {
    b[0] = a[0]; 
    b[1] = min[1];
  }
  else if (d[0]==0 && d[1]<0) {
    b[0] = a[0]; 
    b[1] = max[1];
  }
  else if (d[0]>0 && d[1]==0) {
    b[0] = min[0]; 
    b[1] = a[1];
  }
  else if (d[0]<0 && d[1]==0) {
    b[0] = max[0]; 
    b[1] = a[1];
  }
  else if (d[0]==0 && d[1]==0) {
    b[0] = a[0];      
    b[1] = a[1];
  }

  flag = 0;    
  
  fprintf(stderr,"Before: a: %f %f  b: %f %f  d: %f %f\n", 
          a[0], a[1], b[0], b[1], d[0], d[1]);

  /* Iterations */

  while ( ((a[0]-b[0])*(a[0]-b[0])+(a[1]-b[1])*(a[1]-b[1])) > 0.0000002) 
  {
    if (flag==0) {
      newa[0] = a[0] + (b[0]-a[0]) * 0.382;
      newa[1] = a[1] + (b[1]-a[1]) * 0.382;
      newb[0] = a[0] + (b[0]-a[0]) * 0.618;
      newb[1] = a[1] + (b[1]-a[1]) * 0.618;
  
      for(u=0; u<2 ; u++)
      for(i=0; i<Ni; i++)
      for(j=0; j<Nj; j++)
      for(l=0; l<Nl; l++) 
        xtemp[u][i][j][l] = newa[u];  
         
      calc_phi(srcparam, detparam, xtemp, physparam, phitemp, fxtemp);
      calc_lambda(y, fxtemp, physparam, srcparam, detparam, lambdatemp, &alphaa);
      global_weight_calibrate(xtemp, y, fxtemp, lambdatemp, srcparam, detparam, physparam);
      calc_lambda(y, fxtemp, physparam, srcparam, detparam, lambdatemp, &alphaa);

      for(u=0; u<2 ; u++)
      for(i=0; i<Ni; i++)
      for(j=0; j<Nj; j++)
      for(l=0; l<Nl; l++) 
        xtemp[u][i][j][l] = newb[u];  
       
      calc_phi(srcparam, detparam, xtemp, physparam, phitemp, fxtemp);
      calc_lambda(y, fxtemp, physparam, srcparam, detparam, lambdatemp, &alphab);
      global_weight_calibrate(xtemp, y, fxtemp, lambdatemp, srcparam, detparam, physparam);
      calc_lambda(y, fxtemp, physparam, srcparam, detparam, lambdatemp, &alphab);
    }
    else if (flag==1) {
      newa[0] = newb[0];
      newa[1] = newb[1];
      newb[0] = a[0] + (b[0]-a[0]) * 0.618;
      newb[1] = a[1] + (b[1]-a[1]) * 0.618;
      alphaa = alphab;

      for(u=0; u<2 ; u++)
      for(i=0; i<Ni; i++)
      for(j=0; j<Nj; j++)
      for(l=0; l<Nl; l++) 
        xtemp[u][i][j][l] = newb[u];  
   
      calc_phi(srcparam, detparam, xtemp, physparam, phitemp, fxtemp);
      calc_lambda(y, fxtemp, physparam, srcparam, detparam, lambdatemp, &alphab);
      global_weight_calibrate(xtemp, y, fxtemp, lambdatemp, srcparam, detparam, physparam);
      calc_lambda(y, fxtemp, physparam, srcparam, detparam, lambdatemp, &alphab);
    }
    else if (flag == -1) { 
      newb[0] = newa[0];
      newb[1] = newa[1];
      newa[0] = a[0] + (b[0]-a[0]) * 0.382;
      newa[1] = a[1] + (b[1]-a[1]) * 0.382;
      alphab = alphaa;

      for(u=0; u<2 ; u++)
      for(i=0; i<Ni; i++)
      for(j=0; j<Nj; j++)
      for(l=0; l<Nl; l++) 
        xtemp[u][i][j][l] = newa[u];  
     
      calc_phi(srcparam, detparam, xtemp, physparam, phitemp, fxtemp);
      calc_lambda(y, fxtemp, physparam, srcparam, detparam, lambdatemp, &alphaa);
      global_weight_calibrate(xtemp, y, fxtemp, lambdatemp, srcparam, detparam, physparam);
      calc_lambda(y, fxtemp, physparam, srcparam, detparam, lambdatemp, &alphaa);
    } 

    fprintf(stderr, "1 %d  %f %f %f %f =>  %f %f %f %f  :  %f %f   %f %f \n", 
            u,a[0],a[1],b[0],b[1],newa[0],newa[1],newb[0],newb[1], 
            alphaa, alphab, xtemp[0][8][8][8], xtemp[1][8][8][8]); 

    if (alphaa>alphab) {
      a[0] = newa[0];
      a[1] = newa[1];
      flag = 1;
    }
    else { 
      b[0] = newb[0];
      b[1] = newb[1];
      flag = -1;
    }
 /* 
    for(u=0; u<2 ; u++)
    for(i=0; i<Ni; i++)
    for(j=0; j<Nj; j++)
    for(l=0; l<Nl; l++) 
      xtemp[u][i][j][l] = (a[u]+b[u])/2.0; 
  
    calc_phi(srcparam, detparam, xtemp, physparam, phitemp, fxtemp);
    calc_lambda(y, fxtemp, physparam, srcparam, detparam, lambdatemp, &alphaa);
    global_weight_calibrate(xtemp, y, fxtemp, lambda, srcparam, detparam, physparam);

    fprintf(stderr, "2 %d  %f %f %f %f =>  %f %f %f %f  :  %f %f   %f %f\n", 
            u,a[0],a[1],b[0],b[1],newa[0],newa[1],newb[0],newb[1], 
            alphaa, alphab, xtemp[0][8][8][8], xtemp[1][8][8][8]); 
  */
  }

  for (u=0; u<2;  u++)
  for (i=0; i<Ni; i++)
  for (j=0; j<Nj; j++)
  for (l=0; l<Nl; l++) 
    xtemp[u][i][j][l] = (a[u]+b[u]) / 2.0; 

  for (s=0; s<physparam->S; s++) {
    calc_frechet_row(s, phi, green, x, srcparam, detparam, physparam, At);
    k = findk(physparam, s);
    m = findm(physparam, s);
    temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp2r = cplxmultr(temp1r, temp1i, physparam->wgtr, physparam->wgti);
    temp2i = cplxmulti(temp1r, temp1i, physparam->wgtr, physparam->wgti);

    for (u=0; u<2;  u++)
    for (i=0; i<Ni; i++)
    for (j=0; j<Nj; j++)
    for (l=0; l<Nl; l++) {
      temp3r = cplxmultr(At[u][i][j][l][0], At[u][i][j][l][1], temp2r, temp2i);
      temp3i = cplxmulti(At[u][i][j][l][0], At[u][i][j][l][1], temp2r, temp2i);

      yerror[s][0] -= temp3r * ( xtemp[u][i][j][l] - x[u][i][j][l] );
      yerror[s][1] -= temp3i * ( xtemp[u][i][j][l] - x[u][i][j][l] );
    }
  }

  for (u=0; u<2;  u++)
  for (i=0; i<Ni; i++)
  for (j=0; j<Nj; j++)
  for (l=0; l<Nl; l++) 
    x[u][i][j][l] = xtemp[u][i][j][l]; 

  free(lambdatemp);
  multifree(phitemp,5);
  multifree(xtemp,4);
  multifree(fxtemp,2);
  multifree(At,5);
}



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
  config_param *config)
{
  int s,u,i,j,l,k,m;
  int Ni,Nj,Nl,S;
  double max[2], min[2]; 
  double temp1r, temp1i, temp2r, temp2i, temp3r, temp3i;
  double a[2],b[2],newa,newb,olda[2],oldb[2];
  mtype alphaa, alphab; 
  mtype ****xtemp, *lambdatemp, *****phitemp, **fx, *****At;
  int flag;
  
  max[0] = 0.1;     min[0] = 0.001;  
  max[1] = 0.1;     min[1] = 0.001;  

  Ni = physparam->Ni;
  Nj = physparam->Nj;
  Nl = physparam->Nl;
  S  = physparam->S;

  lambdatemp = (mtype *) malloc(sizeof(mtype) * S);
  xtemp = multialloc(sizeof(mtype), 4, 2, Ni, Nj, Nl);
  phitemp = multialloc(sizeof(mtype), 5, physparam->K, Ni, Nj, Nl, 2);
  fx = multialloc(sizeof(mtype), 2, physparam->S, 2);
  At = multialloc(sizeof(mtype), 5, 2, Ni, Nj, Nl, 2);

  for (u=0; u<2; u++) {
    olda[u] = 1.0;   a[u] = 0.0;
    oldb[u] = 1.0;   b[u] = 0.0; 

    for(i=0; i<Ni; i++)
    for(j=0; j<Nj; j++)
    for(l=0; l<Nl; l++) 
      xtemp[u][i][j][l] = x[u][(int)(Ni/2)][(int)(Nj/2)][(int)(Nl/2)]; 
  }

  while ( ((olda[0]+oldb[0]-a[0]-b[0])*(olda[0]+oldb[0]-a[0]-b[0])+
           (olda[1]+oldb[1]-a[1]-b[1])*(olda[1]+oldb[1]-a[1]-b[1])) > 0.00004) 
  {
    olda[0] = a[0];  oldb[0] = b[0];
    olda[1] = a[1];  oldb[1] = b[1];

    for (u=0; u<2; u++) {
      fprintf(stderr, "DEBUG1   u = %d \n", u);

      a[0] = min[0];   b[0] = max[0];
      a[1] = min[1];   b[1] = max[1];
      flag = 0;    

      while (fabs(b[u]-a[u])>0.003) { 
        if (flag==0) {
          newa = a[u] + (b[u]-a[u]) * 0.382;
          newb = a[u] + (b[u]-a[u]) * 0.618;
  
          for(i=0; i<Ni; i++)
          for(j=0; j<Nj; j++)
          for(l=0; l<Nl; l++) 
            xtemp[u][i][j][l] = newa;  
         
          calc_phi(srcparam, detparam, xtemp, physparam, phitemp, fx);
          calc_lambda(y, fx, physparam, srcparam, detparam, lambdatemp, &alphaa);

          for(i=0; i<Ni; i++)
          for(j=0; j<Nj; j++)
          for(l=0; l<Nl; l++) 
            xtemp[u][i][j][l] = newb;  
       
          calc_phi(srcparam, detparam, xtemp, physparam, phitemp, fx);
          calc_lambda(y, fx, physparam, srcparam, detparam, lambdatemp, &alphab);
        }
        else if (flag ==1) {
          newa = newb;
          newb = a[u] + (b[u]-a[u]) * 0.618;
          alphaa = alphab;

          for(i=0; i<Ni; i++)
          for(j=0; j<Nj; j++)
          for(l=0; l<Nl; l++) 
            xtemp[u][i][j][l] = newb;  
       
          calc_phi(srcparam, detparam, xtemp, physparam, phitemp, fx);
          calc_lambda(y, fx, physparam, srcparam, detparam, lambdatemp, &alphab);
        }
        else if (flag == -1) { 
          newb = newa;
          newa = a[u] + (b[u]-a[u]) * 0.382;
          alphab = alphaa;

          for(i=0; i<Ni; i++)
          for(j=0; j<Nj; j++)
          for(l=0; l<Nl; l++) 
            xtemp[u][i][j][l] = newa;  
         
          calc_phi(srcparam, detparam, xtemp, physparam, phitemp, fx);
          calc_lambda(y, fx, physparam, srcparam, detparam, lambdatemp, &alphaa);
        } 

        fprintf(stderr, "%d  %f %f   %f %f   %f %f   %f %f\n", 
                u, a[u], b[u], newa, newb, alphaa, alphab, xtemp[0][8][8][8], xtemp[1][8][8][8]); 

        if (alphaa>alphab) {
          a[u] = newa;
          flag = 1;
        }
        else { 
          b[u] = newb;
          flag = -1;
        }
      }  
      
      for(i=0; i<Ni; i++)
      for(j=0; j<Nj; j++)
      for(l=0; l<Nl; l++) {
        xtemp[u][i][j][l] = (a[u]+b[u])/2.0; 
      }

      fprintf(stderr, "\n%d  %f %f   %f %f   %f %f  %f %f\n\n", 
              u, a[u], b[u], newa, newb, alphaa, alphab, xtemp[0][8][8][8], xtemp[1][8][8][8]); 
    }    
  }     

  for (s=0; s<physparam->S; s++) {
    calc_frechet_row(s, phi, green, x, srcparam, detparam, physparam, At);
    k = findk(physparam, s);
    m = findm(physparam, s);
    temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp2r = cplxmultr(temp1r, temp1i, physparam->wgtr, physparam->wgti);
    temp2i = cplxmulti(temp1r, temp1i, physparam->wgtr, physparam->wgti);

    for (u=0; u<2;  u++)
    for (i=0; i<Ni; i++)
    for (j=0; j<Nj; j++)
    for (l=0; l<Nl; l++) {
      temp3r = cplxmultr(At[u][i][j][l][0], At[u][i][j][l][1], temp2r, temp2i);
      temp3i = cplxmulti(At[u][i][j][l][0], At[u][i][j][l][1], temp2r, temp2i);

      yerror[s][0] -= temp3r * ( xtemp[u][i][j][l] - x[u][i][j][l] );
      yerror[s][1] -= temp3i * ( xtemp[u][i][j][l] - x[u][i][j][l] );
    }
  }

  for (u=0; u<2;  u++)
  for (i=0; i<Ni; i++)
  for (j=0; j<Nj; j++)
  for (l=0; l<Nl; l++) 
    x[u][i][j][l] = xtemp[u][i][j][l]; 

  free(lambdatemp);
  multifree(phitemp,5);
  multifree(xtemp,4);
  multifree(fx,2);
  multifree(At,5);
}



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
  config_param *config)
{
  int s,u,i,j,l,c,k,m;
  int Ni,Nj,Nl,S;
  mtype *****At;
  double ***SumAt;    /* SumAt[u][s][c] */ 
  double a,b,cc,d,e,f;
  double mu[2], dmu[2]; 
  double determinant;
  double temp1r, temp1i, temp2r, temp2i, temp3r, temp3i, temp4r, temp4i;
/* Milstein - DEBUG */
  double eig1, eig2;
  FILE *fpresult;
  char filename[255];
/* Milstein - DEBUG */
                                   
  
  Ni=physparam->Ni;
  Nj=physparam->Nj;
  Nl=physparam->Nl;
  S =physparam->S;
  
  At = multialloc(sizeof(mtype), 5, 2, Ni, Nj, Nl, 2);
  SumAt = multialloc(sizeof(double), 3, 2, S, 2); 

  for(s=0; s<S; s++) {
    calc_frechet_row(s, phi, green, x, srcparam, detparam, physparam, At);
    
    for(u=0; u<2; u++)
    for(c=0; c<2; c++) {
      SumAt[u][s][c] = 0.0;
    }

    for(u=0; u<2 ; u++)
    for(i=0; i<Ni; i++)
    for(j=0; j<Nj; j++)
    for(l=0; l<Nl; l++)
    for(c=0; c<2 ; c++) {
      SumAt[u][s][c] += At[u][i][j][l][c];  
    }
  } 

  a = 0.0;  b = 0.0;  cc= 0.0;
  d = 0.0;  e = 0.0;  f = 0.0;

  for (s=0; s<S; s++) {
    k = findk(physparam, s);
    m = findm(physparam, s);
    temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp2r = cplxmultr(temp1r, temp1i, physparam->wgtr, physparam->wgti);
    temp2i = cplxmulti(temp1r, temp1i, physparam->wgtr, physparam->wgti);
    temp3r = cplxmultr(SumAt[0][s][0], SumAt[0][s][1], temp2r, temp2i);
    temp3i = cplxmulti(SumAt[0][s][0], SumAt[0][s][1], temp2r, temp2i);
    temp4r = cplxmultr(SumAt[1][s][0], SumAt[1][s][1], temp2r, temp2i);
    temp4i = cplxmulti(SumAt[1][s][0], SumAt[1][s][1], temp2r, temp2i);
 
    a += AbsSquare(temp3r, temp3i) * lambda[s];
    b += AbsSquare(temp4r, temp4i) * lambda[s];
    cc+= cplxmultr(temp3r, -temp3i, temp4r, temp4i) * lambda[s] * 2.0;
    d -= cplxmultr(temp3r, -temp3i, yerror[s][0], yerror[s][1]) * lambda[s] * 2.0;
    e -= cplxmultr(temp4r, -temp4i, yerror[s][0], yerror[s][1]) * lambda[s] * 2.0;
    f += AbsSquare(yerror[s][0], yerror[s][1]) * lambda[s];
  } 

 /* Milstein - DEBUG  - observe eigenvalues of hessian*
 
  eig1= (b+a)+sqrt((b-a)*(b-a)+cc*cc);
  eig2= (b+a)-sqrt((b-a)*(b-a)+cc*cc);
 
  sprintf(filename, "%s/RESULT",config->resultpath);
  fpresult = fopen(filename, "a");
  fprintf(fpresult, "%e %e\n", eig1, eig2);
  fclose(fpresult);

 * Milstein - end DEBUG  - observe eigenvalues of hessian*/                

  mu[0] = x[0][(int)(Ni/2)][(int)(Nj/2)][(int)(Nl/2)];
  mu[1] = x[1][(int)(Ni/2)][(int)(Nj/2)][(int)(Nl/2)];

  if (config->mua_flag || config->D_flag) {   
    determinant = 4*a*b-cc*cc;
    dmu[0] = - (2*b*d - cc *e)/determinant;
    dmu[1] = - (-cc*d + 2*a*e)/determinant;
  }
  else if (config->mua_flag || !config->D_flag) {    
    dmu[0] = - d / 2. / a;
    dmu[1] = 0;
  }
  else if (!config->mua_flag || config->D_flag) {        
    dmu[0] = 0.0;
    dmu[1] = - e / 2. / b;
  }
  else {
    fprintf(stderr,"Error! Both mua_flag and D_flag are 0!!!\n");
    exit(1);
  }

/* reduce step size 
  dmu[0] /= 4.0;
  dmu[1] /= 4.0;
*/

/* Milstein - DEBUG - step size *
  dmu_mag=sqrt(dmu[0]*dmu[0]+dmu[1]*dmu[1]);
  if(dmu_mag > .003){
    dmu[0]=dmu[0]/dmu_mag*.003;
    dmu[1]=dmu[1]/dmu_mag*.003;
  }
* Milstein - DEBUG - step size */  


  for (s=0; s<physparam->S; s++) {
    calc_frechet_row(s, phi, green, x, srcparam, detparam, physparam, At);
    k = findk(physparam, s);
    m = findm(physparam, s);
    temp1r = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp1i = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                       detparam[m].calir, detparam[m].calii);
    temp2r = cplxmultr(temp1r, temp1i, physparam->wgtr, physparam->wgti);
    temp2i = cplxmulti(temp1r, temp1i, physparam->wgtr, physparam->wgti);

    for (u=0; u<2;  u++)
    for (i=0; i<Ni; i++)
    for (j=0; j<Nj; j++)
    for (l=0; l<Nl; l++) {
      temp3r = cplxmultr(At[u][i][j][l][0], At[u][i][j][l][1], temp2r, temp2i);
      temp3i = cplxmulti(At[u][i][j][l][0], At[u][i][j][l][1], temp2r, temp2i);

      if (mu[u] + dmu[u]>0) { 
        yerror[s][0] -= temp3r * dmu[u];
        yerror[s][1] -= temp3i * dmu[u];
      }
      else {
        yerror[s][0] -= temp3r * (0.0001-x[u][i][j][l]);
        yerror[s][1] -= temp3i * (0.0001-x[u][i][j][l]);
      }
    }
  }

  for (u=0; u<2;  u++)
  for (i=0; i<Ni; i++)
  for (j=0; j<Nj; j++)
  for (l=0; l<Nl; l++) {
    if (mu[u] + dmu[u]>0) 
      x[u][i][j][l] = mu[u] + dmu[u]; 
    else 
      x[u][i][j][l] = 0.0001;
  }

/*
  fprintf(stderr, "%f  %f  %f  %f  %f  %f\n", a,b,cc,d,e,f);
  fprintf(stderr, "%1.7f  %1.7f  %1.7f  %1.7f  %f \n", mua, mua+dmuahat, D, D+dDhat,determinant);
*/
  multifree(At, 5);
  multifree(SumAt, 3);
}                              
