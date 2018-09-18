/*
 * Compare Frechet derivative computed by Jong's algorithm
 * with the measured derivative 
 * 
 * HISTORY: 
 *
 * Seungseok Oh 
 * 10/7/2000
 *
 * Adam Milstein
 * 10/11/2000
 * Fixed sign error in Green's function.
 * Added 3 arguments to fwdsolverf_ to allow workspace
 *   size, a flag for indicating initial guess or not,
 *   and the number of desired multigrid cycles.
 *
 * 10/14/2000
 * In 3 places, I fixed it so that i goes from 1 to nnx and
 *  j goes from 1 to nny, instead of something else, which 
 *  would be wrong.  This slipped by us before because nnx 
 *  was equal to nny for our test cases!
 * 
 */


#include "defs.h"


/* Solves elliptic PDE in form of diffusion equation.  This is a
 * C function which uses parameters in a form similar to the rest
 * of the code. It calls fwd3df_ */
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
)
{
  int i,j,l, mudpkworksize;
  int i_l, i_h, j_l, j_h, l_l, l_h;
  int nnx, nny, nnz;
  dtype dx,dy,dz;
  float xmin, xmax, ymin, ymax,zmin, zmax;
  double x_l, x_h, y_l, y_h, z_l, z_h;
  double x_s, y_s, z_s;
  double src_amplitude;

  double ***rhsworkspace, ***phiworkspace;
  double *mudpkworkspace;

  dtype omega,v;
  mtype ****alpha, ****beta,  
        ****rhs;

  nnx=phys_param->Ni;
  nny=phys_param->Nj;
  nnz=phys_param->Nl;
  
  xmin=(float)(phys_param->xmin);
  xmax=(float)(phys_param->xmax);
  ymin=(float)(phys_param->ymin);
  ymax=(float)(phys_param->ymax);
  zmin=(float)(phys_param->zmin);
  zmax=(float)(phys_param->zmax);
  
  dx=(xmax-xmin)/((dtype)(nnx-1));
  dy=(ymax-ymin)/((dtype)(nny-1));
  dz=(zmax-zmin)/((dtype)(nnz-1));

  /* allocate and initialize matrices for PDE coefficients  */

  alpha= (float ****)multialloc(sizeof(float), 4, nnx, nny, nnz, 2);
  beta = (float ****)multialloc(sizeof(float), 4, nnx, nny, nnz, 2);
  rhs  = (float ****)multialloc(sizeof(float), 4, nnx, nny, nnz, 2);

/* Stuff for interfacing with Mudpack */

  rhsworkspace  = (double ***)multialloc(sizeof(double), 3, nnz, nny, nnx);
  phiworkspace  = (double ***)multialloc(sizeof(double), 3, nnz, nny, nnx);


/*  This number changes if you are using a MUDPACK solver other than
    cud3.f .  See the MUDPACK documentation (cud3.d, in particular) for
    more details */

  mudpkworksize = 3*(nnx+2)*(nny+2)*(nnz+2)*(10+0+0+0);
  mudpkworkspace  = (double *)malloc(mudpkworksize*sizeof(double));
 
  for(i=0; i<nnx; i++)
  for(j=0; j<nny; j++)
  for(l=0; l<nnz; l++)
  {
      rhs[i][j][l][0]=(mtype)(0.0);
      rhs[i][j][l][1]=(mtype)(0.0); 
      if (iguessflag==0) 
      {
         phi[i][j][l][0]=(mtype)(0.0);
         phi[i][j][l][1]=(mtype)(0.0);
      } 
  }

  x_s=sources[k].x;
  y_s=sources[k].y;
  z_s=sources[k].z;
  omega=sources[k].omega;
  v = phys_param-> v;

  i_l=(int)floor((x_s-xmin)/dx);
  j_l=(int)floor((y_s-ymin)/dy);
  l_l=(int)floor((z_s-zmin)/dz);
  x_l=xmin+dx*(double)(i_l);
  y_l=ymin+dy*(double)(j_l);
  z_l=zmin+dz*(double)(l_l);
  i_h=i_l+1;
  j_h=j_l+1;
  l_h=l_l+1;
  x_h=x_l+dx;
  y_h=y_l+dy;
  z_h=z_l+dz;

  src_amplitude= (-1.0*sources[k].beta/(dx*dy*dz));
  rhs[i_h][j_h][l_h][0] = (float)(src_amplitude*(x_s-x_l)/dx*(y_s-y_l)/dy*(z_s-z_l)/dz);
  rhs[i_h][j_h][l_l][0] = (float)(src_amplitude*(x_s-x_l)/dx*(y_s-y_l)/dy*(z_h-z_s)/dz);
  rhs[i_h][j_l][l_h][0] = (float)(src_amplitude*(x_s-x_l)/dx*(y_h-y_s)/dy*(z_s-z_l)/dz);
  rhs[i_h][j_l][l_l][0] = (float)(src_amplitude*(x_s-x_l)/dx*(y_h-y_s)/dy*(z_h-z_s)/dz);
  
  rhs[i_l][j_h][l_h][0] = (float)(src_amplitude*(x_h-x_s)/dx*(y_s-y_l)/dy*(z_s-z_l)/dz);
  rhs[i_l][j_h][l_l][0] = (float)(src_amplitude*(x_h-x_s)/dx*(y_s-y_l)/dy*(z_h-z_s)/dz);
  rhs[i_l][j_l][l_h][0] = (float)(src_amplitude*(x_h-x_s)/dx*(y_h-y_s)/dy*(z_s-z_l)/dz);
  rhs[i_l][j_l][l_l][0] = (float)(src_amplitude*(x_h-x_s)/dx*(y_h-y_s)/dy*(z_h-z_s)/dz);


  for(i=0; i<nnx; i++)
  for(j=0; j<nny; j++)
  for(l=0; l<nnz; l++)
  {
      alpha[i][j][l][0] = x[1][i][j][l]; 
      alpha[i][j][l][1] = 0.0; 
      beta[i][j][l][0]  = -x[0][i][j][l];
      beta[i][j][l][1]  = -omega/v;
  }


  fwd3df_(&nnx,&nny,&nnz,
          &xmin,&xmax,&ymin,&ymax,&zmin,&zmax,
          &alpha[0][0][0][0], 
          &beta[0][0][0][0], 
          &rhs[0][0][0][0], 
          &iguessflag, 
          &mudpkworkspace[0],
          &mudpkworksize,
          &rhsworkspace[0][0][0], 
          &phiworkspace[0][0][0], 
          &ncycles,  
          &phi[0][0][0][0]);

  multifree(alpha,4);
  multifree(beta,4);
  multifree(rhs,4);
  multifree(rhsworkspace,3);
  multifree(phiworkspace,3);
  free(mudpkworkspace);

  return(0); 
} 

/* BEGIN-SINGULAR */

int grad_one_voxel_neighbor_of_optode(
  int direction,  /* x:0 y:1 z:2 */
  int i, int j, int l, 
  float ox, float oy,  float oz,
  double kr, double ki, 
  dtype beta, 
  mtype D,
  phys_param *physparam, 
  mtype *gradr, mtype *gradi)  
{
  double r, temp;
  float x,y,z, xmin, xmax, ymin, ymax, zmin, zmax, dx, dy, dz;          
  int nnx, nny, nnz; 
  float tempr1, tempi1, tempr2, tempi2;

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
  x = xmin + i * dx;
  y = ymin + j * dy;
  z = zmin + l * dz;

  r = sqrt((x-ox)*(x-ox)+(y-oy)*(y-oy)+(z-oz)*(z-oz));
  temp = -beta * exp(-kr * r) / (4.0 * 3.141592 * D * r * r);
  tempr1 = cos(-ki*r); 
  tempi1 =  sin(-ki*r); 
  tempr2 = cplxmultr(tempr1, tempi1, kr+1./r, ki);  
  tempi2 = cplxmulti(tempr1, tempi1, kr+1./r, ki);  
 
  switch(direction) {
    case 0:
      *gradr += temp*tempr2*(x-ox); 
      *gradi += temp*tempi2*(x-ox); 
      break;
    case 1:
      *gradr += temp*tempr2*(y-oy); 
      *gradi += temp*tempi2*(y-oy); 
      break;
    case 2:
      *gradr += temp*tempr2*(z-oz); 
      *gradi += temp*tempi2*(z-oz); 
      break;
  }

  return 0;
}

int grad_neighbor_of_optode(
  int direction,
  int i, int j, int l,
  float ox, float oy, float oz,
  dtype omega, dtype beta, 
  dtype calir, dtype calii,
  phys_param *physparam,
  mtype ****mu, mtype *gradr, mtype *gradi)
{
  float x, y, z, xmin, xmax, ymin, ymax, zmin, zmax, thres;          
  dtype dx,dy,dz,dd;
  int nnx, nny, nnz, i_l, j_l, l_l; 
  double kr, ki, tau;
  mtype v, wgtr, wgti;

  v = physparam->v;
  wgtr = physparam->wgtr;
  wgti = physparam->wgti;

  nnx=physparam->Ni;
  nny=physparam->Nj;
  nnz=physparam->Nl;

  thres = 0.8;
 
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

  i_l=(int)floor((ox-xmin)/dx);
  j_l=(int)floor((oy-ymin)/dy);
  l_l=(int)floor((oz-zmin)/dz);


  x = xmin + dx * i;
  y = ymin + dy * j;
  z = zmin + dz * l;
      
  tau = 1.0 / (mu[0][i][j][l] * v);
  kr = sqrt(mu[0][i][j][l]/mu[1][i][j][l]*(sqrt(1+omega*omega*tau*tau)+1)); 
  ki = sqrt(mu[0][i][j][l]/mu[1][i][j][l]*(sqrt(1+omega*omega*tau*tau)-1)); 
     
  *gradr = 0.0;   *gradi = 0.0;
  grad_one_voxel_neighbor_of_optode(direction, i, j, l, ox, oy, oz, kr, ki, 
                                    beta, mu[1][i][j][l], physparam, gradr, gradi); 
  
  if (x-xmin<thres) 
    grad_one_voxel_neighbor_of_optode(direction, i, j, l, 2*xmin-ox, oy, oz, kr, ki, 
                                      -beta, mu[1][i][j][l], physparam, gradr, gradi); 

  if (xmax-x<thres) 
    grad_one_voxel_neighbor_of_optode(direction, i, j, l, 2*xmax-ox, oy, oz, kr, ki, 
                                      -beta, mu[1][i][j][l], physparam, gradr, gradi); 

  if (y-ymin<thres) 
    grad_one_voxel_neighbor_of_optode(direction, i, j, l, ox, 2*ymin-oy, oz, kr, ki, 
                                      -beta, mu[1][i][j][l], physparam, gradr, gradi); 

  if (ymax-y<thres) 
    grad_one_voxel_neighbor_of_optode(direction, i, j, l, ox, 2*ymax-oy, oz, kr, ki, 
                                      -beta, mu[1][i][j][l], physparam, gradr, gradi); 

  if (z-zmin<thres) 
    grad_one_voxel_neighbor_of_optode(direction, i, j, l, ox, oy, 2*zmin-oz, kr, ki, 
                                      -beta, mu[1][i][j][l], physparam, gradr, gradi); 

  if (zmax-z<thres) 
    grad_one_voxel_neighbor_of_optode(direction, i, j, l, ox, oy, 2*zmax-oz, kr, ki, 
                                      -beta, mu[1][i][j][l], physparam, gradr, gradi); 

  return 0;
}

int phi_one_voxel_neighbor_of_optode(
  int i, int j, int l, 
  float ox, float oy,  float oz,
  double kr, double ki, 
  dtype beta, 
  mtype D,
  phys_param *physparam, 
  mtype *phir, mtype *phii)  
{
  double r, temp;
  float x, y, z, xmin, xmax, ymin, ymax, zmin, zmax, dx, dy, dz;          
  int nnx, nny, nnz; 

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
  x = xmin + i * dx;
  y = ymin + j * dy;
  z = zmin + l * dz;

  r = sqrt((x-ox)*(x-ox)+(y-oy)*(y-oy)+(z-oz)*(z-oz));
  temp = beta * exp(-kr * r) / (4.0 * 3.141592 * D * r);
  *phir = temp * cos(-ki*r); 
  *phii = temp * sin(-ki*r); 
 
  return 0;
}

int phi_neighbor_of_optode(
  float ox, float oy, float oz,
  dtype omega, dtype beta, 
  dtype calir, dtype calii,
  int k,
  phys_param *physparam,
  mtype ****mu,
  mtype *****phi)
{
  float x, y, z, xmin, xmax, ymin, ymax, zmin, zmax, thres;          
  dtype dx,dy,dz,dd;
  int i,j,l;
  int nnx, nny, nnz, i_l, j_l, l_l; 
  double kr, ki, tau;
  mtype v, wgtr, wgti, phir, phii;

  v = physparam->v;
  wgtr = physparam->wgtr;
  wgti = physparam->wgti;

  nnx=physparam->Ni;
  nny=physparam->Nj;
  nnz=physparam->Nl;

  thres = 0.8;
 
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

  i_l=(int)floor((ox-xmin)/dx);
  j_l=(int)floor((oy-ymin)/dy);
  l_l=(int)floor((oz-zmin)/dz);


/*
  for (i=i_l; i<i_l+2; i++)
  for (j=j_l; j<j_l+2; j++)
  for (l=l_l; l<l_l+2; l++) {
    if (i>=0 && j>=0 && l>=0 && i<nnx && j<nny && l<nnz) {
*/
  for (i=0; i<nnx; i++)
  for (j=0; j<nny; j++)
  for (l=0; l<nnz; l++) {
    x = xmin + dx * i;
    y = ymin + dy * j;
    z = zmin + dz * l;
      
    if ((ox-x)*(ox-x)+(oy-y)*(oy-y)+(oz-z)*(oz-z)<0.8*0.8*dd*dd) {
      tau = 1.0 / (mu[0][i][j][l] * v);
      kr = sqrt(mu[0][i][j][l]/mu[1][i][j][l]*(sqrt(1+omega*omega*tau*tau)+1)); 
      ki = sqrt(mu[0][i][j][l]/mu[1][i][j][l]*(sqrt(1+omega*omega*tau*tau)-1)); 
     
      phi_one_voxel_neighbor_of_optode(i,j,l,ox,oy,oz,kr,ki, beta, 
                                       mu[1][i][j][l], physparam, &phir, &phii); 
      phi[k][i][j][l][0] = phir;
      phi[k][i][j][l][1] = phii;
  
      if (x-xmin<thres) {
        phi_one_voxel_neighbor_of_optode(i,j,l,2*xmin-ox,oy,oz,kr,ki, -beta, 
                                         mu[1][i][j][l], physparam, &phir, &phii); 
        phi[k][i][j][l][0] += phir;
        phi[k][i][j][l][1] += phii;
      }

      if (xmax-x<thres) {
        phi_one_voxel_neighbor_of_optode(i,j,l,2*xmax-ox,oy,oz,kr,ki, -beta, 
                                         mu[1][i][j][l], physparam, &phir, &phii); 
        phi[k][i][j][l][0] += phir;
        phi[k][i][j][l][1] += phii;
      }

      if (y-ymin<thres) {
        phi_one_voxel_neighbor_of_optode(i,j,l,ox,2*ymin-oy,oz,kr,ki, -beta, 
                                         mu[1][i][j][l], physparam, &phir, &phii); 
        phi[k][i][j][l][0] += phir;
        phi[k][i][j][l][1] += phii;
      }

      if (ymax-y<thres) {
        phi_one_voxel_neighbor_of_optode(i,j,l,ox,2*ymax-oy,oz,kr,ki, -beta,
                                         mu[1][i][j][l], physparam, &phir, &phii); 
        phi[k][i][j][l][0] += phir;
        phi[k][i][j][l][1] += phii;
      }

      if (z-zmin<thres) {
        phi_one_voxel_neighbor_of_optode(i,j,l,ox,oy,2*zmin-oz,kr,ki, -beta, 
                                         mu[1][i][j][l], physparam, &phir, &phii); 
        phi[k][i][j][l][0] += phir;
        phi[k][i][j][l][1] += phii;
      }

      if (zmax-z<thres) {
        phi_one_voxel_neighbor_of_optode(i,j,l,ox,oy,2*zmax-oz,kr,ki, -beta, 
                                         mu[1][i][j][l], physparam, &phir, &phii); 
        phi[k][i][j][l][0] += phir;
        phi[k][i][j][l][1] += phii;
      }
    }
  }

  return 0;
}

/* END-SINGULAR */

int calc_phi(
     /*  Input */
  src_param *sources, /* Info about source locations and frequencies */
  det_param *dets,    /* Info about detector positions */
  mtype ****x,        /* mua and mus array: x[u,i,j,l] */
  phys_param *phys_param, /* Info about physical dimensions of problem */
    /* Output */
  mtype *****phi,     /* Calculated phi for each source: phi[k,i,j,l,c]*/
  mtype **fx         /* Calculated phi at measurement positions: fx[s,c]*/
 )
{
  int k,m,s, i_l,j_l,l_l, i_h, j_h, l_h ;
  int nnx, nny, nnz;
  LINK2D sparse, src_element;
  LINK   det_list;
  dtype  xmin, xmax, ymin, ymax, zmin, zmax, dx, dy, dz;
  dtype  x_l, x_h, y_l, y_h, z_l, z_h, x_d, y_d, z_d;

  sparse=phys_param->sparse;
  
  s=0;
  for(k=0; k<phys_param->K; k++){
    fwdsolver_3d(phys_param, sources,  
       k,x,0, DEFAULT_CYCLES, phi[k]);

    /* BEGIN-SINGULAR */
    phi_neighbor_of_optode(sources[k].x, sources[k].y, sources[k].z, 
                           sources[k].omega, sources[k].beta, 
                           sources[k].calir, sources[k].calii,
                           k, phys_param, x, phi);
    /* END-SINGULAR */

    src_element=find_element_2d(sparse, k);
    if(src_element==NULL){
      fprintf(stderr, "calc_phi: problem with linked list. Aborting.\n");
      return -1;
    }
    det_list=src_element->d;

    nnx=phys_param->Ni;
    nny=phys_param->Nj;
    nnz=phys_param->Nl;
    xmin=(phys_param->xmin);
    xmax=(phys_param->xmax);
    ymin=(phys_param->ymin);
    ymax=(phys_param->ymax);
    zmin=(phys_param->zmin);
    zmax=(phys_param->zmax);
    
    dx=(xmax-xmin)/((dtype)(nnx-1));
    dy=(ymax-ymin)/((dtype)(nny-1));
    dz=(zmax-zmin)/((dtype)(nnz-1));

    for(m=0; m<phys_param->M; m++){
      x_d=dets[m].x;
      y_d=dets[m].y;
      z_d=dets[m].z;

      i_l=(int)floor((x_d-xmin)/dx);
      j_l=(int)floor((y_d-ymin)/dy);
      l_l=(int)floor((z_d-zmin)/dz);
      x_l=xmin+dx*(double)(i_l);
      y_l=ymin+dy*(double)(j_l);
      z_l=zmin+dz*(double)(l_l);
      i_h=i_l+1;
      j_h=j_l+1;
      l_h=l_l+1;
      x_h=x_l+dx;
      y_h=y_l+dy;
      z_h=z_l+dz;


      if(find_data_in_list(det_list,m) >= 0){
        fx[s][0]=(x_d-x_l)/dx*(y_d-y_l)/dy*(z_d-z_l)/dz*phi[k][i_h][j_h][l_h][0]
                +(x_d-x_l)/dx*(y_d-y_l)/dy*(z_h-z_d)/dz*phi[k][i_h][j_h][l_l][0]
                +(x_d-x_l)/dx*(y_h-y_d)/dy*(z_d-z_l)/dz*phi[k][i_h][j_l][l_h][0]
                +(x_d-x_l)/dx*(y_h-y_d)/dy*(z_h-z_d)/dz*phi[k][i_h][j_l][l_l][0]
                +(x_h-x_d)/dx*(y_d-y_l)/dy*(z_d-z_l)/dz*phi[k][i_l][j_h][l_h][0]
                +(x_h-x_d)/dx*(y_d-y_l)/dy*(z_h-z_d)/dz*phi[k][i_l][j_h][l_l][0]
                +(x_h-x_d)/dx*(y_h-y_d)/dy*(z_d-z_l)/dz*phi[k][i_l][j_l][l_h][0]
                +(x_h-x_d)/dx*(y_h-y_d)/dy*(z_h-z_d)/dz*phi[k][i_l][j_l][l_l][0];
 
        fx[s][1]=(x_d-x_l)/dx*(y_d-y_l)/dy*(z_d-z_l)/dz*phi[k][i_h][j_h][l_h][1]
                +(x_d-x_l)/dx*(y_d-y_l)/dy*(z_h-z_d)/dz*phi[k][i_h][j_h][l_l][1]
                +(x_d-x_l)/dx*(y_h-y_d)/dy*(z_d-z_l)/dz*phi[k][i_h][j_l][l_h][1]
                +(x_d-x_l)/dx*(y_h-y_d)/dy*(z_h-z_d)/dz*phi[k][i_h][j_l][l_l][1]
                +(x_h-x_d)/dx*(y_d-y_l)/dy*(z_d-z_l)/dz*phi[k][i_l][j_h][l_h][1]
                +(x_h-x_d)/dx*(y_d-y_l)/dy*(z_h-z_d)/dz*phi[k][i_l][j_h][l_l][1]
                +(x_h-x_d)/dx*(y_h-y_d)/dy*(z_d-z_l)/dz*phi[k][i_l][j_l][l_h][1]
                +(x_h-x_d)/dx*(y_h-y_d)/dy*(z_h-z_d)/dz*phi[k][i_l][j_l][l_l][1];
                
        s++;
      }

    }
  }
  return 0;
}

int add_detector_noise(phys_param *physparam, dtype alpha_fixed, mtype **meas, mtype *snr){
  int s;
  double noisymeas_real, noisymeas_imag, mag;
  srandom2(time(NULL));

  for(s=0; s<physparam->S; s++){
    mag=sqrt(AbsSquare(meas[s][0],meas[s][1]));
    noisymeas_real=meas[s][0]+sqrt(.5*alpha_fixed*mag)*normal();
    noisymeas_imag=meas[s][1]+sqrt(.5*alpha_fixed*mag)*normal();
    snr[s]=1./alpha_fixed*mag;
    meas[s][0]=noisymeas_real;
    meas[s][1]=noisymeas_imag;
  }
  return 0; 
}




/******
int calc_gradient(
  mtype ****field,
  mtype **grad,
  int i, int j, int l,
  dtype dx, dtype dy, dtype dz,
  int opt)
{
  int c, x, y;
  dtype h[2][3][3]
    = { { {0, 0, 0}, {0,0.5,0},{0,0,0} },
        { {1./18., 1./18., 1./18}, {1./18., 1./18., 1./18}, {1./18., 1./18., 1./18} } };

  for (c=0; c<2; c++) {
    grad[0][c] = 0.0;
    grad[1][c] = 0.0;
    grad[2][c] = 0.0;

    for (x=0; x<3; x++)
    for (y=0; y<3; y++) {
      grad[0][c] += (-field[i-1][j+x-1][l+y-1][c] + field[i+1][j+x-1][l+y-1][c]) * h[opt][x][y] / (dx * 2.);
      grad[1][c] += (-field[i+x-1][j-1][l+y-1][c] + field[i+x-1][j+1][l+y-1][c]) * h[opt][x][y] / (dy * 2.);
      grad[2][c] += (-field[i+x-1][j+y-1][l-1][c] + field[i+x-1][j+y-1][l+1][c]) * h[opt][x][y] / (dz * 2.);
    }
  }

  return 0;
}
****/

int calc_gradient(
  mtype ****field,
  mtype **grad,
  int i, int j, int l,
  dtype dx, dtype dy, dtype dz,
  int opt)
{
  int c;

  for (c=0; c<2; c++) {
    grad[0][c] = (-field[i-1][j][l][c] + field[i+1][j][l][c]) / (dx*2.);
    grad[1][c] = (-field[i][j-1][l][c] + field[i][j+1][l][c]) / (dy*2.);
    grad[2][c] = (-field[i][j][l-1][c] + field[i][j][l+1][c]) / (dz*2.);
  }

  return 0;
}

int calc_green(
     /*  Input */
  src_param *sources, /* Info about source locations and frequencies */
  det_param *dets,    /* Info about detector positions */
  mtype ****x,        /* mua and mus array: x[u,i,j,l] */
  phys_param *phys_param, /* Info about physical dimensions of problem */
    /* Output */
  mtype *****green    /* Calculated green for each source: green[k,i,j,l,c]*/
 )
{
  int m;
  src_param *green_src_at_det_pos=NULL;
  double x_d, y_d, z_d;

  green_src_at_det_pos=(src_param *)malloc(1*sizeof(src_param));

  for(m=0; m<phys_param->M; m++){
    x_d = dets[m].x;
    y_d = dets[m].y;
    z_d = dets[m].z;

    green_src_at_det_pos->x=x_d;
    green_src_at_det_pos->y=y_d;
    green_src_at_det_pos->z=z_d;
    green_src_at_det_pos->omega=dets[m].omega;
    green_src_at_det_pos->beta=(dtype)1.0;
  
    fwdsolver_3d(phys_param, green_src_at_det_pos, 
       0,x,0, DEFAULT_CYCLES, green[m]);

    /* BEGIN-SINGULAR */
    phi_neighbor_of_optode(dets[m].x, dets[m].y, dets[m].z, 
                           dets[m].omega, 1.0, 
                           dets[m].calir, dets[m].calii,
                           m, phys_param, x, green);
    /* END-SINGULAR */
  }
  free(green_src_at_det_pos);
  return 0;
}


float dist_voxel2point(
  int i, int j, int l,
  dtype ox, dtype oy, dtype oz, 
  phys_param *physparam)
{
  float x, y, z, xmin, xmax, ymin, ymax, zmin, zmax, dx, dy, dz;          
  int nnx, nny, nnz; 

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
  x = xmin + i * dx;
  y = ymin + j * dy;
  z = zmin + l * dz;

  return(sqrt((x-ox)*(x-ox)+(y-oy)*(y-oy)+(z-oz)*(z-oz)));
} 


int check_ifneighbor(
  int i, int j, int l,
  dtype ox, dtype oy, dtype oz, 
  phys_param *physparam)
{
  float  xmin, xmax, ymin, ymax, zmin, zmax, dx, dy, dz;          
  int nnx, nny, nnz; 
  float distance,dd;

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

  distance = dist_voxel2point(i,j,l,ox,oy,oz,physparam);

  if (distance>0.8*dd) 
    return 0;
  else 
    return 1;
}

int calc_frechet_col(
  /* Input */
  int u, int i, int j, int l,
  mtype *****phi,
  mtype *****green,
  mtype ****x,
  src_param *sources,
  det_param *dets,
  phys_param *phys_param,
    /* Output */
  mtype **At          /* At[s,c] */
)
{
  int k,m,s;
  int nnx, nny, nnz;
  dtype xmin, xmax, ymin, ymax, zmin, zmax, dx, dy, dz, A;
  dtype D, mua;
  dtype v, omega;
  dtype greenr, greeni, phir, phii, tempr, tempi;
  mtype **gradgreen, **gradphi;    /* gradient[x/y/z][r/i] */
  mtype dgr, dgi, dpr, dpi;

  LINK2D sparse, src_element;
  LINK   det_list;

  nnx=phys_param->Ni;
  nny=phys_param->Nj;
  nnz=phys_param->Nl;

  v=phys_param->v;
  xmin=phys_param->xmin;
  xmax=phys_param->xmax;
  ymin=phys_param->ymin;
  ymax=phys_param->ymax;
  zmin=phys_param->zmin;
  zmax=phys_param->zmax;
 
  dx=(xmax-xmin)/((dtype)(nnx-1));
  dy=(ymax-ymin)/((dtype)(nny-1));
  dz=(zmax-zmin)/((dtype)(nnz-1));
  A = dx * dy * dz;

  gradgreen = multialloc(sizeof(mtype), 2, 3, 2);
  gradphi   = multialloc(sizeof(mtype), 2, 3, 2);

  sparse=phys_param->sparse;
  s=0;
  for(k=0; k<phys_param->K; k++){
    src_element=find_element_2d(sparse, k);
    if(src_element==NULL){
      fprintf(stderr, "calc_frechet_col: problem with linked list. Aborting.\n");
      return -1;
    }
    det_list=src_element->d;

    for(m=0; m<phys_param->M; m++) {
      if(find_data_in_list(det_list,m) >= 0){
        omega=sources[k].omega;
        mua=(dtype)x[0][i][j][l];
        D  =(dtype)x[1][i][j][l];
        greenr=green[m][i][j][l][0];
        greeni=green[m][i][j][l][1];

        phir=phi[k][i][j][l][0];
        phii=phi[k][i][j][l][1];

        tempr = (greenr * phir - greeni * phii) * A;
        tempi = (greenr * phii + greeni * phir) * A;

        if(u==MUA) {
          At[s][0] = -tempr;
          At[s][1] = -tempi;
        }

        else if(u==MUS) {
/*  In case of finite-element-like gradient,
          calc_gradient(green[m],gradgreen,i,j,l,dx,dy,dz,0);
          calc_gradient(phi[k],  gradphi,  i,j,l,dx,dy,dz,0);

          At[s][0] = 0.0;
          At[s][1] = 0.0;

          for (ii=0; ii<3; ii++) {
            At[s][0] += gradgreen[ii][0] * gradphi[ii][0]
                         - gradgreen[ii][1] * gradphi[ii][1];
            At[s][1] += gradgreen[ii][0] * gradphi[ii][1]
                         + gradgreen[ii][1] * gradphi[ii][0];
          }

          At[s][0] *= -A; 
          At[s][1] *= -A;
*/
/* In case of Jong's Formular-like method ,
          cDr = mua/D;
          cDi = omega/v/D;
          At[s][0] = tempr * cDr - tempi * cDi;
          At[s][1] = tempr * cDi + tempi * cDr;
*/

/* In case of Professors' method, */
          At[s][0] = 0.0;
          At[s][1] = 0.0;

/* MILSTEIN - added bounds checking to allow updates along the edges */
 
          if(i>0){
            if ( check_ifneighbor(i,j,l, dets[m].x, dets[m].y, dets[m].z, phys_param)) {
              grad_neighbor_of_optode(1, i, j, l, dets[m].x, dets[m].y, dets[m].z, 
                                      dets[m].omega, 1.0, dets[m].calir, dets[m].calii, 
                                      phys_param, x, &dgr, &dgi);
            }
            else {
              dgr = (green[m][i][j][l][0] - green[m][i-1][j][l][0])/dx;
              dgi = (green[m][i][j][l][1] - green[m][i-1][j][l][1])/dx;
            }
            dpr = (phi[k][i][j][l][0] - phi[k][i-1][j][l][0])/dx;
            dpi = (phi[k][i][j][l][1] - phi[k][i-1][j][l][1])/dx;
            At[s][0] += dgr * dpr - dgi * dpi;
            At[s][1] += dgi * dpr + dgr * dpi;
          }
 
          if(i<(nnx-1)){
            dgr = (green[m][i+1][j][l][0] - green[m][i][j][l][0])/dx;
            dgi = (green[m][i+1][j][l][1] - green[m][i][j][l][1])/dx;
            dpr = (phi[k][i+1][j][l][0] - phi[k][i][j][l][0])/dx;
            dpi = (phi[k][i+1][j][l][1] - phi[k][i][j][l][1])/dx;
            At[s][0] += dgr * dpr - dgi * dpi;
            At[s][1] += dgi * dpr + dgr * dpi;
          }
 
          if(j>0){
            dgr = (green[m][i][j][l][0] - green[m][i][j-1][l][0])/dy;
            dgi = (green[m][i][j][l][1] - green[m][i][j-1][l][1])/dy;
            dpr = (phi[k][i][j][l][0] - phi[k][i][j-1][l][0])/dy;
            dpi = (phi[k][i][j][l][1] - phi[k][i][j-1][l][1])/dy;
            At[s][0] += dgr * dpr - dgi * dpi;
            At[s][1] += dgi * dpr + dgr * dpi;
          }
 
          if(j<(nny-1)){
            dgr = (green[m][i][j+1][l][0] - green[m][i][j][l][0])/dy;
            dgi = (green[m][i][j+1][l][1] - green[m][i][j][l][1])/dy;
            dpr = (phi[k][i][j+1][l][0] - phi[k][i][j][l][0])/dy;
            dpi = (phi[k][i][j+1][l][1] - phi[k][i][j][l][1])/dy;
            At[s][0] += dgr * dpr - dgi * dpi;
            At[s][1] += dgi * dpr + dgr * dpi;
          }
 
          if(l>0){
            dgr = (green[m][i][j][l][0] - green[m][i][j][l-1][0])/dz;
            dgi = (green[m][i][j][l][1] - green[m][i][j][l-1][1])/dz;
            dpr = (phi[k][i][j][l][0] - phi[k][i][j][l-1][0])/dz;
            dpi = (phi[k][i][j][l][1] - phi[k][i][j][l-1][1])/dz;
            At[s][0] += dgr * dpr - dgi * dpi;
            At[s][1] += dgi * dpr + dgr * dpi;
          }
 
          if(l<(nnz-1)){
            dgr = (green[m][i][j][l+1][0] - green[m][i][j][l][0])/dz;
            dgi = (green[m][i][j][l+1][1] - green[m][i][j][l][1])/dz;
            dpr = (phi[k][i][j][l+1][0] - phi[k][i][j][l][0])/dz;
            dpi = (phi[k][i][j][l+1][1] - phi[k][i][j][l][1])/dz;
            At[s][0] += dgr * dpr - dgi * dpi;
            At[s][1] += dgi * dpr + dgr * dpi;
          }

          At[s][0] *= -A / 2.0;
          At[s][1] *= -A / 2.0;
/**/
        }
        else {
          fprintf(stderr, "ERROR! Invalid u!\n");
          exit(1);
        }
        s++;
      }
    }/* End for m */
  }/* End for k*/
  multifree(gradgreen, 2);
  multifree(gradphi, 2);

  return 0;
}


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
)
{
  int k,m,u,i,j,l;
  int nnx, nny, nnz;
  dtype xmin, xmax, ymin, ymax, zmin, zmax, dx, dy, dz, A;
  dtype greenr, greeni, phir, phii;
  double dgr, dgi, dpr, dpi;
  dtype xx,yy,zz;
 
  nnx=physparam->Ni;
  nny=physparam->Nj;
  nnz=physparam->Nl;
 
  xmin=physparam->xmin;
  xmax=physparam->xmax;
  ymin=physparam->ymin;
  ymax=physparam->ymax;
  zmin=physparam->zmin;
  zmax=physparam->zmax;
 
  dx=(xmax-xmin)/((dtype)(nnx-1));
  dy=(ymax-ymin)/((dtype)(nny-1));
  dz=(zmax-zmin)/((dtype)(nnz-1));
  A = dx * dy * dz;
 
  k = findk(physparam, s);
  m = findm(physparam, s);
 
  u = MUA;    
  for (i=1; i<nnx-1; i++)
  for (j=1; j<nny-1; j++)
  for (l=1; l<nnz-1; l++) {
    greenr=green[m][i][j][l][0];
    greeni=green[m][i][j][l][1];
    phir=phi[k][i][j][l][0];
    phii=phi[k][i][j][l][1];
    At[u][i][j][l][0] = - (greenr * phir - greeni * phii) * A;
    At[u][i][j][l][1] = - (greenr * phii + greeni * phir) * A;
  }
 
 
  u = MUS;
 
  for (i=1; i<nnx-1; i++)
  for (j=1; j<nny-1; j++)
  for (l=1; l<nnz-1; l++) {
    xx = xmin + dx * i;
    yy = ymin + dy * j;
    zz = zmin + dz * l;

    At[u][i][j][l][0] = 0.0;
    At[u][i][j][l][1] = 0.0;
 
    dgr = (green[m][i][j][l][0] - green[m][i-1][j][l][0])/dx;
    dgi = (green[m][i][j][l][1] - green[m][i-1][j][l][1])/dx;
    dpr = (phi[k][i][j][l][0] - phi[k][i-1][j][l][0])/dx;
    dpi = (phi[k][i][j][l][1] - phi[k][i-1][j][l][1])/dx;
    At[u][i][j][l][0] += dgr * dpr - dgi * dpi;
    At[u][i][j][l][1] += dgi * dpr + dgr * dpi;
 
    dgr = (green[m][i+1][j][l][0] - green[m][i][j][l][0])/dx;
    dgi = (green[m][i+1][j][l][1] - green[m][i][j][l][1])/dx;
    dpr = (phi[k][i+1][j][l][0] - phi[k][i][j][l][0])/dx;
    dpi = (phi[k][i+1][j][l][1] - phi[k][i][j][l][1])/dx;
    At[u][i][j][l][0] += dgr * dpr - dgi * dpi;
    At[u][i][j][l][1] += dgi * dpr + dgr * dpi;
 
    dgr = (green[m][i][j][l][0] - green[m][i][j-1][l][0])/dy;
    dgi = (green[m][i][j][l][1] - green[m][i][j-1][l][1])/dy;
    dpr = (phi[k][i][j][l][0] - phi[k][i][j-1][l][0])/dy;
    dpi = (phi[k][i][j][l][1] - phi[k][i][j-1][l][1])/dy;
    At[u][i][j][l][0] += dgr * dpr - dgi * dpi;            

    dgr = (green[m][i][j+1][l][0] - green[m][i][j][l][0])/dy;
    dgi = (green[m][i][j+1][l][1] - green[m][i][j][l][1])/dy;
    dpr = (phi[k][i][j+1][l][0] - phi[k][i][j][l][0])/dy;
    dpi = (phi[k][i][j+1][l][1] - phi[k][i][j][l][1])/dy;
    At[u][i][j][l][0] += dgr * dpr - dgi * dpi;
    At[u][i][j][l][1] += dgi * dpr + dgr * dpi;
 
    dgr = (green[m][i][j][l][0] - green[m][i][j][l-1][0])/dz;
    dgi = (green[m][i][j][l][1] - green[m][i][j][l-1][1])/dz;
    dpr = (phi[k][i][j][l][0] - phi[k][i][j][l-1][0])/dz;
    dpi = (phi[k][i][j][l][1] - phi[k][i][j][l-1][1])/dz;
    At[u][i][j][l][0] += dgr * dpr - dgi * dpi;
    At[u][i][j][l][1] += dgi * dpr + dgr * dpi;
 
    dgr = (green[m][i][j][l+1][0] - green[m][i][j][l][0])/dz;
    dgi = (green[m][i][j][l+1][1] - green[m][i][j][l][1])/dz;
    dpr = (phi[k][i][j][l+1][0] - phi[k][i][j][l][0])/dz;
    dpi = (phi[k][i][j][l+1][1] - phi[k][i][j][l][1])/dz;
 
    At[u][i][j][l][0] += dgr * dpr - dgi * dpi;
    At[u][i][j][l][1] += dgi * dpr + dgr * dpi;
 
    At[u][i][j][l][0] *= -A / 2.0;
    At[u][i][j][l][1] *= -A / 2.0;
  }
 
  return 0;
}                






