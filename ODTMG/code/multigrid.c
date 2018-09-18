#include <stdio.h>
#include <math.h>
#include "defs.h"

/*   You can change the inversion method (e.g. fixed-grid only, 
     2 level multigrid, 3 level multigrid, adaptive 3 level 
     multigrid, ¡¦) by commenting or removing commenting 
     appropriate parts in the multigrid_main() in this file.
     You might want to build your own recursion by using 
     multigrid_update() or adaptive_multigrid_update() as a 
     LEGO blocks.
 */

float deltac[5];             
float max_deltac[5];         
float last_deltac[5];        
float average_deltac[5];        
float computation[2][5]      /* [x or r][h]    */
      = { {1.0,  0.125,    0.015625,   0.0019953125,  2.44140625e-4},  
          {0.81, 0.100125, 0.01265625, 0.00158203125, 1.9775390625e-4} }; 


int escape_test(
  int h,		
  int iter,
  int n,
  int nu,
  int h_next,
  char *resultpath
)
{
  int status;
  FILE *fpresult;
  char filename[255];	  
	
  if ((deltac[h] < 0.05 * max_deltac[h]))
    status=1;	 
  else if ((n>0) && (deltac[h]/computation[0][h] < last_deltac[h_next]/computation[0][h_next])) 
/*  else if ((n>0) && (deltac[h]/computation[0][h] < average_deltac[h_next]/computation[0][h_next]))  */
    status=2;
  else if (n>=nu)
    status=3; 	  
  /*else if (h==0) ||  
    status=5;  */ 
  else 
    status= 0;	  

  sprintf(filename, "%s/RESULT",resultpath);
  fpresult = fopen(filename, "a");
  fprintf(fpresult, "%1d   ", status); 
  fclose(fpresult);

  return(status);
}




int set_config_scale(
  config_param *config,
  int hold,
  int hnew
)
{
  int h;

  if (hold<hnew) {
    for(h=hold; h<hnew; h++) {
      config->borderi /= 2;
      config->borderj /= 2;
      config->borderl /= 2;
    } 
  }

  if (hold>hnew) {
    for(h=hold; h>hnew; h--) {
      config->borderi *= 2;
      config->borderj *= 2;
      config->borderl *= 2;
    } 
  }

  return 0; 
}


int set_params_scale(
  config_param *config,
  phys_param *physparam,
  prior_param *prior_mua,
  prior_param *prior_D,
  int hold,
  int hnew
)
{
  int h;

  if (hold<hnew) {
    for(h=hold; h<hnew; h++) {
      physparam->Ni = ncoarse(physparam->Ni);
      physparam->Nj = ncoarse(physparam->Nj);
      physparam->Nl = ncoarse(physparam->Nl);
    } 
  }

  if (hold>hnew) {
    for(h=hold; h>hnew; h--) {
      physparam->Ni = nfine(physparam->Ni);
      physparam->Nj = nfine(physparam->Nj);
      physparam->Nl = nfine(physparam->Nl);
    } 
  }

  prior_mua->sigma *= pow(2.0, (hnew-hold)*(1.0-3.0/prior_mua->p));
  prior_D->sigma   *= pow(2.0, (hnew-hold)*(1.0-3.0/prior_D->p));

  set_config_scale(config, hold, hnew);

  return 0; 
}


/* Coarse Grid Correction :
 *       x = max{0, x+interpolate(x(h+1)-x_dec)}
 */
int coarse_correction(
  int h,
  mtype ****xh,      /* input and output */
  int Ni,            /* Ni for xh */
  int Nj,            /* Nj for xh */
  int Nl,            /* Nl for xh */
  mtype ****xhplus1,
  config_param *config)
{
  mtype ****xdec, ****dxdec, ****dx;
  int u,i,j,l;
  int Nicoarse, Njcoarse, Nlcoarse;

  Nicoarse = ncoarse(Ni); 
  Njcoarse = ncoarse(Nj); 
  Nlcoarse = ncoarse(Nl);

  xdec  = multialloc(sizeof(mtype), 4, 2, Nicoarse, Njcoarse, Nlcoarse);
  dxdec = multialloc(sizeof(mtype), 4, 2, Nicoarse, Njcoarse, Nlcoarse);
  dx    = multialloc(sizeof(mtype), 4, 2, Ni, Nj, Nl);

  decimator(xh, Ni, Nj, Nl, xdec, config);

  for(u=0; u<2; u++)
  for(i=0; i<Nicoarse; i++)
  for(j=0; j<Njcoarse; j++)
  for(l=0; l<Nlcoarse; l++) {
    dxdec[u][i][j][l] = xhplus1[u][i][j][l] - xdec[u][i][j][l];
  }
 
  set_config_scale(config, h, h+1);
  interpolator(dxdec, Nicoarse, Njcoarse, Nlcoarse, dx, config);   
  set_config_scale(config, h+1, h);

  for(u=0; u<2;  u++)
  for(i=0; i<Ni; i++)
  for(j=0; j<Nj; j++)
  for(l=0; l<Nl; l++) {
    xh[u][i][j][l] += dx[u][i][j][l];
    if (xh[u][i][j][l] < 1e-20)
      xh[u][i][j][l] = 1e-20;
  }

  multifree(dxdec, 4);
  multifree(dx, 4);

  return 0;
}

 
double calc_rx(
  mtype ****r,
  mtype ****x,
  phys_param *physparam
)
{
  double rx = 0.0;
  int u,i,j,l;

  for(u=0; u<2; u++)
  for(i=0; i<physparam->Ni; i++)
  for(j=0; j<physparam->Nj; j++)
  for(l=0; l<physparam->Nl; l++)
    rx += r[u][i][j][l] * x[u][i][j][l];

  return(rx);
}




mtype calc_gradc_prior_pixel(
  int u, int i, int j, int l, 
  mtype ****x,
  phys_param *physparam,       
  prior_param *priorparam,     
  config_param *config)
{
  int n;
  mtype gradc_prior, *neighbor;

  neighbor = (mtype *) malloc(sizeof(mtype)*priorparam->Nneighbor);
  get_neighbor(u, i, j, l, priorparam, x, neighbor, physparam, config);
 
  gradc_prior = 0.0;

  for (n=0; n<priorparam->Nneighbor; n++)
    gradc_prior += priorparam->b[n]
                   * pow( fabs(x[u][i][j][l]-neighbor[n]), priorparam->p-1 ) 
                   * SG(x[u][i][j][l], neighbor[n]);

  gradc_prior /= pow(priorparam->sigma, priorparam->p);

  free(neighbor);

  return gradc_prior;
}


int calc_gradc_prior(
  mtype ****gradc_prior,
  mtype ****x,
  phys_param *physparam,       
  prior_param *prior_mua,     
  prior_param *prior_D,     
  config_param *config)
{
  int u,i,j,l;
  prior_param *priorparam;

  for (u=0; u<2; u++) 
  for (i=0; i<physparam->Ni; i++)
  for (j=0; j<physparam->Nj; j++)
  for (l=0; l<physparam->Nl; l++) 
      gradc_prior[u][i][j][l] = 0.0; 

  for (u=0; u<2; u++) {
    if (u==0) 
      priorparam = prior_mua;
    else 
      priorparam = prior_D;

    for (i=1; i<physparam->Ni-1; i++)
    for (j=1; j<physparam->Nj-1; j++)
    for (l=1; l<physparam->Nl-1; l++) 
      gradc_prior[u][i][j][l] 
         = calc_gradc_prior_pixel(u,i,j,l, x, physparam, priorparam, config);
  }

  return 0;
}


int calc_gradc(  
  mtype *****phi,
  mtype *****green,
  mtype ****x,
  mtype **y,
  mtype **fx,
  mtype *lambda,
  phys_param *physparam,     
  src_param  *srcparam,      /* src_param array */
  det_param  *detparam,      /* det_param array */
  prior_param *prior_mua,   
  prior_param *prior_D,    
  config_param *config,
  mtype ****gradc)
{ 
  int u,i,j,l;
  int Ni, Nj, Nl; 
  mtype **At, **yerror; 
  double theta1, theta2;

  Ni = physparam->Ni;
  Nj = physparam->Nj;
  Nl = physparam->Nl;

  At = multialloc(sizeof(mtype), 2, physparam->S, 2);
  yerror = multialloc(sizeof(mtype), 2, physparam->S, 2);

  for (u=0; u<2; u++) 
  for (i=0; i<physparam->Ni; i++)
  for (j=0; j<physparam->Nj; j++)
  for (l=0; l<physparam->Nl; l++) 
    gradc[u][i][j][l] = 0.0; 

  calc_gradc_prior(gradc, x, physparam, prior_mua, prior_D, config);  

  calc_yerror(yerror, y, fx, physparam, srcparam, detparam); 

  for (u=0; u<2; u++)
  for (i=1; i<Ni-1; i++)
  for (j=1; j<Nj-1; j++)
  for (l=1; l<Nl-1; l++) {
    calc_frechet_col(u, i, j, l, phi, green, x, srcparam, detparam, physparam, At);
    ICD_params(At, yerror, lambda, physparam, srcparam, detparam, &theta1, &theta2);
    gradc[u][i][j][l] += theta1;
  }

  multifree(At, 2);
  multifree(yerror, 2);

  return 0;
}




int multigrid_update( 
  int h,
  int h_prev,
  int h_next,
  mtype *****x,
  mtype *****r,
  mtype *****v,
  mtype **y,               
  mtype ***rfx,
  mtype ***vfx,
  mtype *lambda,
  phys_param   *physparam,  
  src_param    *srcparam,   /* src_param array */
  det_param    *detparam,   /* det_param array */
  prior_param  *prior_mua,
  prior_param  *prior_D,  
  config_param *config,
  int   nu,
  int   iter,
  int   *scale0_updated
)
{
  int S, Ni, Nj, Nl, Nicoarse, Njcoarse, Nlcoarse, Nifine, Njfine, Nlfine; 
  int u, i, j, l, n, s, c;
  mtype **fx, *****phi, *****green, ****v_finer_dec, **yerror;
  double alpha, alphaold, cost, rx; 
  FILE *fpresult, *fp;
  char filename[256], arrayname[256];
  double priorh[2];

  S  = physparam->S; 
  Ni = physparam->Ni; 
  Nj = physparam->Nj; 
  Nl = physparam->Nl; 
  Nicoarse = ncoarse(Ni);
  Njcoarse = ncoarse(Nj);
  Nlcoarse = ncoarse(Nl);
  Nifine = nfine(Ni);
  Njfine = nfine(Nj);
  Nlfine = nfine(Nl);

  yerror   = multialloc(sizeof(mtype), 2, physparam->S, 2);
  fx       = multialloc(sizeof(mtype), 2, physparam->S, 2);
  phi      = multialloc(sizeof(mtype), 5, physparam->K, Ni, Nj, Nl, 2);
  green    = multialloc(sizeof(mtype), 5, physparam->M, Ni, Nj, Nl, 2);
  v_finer_dec = multialloc(sizeof(mtype), 4, 2, Ni, Nj, Nl);

  if (h_prev == h-1) {
    set_config_scale(config,h,h-1);
    decimator(x[h-1], Nifine, Njfine, Nlfine, x[h], config); 
    set_config_scale(config,h-1,h);
  }
  else if (h_prev == h+1) {
    coarse_correction(h, x[h], Ni, Nj, Nl, x[h+1], config);
  }
  else {
    fprintf(stderr, "Invalid h_prev in multigrid_update().\n");
  } 


    if (config->mu_store_flag !=0 /* && h==0 */) {
      sprintf(filename, "%s/muhat%d%d%d_%d_%d.dat", 
              config->muhatpath, h, h_prev, h_next, 0, iter);
      sprintf(arrayname, "rec");
      fp = datOpen(filename, "w+b");
      write_float_array(fp, arrayname, &x[h][0][0][0][0], 4, 2, Ni, Nj, Nl);
      datClose(fp);
    }
  
  fprintf(stderr, "calc_phi for h=%d\n", h);
  calc_phi(srcparam, detparam, x[h], physparam, phi, fx);
  fprintf(stderr, "calc_green for h=%d\n", h);
  calc_green(srcparam, detparam, x[h], physparam, green);     

  if (h_prev==h-1) {
    for (s=0; s<S; s++)
    for (c=0; c<2; c++) 
      rfx[h][s][c] = - fx[s][c] + vfx[h-1][s][c];
  
    for (s=0; s<S; s++)
    for (c=0; c<2; c++)
      y[s][c] -= rfx[h][s][c];
  }
  else if (h_prev==h+1) {
    for (s=0; s<S; s++)
    for (c=0; c<2; c++)
      y[s][c] += rfx[h+1][s][c];
  }

  calc_yerror(yerror, y, fx, physparam, srcparam, detparam); 

  if (h==0)
    *scale0_updated = 1;

  alphaold = alpha;
  alpha = calc_alpha(y, fx, physparam, srcparam, detparam);
  if (h==0 || *scale0_updated==0 || alpha<alphaold) 
    calc_lambda_with_alpha(y, alpha, physparam, lambda); 

  if (h_prev==h-1) {
    calc_gradc(phi, green, x[h], y, fx, lambda, physparam, srcparam, detparam, 
               prior_mua, prior_D, config, r[h]);

    set_config_scale(config,h,h-1);
    interpolatortranspose(v[h-1], Nifine, Njfine, Nlfine, v_finer_dec, config); 
    set_config_scale(config,h-1,h);

    for (u=0; u<2; u++)
    for (i=0; i<Ni; i++)
    for (j=0; j<Nj; j++)
    for (l=0; l<Nl; l++)
      r[h][u][i][j][l] -= v_finer_dec[u][i][j][l]; 
  }

  rx = calc_rx(r[h], x[h], physparam);

  cost=obj_fn(physparam, prior_D, prior_mua, x[h], alpha, config);
  sprintf(filename, "%s/RESULT",config->resultpath);
  fpresult = fopen(filename, "a");
  fprintf(fpresult, "0  %3d  %3d  \t%e  \t%e\n",
          iter+1, h, cost, alpha);
  fclose(fpresult);

  for (n=0; n<nu; n++) {
    ICD_update(x[h], yerror, phi, green, y, fx, lambda, prior_D, prior_mua,
               srcparam, detparam, physparam, config, r[h]);

    if (config->mu_store_flag !=0 /* && h==0 */ ) {
      sprintf(filename, "%s/muhat%d%d%d_%d_%d.dat", 
              config->muhatpath, h, h_prev, h_next, n+1, iter);
      sprintf(arrayname, "rec");
      fp = datOpen(filename, "w+b");
      write_float_array(fp, arrayname, &x[h][0][0][0][0], 4, 2, Ni, Nj, Nl);
      datClose(fp);
    }

    if (n!=nu-1 || h_next==h+1) {
      fprintf(stderr, "calc_phi for h=%d\n", h);
      calc_phi(srcparam, detparam, x[h], physparam, phi, fx);
      fprintf(stderr, "calc_green for h=%d\n", h);
      calc_green(srcparam, detparam, x[h], physparam, green);     
      calc_yerror(yerror, y, fx, physparam, srcparam, detparam); 
    }

    alphaold = alpha;
    alpha = calc_alpha(y, fx, physparam, srcparam, detparam);
    if (h==0 || *scale0_updated==0 || alpha<alphaold) 
      calc_lambda_with_alpha(y, alpha, physparam, lambda); 
    cost = obj_fn(physparam, prior_D, prior_mua, x[h], alpha, config)
           - calc_rx(r[h], x[h], physparam) + rx ;
    sprintf(filename, "%s/RESULT",config->resultpath);
    fpresult = fopen(filename, "a");
    fprintf(fpresult, "0  %3d  %3d  \t%e  \t%e\n",
            iter+1, h, cost, alpha);
    fclose(fpresult);
  }

  if (h_next==h+1) {
    calc_gradc(phi, green, x[h], y, fx, lambda, physparam, srcparam, detparam, 
               prior_mua, prior_D, config, v[h]);

    for (u=0; u<2; u++)
    for (i=0; i<Ni; i++)
    for (j=0; j<Nj; j++)
    for (l=0; l<Nl; l++)
      v[h][u][i][j][l] -= r[h][u][i][j][l]; 

    for (s=0; s<S; s++)
    for (c=0; c<2; c++)
      vfx[h][s][c] = fx[s][c];  
  }

  multifree(yerror,2);
  multifree(fx,2);
  multifree(phi, 5);
  multifree(green, 5);
  multifree(v_finer_dec, 4);

  return 0;
}





int adaptive_multigrid_update( 
  int h,
  int h_prev,
  int h_next,
  mtype *****x,
  mtype *****r,
  mtype *****v,
  mtype **y,               
  mtype ***rfx,
  mtype ***vfx,
  mtype *lambda,
  phys_param   *physparam,  
  src_param    *srcparam,   
  det_param    *detparam,   
  prior_param  *prior_mua,
  prior_param  *prior_D,  
  config_param *config,
  int   nu,
  int   iter,
  int   *scale0_updated
)
{
  int S, Ni, Nj, Nl, Nicoarse, Njcoarse, Nlcoarse, Nifine, Njfine, Nlfine; 
  int u, i, j, l, n, s, c;
  mtype **fx, *****phi, *****green, ****v_finer_dec, **yerror;
  double alpha, alphaold, cost, costold, rx; 
  FILE *fpresult, *fp;
  char filename[256], arrayname[256];
  double priorh[2];
  double sum_deltac;


  S  = physparam->S; 
  Ni = physparam->Ni; 
  Nj = physparam->Nj; 
  Nl = physparam->Nl; 
  Nicoarse = ncoarse(Ni);
  Njcoarse = ncoarse(Nj);
  Nlcoarse = ncoarse(Nl);
  Nifine = nfine(Ni);
  Njfine = nfine(Nj);
  Nlfine = nfine(Nl);

  yerror   = multialloc(sizeof(mtype), 2, physparam->S, 2);
  fx       = multialloc(sizeof(mtype), 2, physparam->S, 2);
  phi      = multialloc(sizeof(mtype), 5, physparam->K, Ni, Nj, Nl, 2);
  green    = multialloc(sizeof(mtype), 5, physparam->M, Ni, Nj, Nl, 2);
  v_finer_dec = multialloc(sizeof(mtype), 4, 2, Ni, Nj, Nl);

  if (h_prev == h-1) {
    set_config_scale(config,h,h-1);
    decimator(x[h-1], Nifine, Njfine, Nlfine, x[h], config); 
    set_config_scale(config,h-1,h);
  }
  else if (h_prev == h+1) {
    coarse_correction(h, x[h], Ni, Nj, Nl, x[h+1], config);
  }
  else {
    fprintf(stderr, "Invalid h_prev in multigrid_update().\n");
  } 


  if (config->mu_store_flag !=0 && h==0) {
    sprintf(filename, "%s/muhat%d%d%d_%d_%d.dat", 
            config->muhatpath, h, h_prev, h_next, iter, 0);
    sprintf(arrayname, "rec");
    fp = datOpen(filename, "w+b");
    write_float_array(fp, arrayname, &x[h][0][0][0][0], 4, 2, Ni, Nj, Nl);
    datClose(fp);
  }

  
  fprintf(stderr, "calc_phi for h=%d\n", h);
  calc_phi(srcparam, detparam, x[h], physparam, phi, fx); 
  fprintf(stderr, "calc_green for h=%d\n", h);
  calc_green(srcparam, detparam, x[h], physparam, green);     
  
  if (h_prev==h-1) {
    for (s=0; s<S; s++)
    for (c=0; c<2; c++) 
      rfx[h][s][c] = - fx[s][c] + vfx[h-1][s][c];
  
    for (s=0; s<S; s++)
    for (c=0; c<2; c++)
      y[s][c] -= rfx[h][s][c];
  }
  else if (h_prev==h+1) {
    for (s=0; s<S; s++)
    for (c=0; c<2; c++)
      y[s][c] += rfx[h+1][s][c];
  }

  calc_yerror(yerror, y, fx, physparam, srcparam, detparam); 

  if (h==0)
    *scale0_updated = 1;

  alphaold = alpha;
  alpha = calc_alpha(y, fx, physparam, srcparam, detparam);
  if (h==0 || *scale0_updated==0 || alpha<alphaold) 
    calc_lambda_with_alpha(y, alpha, physparam, lambda); 

  if (h_prev==h-1) {
    calc_gradc(phi, green, x[h], y, fx, lambda, physparam, srcparam, detparam, 
               prior_mua, prior_D, config, r[h]);

    set_config_scale(config,h,h-1);
    interpolatortranspose(v[h-1], Nifine, Njfine, Nlfine, v_finer_dec, config); 
    set_config_scale(config,h-1,h);

    for (u=0; u<2; u++)
    for (i=0; i<Ni; i++)
    for (j=0; j<Nj; j++)
    for (l=0; l<Nl; l++)
      r[h][u][i][j][l] -= v_finer_dec[u][i][j][l];  
  }

  rx = calc_rx(r[h], x[h], physparam);

  cost=obj_fn(physparam, prior_D, prior_mua, x[h], alpha, config);
  sprintf(filename, "%s/RESULT",config->resultpath);
  fpresult = fopen(filename, "a");
  fprintf(fpresult, "%3d %3d   %.5e %.5e \n", iter+1, h, cost, alpha); 
  fclose(fpresult);

  max_deltac[h] = 0; 
  deltac[h] = 0;
  sum_deltac = 0;

  
  for (n=0; escape_test(h, iter, n, nu, h_next, config->resultpath)==0; n++)  {
    costold = cost;

    ICD_update(x[h], yerror, phi, green, y, fx, lambda, prior_D, prior_mua,
               srcparam, detparam, physparam, config, r[h]);

    if (config->mu_store_flag !=0 && h==0) {
      sprintf(filename, "%s/muhat%d%d%d_%d_%d.dat", 
              config->muhatpath, h, h_prev, h_next, iter, n+1);
      sprintf(arrayname, "rec");
      fp = datOpen(filename, "w+b");
      write_float_array(fp, arrayname, &x[h][0][0][0][0], 4, 2, Ni, Nj, Nl);
      datClose(fp);
    }

    if (n!=nu-1 || h_next==h+1) {
      fprintf(stderr, "calc_phi for h=%d\n", h);
      calc_phi(srcparam, detparam, x[h], physparam, phi, fx);
      fprintf(stderr, "calc_green for h=%d\n", h);
      calc_green(srcparam, detparam, x[h], physparam, green);     
      calc_yerror(yerror, y, fx, physparam, srcparam, detparam); 
    }

    alphaold = alpha;
    alpha = calc_alpha(y, fx, physparam, srcparam, detparam);
    if (h==0 || *scale0_updated==0 || alpha<alphaold) 
      calc_lambda_with_alpha(y, alpha, physparam, lambda); 
    cost = obj_fn(physparam, prior_D, prior_mua, x[h], alpha, config)
           - calc_rx(r[h], x[h], physparam) + rx ;

    if (costold>cost)
      deltac[h] = costold-cost;

    if (n!=nu-1 || h_next==h+1) {
      sum_deltac += deltac[h];
      last_deltac[h] = deltac[h];
    }

    if (deltac[h] > max_deltac[h])
      max_deltac[h] = deltac[h]; 

    sprintf(filename, "%s/RESULT",config->resultpath);
    fpresult = fopen(filename, "a");
    fprintf(fpresult, "%3d %3d   %.5e %.5e\n", iter+1, h, cost, alpha); 
    fclose(fpresult);
  }
  
  if (n>1 || h_next==h-1) 
    average_deltac[h] = sum_deltac/(float)(n-1);
  else if (n>0 || h_next==h+1) 
    average_deltac[h] = sum_deltac/n;

  if (h_next==h+1) {
    calc_gradc(phi, green, x[h], y, fx, lambda, physparam, srcparam, detparam, 
               prior_mua, prior_D, config, v[h]);

    for (u=0; u<2; u++)
    for (i=0; i<Ni; i++)
    for (j=0; j<Nj; j++)
    for (l=0; l<Nl; l++)
      v[h][u][i][j][l] -= r[h][u][i][j][l]; 

    for (s=0; s<S; s++)
    for (c=0; c<2; c++)
      vfx[h][s][c] = fx[s][c];  
  }

  multifree(yerror,2);
  multifree(fx,2);
  multifree(phi, 5);
  multifree(green, 5);
  multifree(v_finer_dec, 4);

  return 0;
}

 

int multigrid_main(
  mtype ****x0,
  mtype **y,                   
  phys_param *physparam,      
  src_param  *srcparam,      
  det_param  *detparam,     
  prior_param *prior_mua,
  prior_param *prior_D,  
  mtype **yerror, 
  config_param *config)
{
  int Ni, Nj, Nl; 
  int u, i, j, l, s, c, iter, h, scale0_updated=0;
  mtype *****x, *****r, *****v, *lambda, sigmabkup[2]; 
  mtype ***rfx, ***vfx;
  
  int h_curr, h_prev, h_next;
  int numax[5]={ 4,10,20,40,100}; 

  FILE *fpresult;
  char filename[255];



  x = (mtype *****) malloc(sizeof(mtype ****)*(config->hmax+1));
  r = (mtype *****) malloc(sizeof(mtype ****)*(config->hmax+1));
  v = (mtype *****) malloc(sizeof(mtype ****)*(config->hmax+1));
  lambda = (mtype *) malloc(sizeof(mtype *)*(physparam->S));
  rfx = multialloc(sizeof(mtype), 3, config->hmax+1, physparam->S, 2);
  vfx = multialloc(sizeof(mtype), 3, config->hmax+1, physparam->S, 2);

  for (h=0; h<=config->hmax; h++) {
    Ni = physparam->Ni; 
    Nj = physparam->Nj; 
    Nl = physparam->Nl; 

    if (h==0) {
      x[h] = x0;
    }
    else {
      x[h] = multialloc(sizeof(mtype), 4, 2, Ni, Nj, Nl);
      set_config_scale(config, h, h-1);
      decimator(x[h-1], nfine(Ni), nfine(Nj), nfine(Nl), x[h], config); 
      set_config_scale(config, h-1, h);
    }

    r[h] = multialloc(sizeof(mtype), 4, 2, Ni, Nj, Nl);
    v[h] = multialloc(sizeof(mtype), 4, 2, Ni, Nj, Nl);

    for (u=0; u<2 ; u++)
    for (i=0; i<Ni; i++)
    for (j=0; j<Nj; j++)
    for (l=0; l<Nl; l++) {
      r[h][u][i][j][l] = 0.0;
      v[h][u][i][j][l] = 0.0;
    }

    if (h<config->hmax)
      set_params_scale(config, physparam, prior_mua, prior_D, h, h+1);
  }
  set_params_scale(config, physparam, prior_mua, prior_D, config->hmax, 0);
  Ni = physparam->Ni; 
  Nj = physparam->Nj; 
  Nl = physparam->Nl; 

  for (h=0; h<=config->hmax; h++) 
  for (s=0; s<physparam->S; s++)
  for (c=0; c<2; c++) {
    rfx[h][s][c] = 0.0;
    vfx[h][s][c] = 0.0;
  }


 if (config->hmax==0) {    /* Fixed-grid */ 
  for (iter=0; iter<config->niterations; iter++) {
    multigrid_update(0, 0, 0, x, r, v, y, rfx, vfx, lambda, physparam, srcparam, 
                     detparam, prior_mua, prior_D, config, 1, iter, &scale0_updated);
  }
 } 
 else if (config->hmax==1) {   /* 2 level adaptive multigrid */ 
  sprintf(filename, "%s/RESULT",config->resultpath);
  fpresult = fopen(filename, "a");
  fprintf(fpresult, "0  "); 
  fclose(fpresult);

  iter = 0; 
  
    adaptive_multigrid_update(0, 1, 1, x, r, v, y, rfx, vfx, lambda, physparam, srcparam, 
                     detparam, prior_mua, prior_D, config, 0, iter, &scale0_updated);
 
    set_params_scale(config, physparam, prior_mua, prior_D, 0, 1);

  for (iter=1; iter<config->niterations; iter++) {
    adaptive_multigrid_update(1, 0, 0, x, r, v, y, rfx, vfx, lambda, physparam, srcparam, 
                     detparam, prior_mua, prior_D, config, 40, iter, &scale0_updated);

    set_params_scale(config, physparam, prior_mua, prior_D, 1, 0);

    adaptive_multigrid_update(0, 1, 1, x, r, v, y, rfx, vfx, lambda, physparam, srcparam, 
                     detparam, prior_mua, prior_D, config, 20, iter, &scale0_updated);

    set_params_scale(config, physparam, prior_mua, prior_D, 0, 1);
  }
 }
 else if (config->hmax==2) {  /* 3 level adaptive multigrid */
  sprintf(filename, "%s/RESULT",config->resultpath);
  fpresult = fopen(filename, "a");
  fprintf(fpresult, "0  "); 
  fclose(fpresult);

  iter = 0; 
  
    adaptive_multigrid_update(0, 1, 1, x, r, v, y, rfx, vfx, lambda, physparam, srcparam, 
                     detparam, prior_mua, prior_D, config, 0, iter, &scale0_updated);
 
    set_params_scale(config, physparam, prior_mua, prior_D, 0, 1);

    adaptive_multigrid_update(1, 0, 2, x, r, v, y, rfx, vfx, lambda, physparam, srcparam, 
                     detparam, prior_mua, prior_D, config, 0, iter, &scale0_updated);

    set_params_scale(config, physparam, prior_mua, prior_D, 1, 2);


  for (iter=1; iter<config->niterations; iter++) {
    adaptive_multigrid_update(2, 1, 1, x, r, v, y, rfx, vfx, lambda, physparam, srcparam, 
                     detparam, prior_mua, prior_D, config, 70, iter, &scale0_updated);

    set_params_scale(config, physparam, prior_mua, prior_D, 2, 1);

    adaptive_multigrid_update(1, 2, 0, x, r, v, y, rfx, vfx, lambda, physparam, srcparam, 
                     detparam, prior_mua, prior_D, config, 30, iter, &scale0_updated);

    set_params_scale(config, physparam, prior_mua, prior_D, 1, 0);

    adaptive_multigrid_update(0, 1, 1, x, r, v, y, rfx, vfx, lambda, physparam, srcparam, 
                     detparam, prior_mua, prior_D, config, 20, iter, &scale0_updated);

    set_params_scale(config, physparam, prior_mua, prior_D, 0, 1);

    adaptive_multigrid_update(1, 0, 2, x, r, v, y, rfx, vfx, lambda, physparam, srcparam, 
                     detparam, prior_mua, prior_D, config, 30, iter, &scale0_updated);

    set_params_scale(config, physparam, prior_mua, prior_D, 1, 2);
  }
 }
 else {
    fprintf(stderr, "For more than 3 levels, add your code in multigrid_main() in multigrid.c \n");
    exit(1);
 }
  
  multifree(rfx,3);            
  multifree(vfx,3);            

  for(h=1; h<config->hmax; h++) {
    multifree(x[h],4);            
  } 
  for(h=0; h<config->hmax; h++) {
    multifree(r[h],4);            
    multifree(v[h],4);            
  } 
  free(x);
  free(r);
  free(v);
  free(lambda);

  return 0;
}
 
