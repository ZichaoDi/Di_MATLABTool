/*
 * ICD-Born iterative method for optical diffusion tomography 
 * Jong's paper, JOSA-A, Oct, 1999
 * 
 * Seungseok Oh 
 * 10/25/2000
 */

#include <stdio.h>
#include <string.h>
#include <math.h>
#include "allocate.h"
#include "defs.h"


int main(int argc, char **argv){
  int i,j,l,c,s,k,m;
  int status;
  int fwd_flag=0;
  phys_param  *physparam;
  src_param    *srcparam;
  det_param    *detparam;
  prior_param *priorparam_mua;
  prior_param *priorparam_D;
  dtype *x, *y, *z, dx, dy, dz;
  dtype alpha_fixed=9.4e-6;
  mtype ****mu, ****muhat;  
  mtype **meas, **meas2, **yerror;
  mtype *****phi;
  mtype *snr;
  FILE *fp=NULL;
  char physfile[255];
  char priorfile_D[255];
  char priorfile_mua[255];
  char measfile[255];
  char phantomfile[255];
  config_param config;
  double tempr, tempi, temp2r, temp2i, temp3r, temp3i;    
  dtype b[26]; 


  if (argc!=2 && argc!=7) {
    fprintf(stderr, "Usage: %s configfile\n", argv[0]);
    fprintf(stderr, "OR   : %s -F physfile phantomfile alpha wgtr wgti\n", argv[0]);
    exit(1);
  }

  if(argc==2){ 
    fp = fopen(argv[1],"r");
    if (fp==NULL) {
      fprintf(stderr, "ERROR! Cannot load configuration file!\n");
      exit(1);
    }
    get_config(fp, &config);
    fclose(fp);

    strcpy(physfile, config.phys_file);
    strcpy(priorfile_D, config.prior_D_file);
    strcpy(priorfile_mua, config.prior_mua_file);
    strcpy(measfile, config.meas_file);
  }
  else{
    fwd_flag=1;
    strcpy(physfile, argv[2]);
    strcpy(phantomfile, argv[3]);
    alpha_fixed=atof(argv[4]);
  }
 
  printf("Reading in physical parameters from file `%s`...\n",physfile);
  fp=fopen(physfile, "r");
  if(fp==NULL){
    fprintf(stderr,"Error: can't open `%s`\n", physfile);
    exit(1);
  }
  
  physparam=alloc_phys_param();
  get_all_phys(fp, physparam, &srcparam, &detparam);  
  fclose(fp);

/* Milstein - BEGIN */

  if(!fwd_flag){
    physparam->wgtr=config.init_wgtr;
    physparam->wgti=0.0;
  }
  else{
    physparam->wgtr=atof(argv[5]);
    physparam->wgti=atof(argv[6]);
  }    

/* Milstein - END */   


  /* make a grid */
  dx=(physparam->xmax - physparam->xmin) / ((float)(physparam->Ni - 1));
  dy=(physparam->ymax - physparam->ymin) / ((float)(physparam->Nj - 1));
  dz=(physparam->zmax - physparam->zmin) / ((float)(physparam->Nl - 1));

  x=(dtype *)malloc((physparam->Ni)*sizeof(dtype));
  y=(dtype *)malloc((physparam->Nj)*sizeof(dtype));
  z=(dtype *)malloc((physparam->Nl)*sizeof(dtype));

  for(i=0; i<physparam->Ni; i++)
    x[i]= physparam->xmin + ((float)(i)) * dx;
  for(j=0; j<physparam->Nj; j++)
    y[j]= physparam->ymin + ((float)(j)) * dy;
  for(l=0; l<physparam->Nl; l++)
    z[l]= physparam->zmin + ((float)(l)) * dz;



  /* Set prior model parameters */

  if(!fwd_flag){
    priorparam_D = alloc_prior_param(NULL, 0, 0, 26, b);   
    printf("Reading in model parameters from file `%s`...\n",priorfile_D);
    fp=fopen(priorfile_D,"r");
    if(fp==NULL){
      fprintf(stderr,"Error: can't open `%s`\n", priorfile_D);
      exit(1);
    }
    get_prior(fp,priorparam_D);
    fclose(fp);

    priorparam_mua = alloc_prior_param(NULL, 0, 0, 26, b);   
    printf("Reading in model parameters from file `%s`...\n",priorfile_mua);
    fp=fopen(priorfile_mua,"r");
    if(fp==NULL){
      fprintf(stderr,"Error: can't open `%s`\n", priorfile_mua);
      exit(1);
    }
    get_prior(fp,priorparam_mua);

    fclose(fp);

  }


  /* Set absorption and scattering coeff. */

  mu   = multialloc(sizeof(mtype), 4, 2, physparam->Ni, physparam->Nj, physparam->Nl);
  muhat= multialloc(sizeof(mtype), 4, 2, physparam->Ni, physparam->Nj, physparam->Nl);

  if(fwd_flag){ 
    fp = datOpen(phantomfile, "r");
    if(fp==NULL){
      fprintf(stderr,"Error: can't open `%s`\n", phantomfile);
      exit(1);
    }
    status=read_float_array(fp, "mu" , &mu[0][0][0][0] , 4, 
                            2, physparam->Ni, physparam->Nj, physparam->Nl );
    if(status==FOERR){
      fprintf(stderr,"Error reading mu. Aborting.\n");
      exit(1);
    }
    datClose(fp);
  }


  /* simulate measurement */

  phi    = multialloc(sizeof(mtype), 5, physparam->K, physparam->Ni, 
                      physparam->Nj, physparam->Nl, 2);
  meas   = multialloc(sizeof(mtype), 2, physparam->S, 2);
  yerror = multialloc(sizeof(mtype), 2, physparam->S, 2);
  meas2   = multialloc(sizeof(mtype), 2, physparam->S, 2);
  snr   = malloc(sizeof(mtype)*physparam->S);

  if(srcparam==NULL || detparam==NULL|| physparam==NULL|| 
     phi==NULL || meas==NULL || yerror==NULL || meas2==NULL)  {
    printf("Memory problems.\n");
    exit(1);
  }

  if(fwd_flag){
     calc_phi(srcparam, detparam, mu, physparam, phi, meas);
     add_detector_noise(physparam, alpha_fixed, meas, snr);

     for (s=0; s<physparam->S; s++) {
       k = findk(physparam,s);
       m = findm(physparam,s);
       tempr = cplxmultr(srcparam[k].calir, srcparam[k].calii,
                         detparam[m].calir, detparam[m].calii);
       tempi = cplxmulti(srcparam[k].calir, srcparam[k].calii,
                         detparam[m].calir, detparam[m].calii);
       temp2r = cplxmultr(meas[s][0], meas[s][1], tempr, tempi);
       temp2i = cplxmulti(meas[s][0], meas[s][1], tempr, tempi);

       /* Milstein - Begin */
       temp3r = cplxmultr(temp2r, temp2i, physparam->wgtr, physparam->wgti);
       temp3i = cplxmulti(temp2r, temp2i, physparam->wgtr, physparam->wgti);
 
       fprintf(stderr, "%2d  %2d  %2d : %f  %f  %f  %f  %f  %f \n",
                 s, k, m, tempr, tempi, meas[s][0], meas[s][1], temp3r, temp3i);
       meas[s][0] = temp3r;
       meas[s][1] = temp3i;
       /* Milstein - END */    
     }

     fp = datOpen("meas.dat", "w+b");
     write_float_array(fp, "meas", &meas[0][0], 2, physparam->S, 2);
     datClose(fp);
     fp = datOpen("snr.dat", "w+b");
     write_float_array(fp, "snr", &snr[0], 1, physparam->S);
     datClose(fp);
  }

  else{
    printf("Reading measurement data...\n");
    fp = datOpen(measfile, "r+b");
    status=read_float_array(fp, "meas" , &meas[0][0] , 2, physparam->S, 2);
    if(status==FOERR){
      fprintf(stderr,"Error reading measurements. Aborting.\n");
      exit(1);
    }
    datClose(fp);

    /* initial guess of mus and mua */ 

    for(i=0; i<physparam->Ni; i++)
    for(j=0; j<physparam->Nj; j++)
    for(l=0; l<physparam->Nl; l++) {   
      muhat[0][i][j][l] = config.mua_backg; 
      muhat[1][i][j][l] = config.D_backg; 
    } 

    if(config.init_guess_flag){
      fp = datOpen(config.init_guess_path, "r");
      if(fp==NULL){
        fprintf(stderr,"Error: can't open `%s`\n", config.init_guess_path);
        exit(1);
      }
      status=read_float_array(fp, config.init_guess_varname , 
                              &muhat[0][0][0][0] , 4, 2, 
                              physparam->Ni, physparam->Nj, physparam->Nl );
 
      if(status==FOERR){
        fprintf(stderr,"Error reading initial guess file. Aborting.\n");
        exit(1);
      }
      datClose(fp);
    }

    /* Intitialize the source-detector weights. 
       Initial guess of calibration is 1.0+0.0j. */

    if (config.calibration_flag!=2) {  
      for (k=0; k<physparam->K; k++) {
        srcparam[k].calir = 1.0;
        srcparam[k].calii = 0.0;
      }

      for (m=0; m<physparam->M; m++) {
        detparam[m].calir = 1.0;
        detparam[m].calii = 0.0;
      }  
    }

/* DELETE-MG *
    printf("Forward solution...\n");
    calc_phi(srcparam, detparam, muhat, physparam, phi, meas2); 

    for (s=0; s<physparam->S; s++) 
    for (c=0; c<2; c++) {
      yerror[s][c] = meas[s][c] - meas2[s][c];
      printf("yerror[%d][%d]=%e\n",s,c,yerror[s][c]);
    }
*/
    /* perform ICD iterations */

    printf("Inversion...\n");

/* LINE-MG */
    multigrid_main(muhat, meas, physparam, srcparam, detparam, 
                priorparam_mua, priorparam_D, yerror, &config);

/* DELETE-LINE-MG *
    rvssolver_sg(muhat, meas, physparam, srcparam, detparam, 
                 priorparam_D, priorparam_mua, yerror, &config); 
 */
  }


  delete_phys_param(physparam); 
  free(srcparam);
  free(detparam);

  if(!fwd_flag) {
    free_prior_param(priorparam_D);
    free_prior_param(priorparam_mua);
  }

  multifree(mu,4);
  multifree(muhat,4);
  multifree(phi,5);
  multifree(meas,2);
  multifree(meas2,2);
  multifree(yerror,2);
  free(x);
  free(y);
  free(z);
  
  return 0;
}
