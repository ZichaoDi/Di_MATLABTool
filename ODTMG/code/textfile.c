#include "structs.h"
#include "listfun.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "textfile.h"

int is_int(char *buf){
  char trash[255];
  int test, status;

  strcpy(trash,"");

  status= sscanf(buf, "%d", &test);
  if(status!=1) return 0;
  
  status= sscanf(buf, "%d%s", &test, trash);
  if(strlen(trash)>0) return 0;
  
  return 1;
}

int is_double(char *buf){
  char trash[255];
  int status;
  double test;

  strcpy(trash,"");

  status= sscanf(buf, "%lf", &test);
  if(status!=1) return 0;
  
  status= sscanf(buf, "%lf%s", &test, trash);
  if(strlen(trash)>0) return 0;
  
  return 1;
}

int read_next_word(FILE *fp, char *buf){
  int status;
  char trash[255];

  while(1){
    status=fscanf(fp," %s", &buf[0]);

/* Skip over comments */
    if(buf[0]=='#'){
      fscanf(fp,"%[^\n]\n",trash);
      continue;
    }
    break;
  }

  return status;
}

int read_next_int(FILE *fp, int *readme){
  int status;
  char trash[255];
  char buf[255];

  while(1){
    status=fscanf(fp," %s", &buf[0]);

/* Skip over comments */
    if(buf[0]=='#'){
      fscanf(fp,"%[^\n]\n",trash);
      continue;
    }
    break;
  }
  if(!is_int(buf)){
    fprintf(stderr,"Parse error: expected integer, found `%s`.\n",buf);
    exit(1);
  }
  *readme=atoi(buf);

  return 0;
}

int read_next_int_or_brace(FILE *fp, int *readme){
  int status;
  char trash[255];
  char buf[255];

  while(1){
    status=fscanf(fp," %s", &buf[0]);

/* Skip over comments */
    if(buf[0]=='#'){
      fscanf(fp,"%[^\n]\n",trash);
      continue;
    }
    break;
  }
  if(strcmp(buf, "]")==0){
    return 1;
  }

  if(!is_int(buf)){
    fprintf(stderr,"Parse error: expected integer, found `%s`.\n",buf);
    exit(1);
  }
  *readme=atoi(buf);

  return 0;
}

int read_next_double(FILE *fp, double *readme){
  int status;
  char trash[255];
  char buf[255];

  while(1){
    status=fscanf(fp," %s", &buf[0]);

/* Skip over comments */
    if(buf[0]=='#'){
      fscanf(fp,"%[^\n]\n",trash);
      continue;
    }
    break;
  }
  if(!is_double(buf)){
    fprintf(stderr,"Parse error: expected double, found `%s`.\n",buf);
    exit(1);
  }
  *readme=atof(buf);

  return 0;
}

int lookfor(FILE *fp,  char *findme){
  int status;
  char buf[255];
  status=read_next_word(fp, buf);
  if(status!=1){
    fprintf(stderr,"Error reading input file. Can't find `%s`.\n", findme);
     exit(1);
  }

  if(strcmp(findme, buf)!=0){
    fprintf(stderr, "Parse error.  Expected `%s`, found `%s`.\n",findme, buf);
    exit(1);
  }
  return 0;
}


int get_source(FILE *fp, src_param *source){
  lookfor(fp, "source");
  lookfor(fp, "{");
  lookfor(fp, "position");
  read_next_double(fp, &(source->x));
  read_next_double(fp, &(source->y));
  read_next_double(fp, &(source->z));
  lookfor(fp, "omega");
  read_next_double(fp, &(source->omega));
  lookfor(fp, "beta");
  read_next_double(fp, &(source->beta));
  lookfor(fp, "calir");
  read_next_double(fp, &(source->calir));
  lookfor(fp, "calii");
  read_next_double(fp, &(source->calii));
  lookfor(fp, "}");

  return 0;
} 

int get_detector(FILE *fp, det_param *det){
  lookfor(fp, "detector");
  lookfor(fp, "{");
  lookfor(fp, "position");
  read_next_double(fp, &(det->x));
  read_next_double(fp, &(det->y));
  read_next_double(fp, &(det->z));
  lookfor(fp, "omega");
  read_next_double(fp, &(det->omega));
  lookfor(fp, "calir");
  read_next_double(fp, &(det->calir));
  lookfor(fp, "calii");
  read_next_double(fp, &(det->calii));
  lookfor(fp, "}");

  return 0;
} 

int get_prior(FILE *fp, prior_param *prior ){
  char b_n[255];
  double b_cur, sigma, p;
  int i;
 
  lookfor(fp, "parameters");
  lookfor(fp, "{");

  lookfor(fp, "sigma");
  read_next_double(fp, &sigma);
  prior->sigma=(dtype)sigma;

  lookfor(fp, "p");
  read_next_double(fp, &p);
  prior->p=(dtype)p;

  lookfor(fp, "}");


  lookfor(fp, "neighbors");
  lookfor(fp, "{");
 
  for(i=0; i<26; i++){
    sprintf(b_n, "b%d",i);
    lookfor(fp, b_n);
    read_next_double(fp, &b_cur);
    prior->b[i]=(dtype) b_cur;
  }
  lookfor(fp, "}");
     
  return 0;
}
int get_config(FILE *fp, config_param *config){

  lookfor(fp, "physical:");
  read_next_word(fp, &(config->phys_file[0]) );

  lookfor(fp, "prior_D:");
  read_next_word(fp, &(config->prior_D_file[0]) );

  lookfor(fp, "prior_mua:");
  read_next_word(fp, &(config->prior_mua_file[0]) );

  lookfor(fp, "meas:");
  read_next_word(fp, &(config->meas_file[0]) );

  lookfor(fp, "mu_store_flag:");
  read_next_int(fp, &(config->mu_store_flag) );

  lookfor(fp, "muhat_path:");
  read_next_word(fp, &(config->muhatpath[0]) );

  lookfor(fp, "RESULT_path:");
  read_next_word(fp, &(config->resultpath[0]) );

  lookfor(fp, "D_background:");
  read_next_double(fp, &(config->D_backg));

  lookfor(fp, "mua_background:");
  read_next_double(fp, &(config->mua_backg));

/* Milstein */
  lookfor(fp, "init_guess_flag:");
  read_next_int(fp, &(config->init_guess_flag) );
 
  lookfor(fp, "init_guess_path:");
  read_next_word(fp, &(config->init_guess_path[0]) );
 
  lookfor(fp, "init_guess_varname:");
  read_next_word(fp, &(config->init_guess_varname[0]) );
/**/ 

  lookfor(fp, "calibration_flag:");
  read_next_int(fp, &(config->calibration_flag));

  lookfor(fp, "homogeneous_flag:");
  read_next_int(fp, &(config->homogeneous_flag));

/* Milstein - BEGIN */
  lookfor(fp, "global_weight_flag:");
  read_next_int(fp, &(config->global_weight_flag));

  lookfor(fp, "init_wgtr:");
  read_next_double(fp, &(config->init_wgtr));

  lookfor(fp, "init_wgti:");
  read_next_double(fp, &(config->init_wgti));
/* Milstein - END */           

  lookfor(fp, "D_flag:");
  read_next_int(fp, &(config->D_flag));

  lookfor(fp, "mua_flag:");
  read_next_int(fp, &(config->mua_flag));

  lookfor(fp, "ICD_iterations:");
  read_next_int(fp, &(config->niterations));

  lookfor(fp, "rmse_tolerance:");
  read_next_double(fp, &(config->rmse_tol));

  lookfor(fp, "alpha_lower_bound:");
  read_next_double(fp, &(config->alpha_bound));

  lookfor(fp, "borderi:");
  read_next_int(fp, &(config->borderi));

  lookfor(fp, "borderj:");
  read_next_int(fp, &(config->borderj));

  lookfor(fp, "borderl:");
  read_next_int(fp, &(config->borderl));

  lookfor(fp, "border_update_flag:");
  read_next_int(fp, &(config->border_update_flag));

  lookfor(fp, "hmax:");
  read_next_int(fp, &(config->hmax));

  return 0;
}

int get_phys(FILE *fp, phys_param *phys){
  double v_dbl;

  lookfor(fp, "physical");
  lookfor(fp, "{");

  lookfor(fp, "xmin");
  read_next_double(fp, &(phys->xmin));
  lookfor(fp, "xmax");
  read_next_double(fp, &(phys->xmax));
  lookfor(fp, "ymin");
  read_next_double(fp, &(phys->ymin));
  lookfor(fp, "ymax");
  read_next_double(fp, &(phys->ymax));
  lookfor(fp, "zmin");
  read_next_double(fp, &(phys->zmin));
  lookfor(fp, "zmax");
  read_next_double(fp, &(phys->zmax));

  lookfor(fp, "Ni");
  read_next_int(fp, &(phys->Ni));
  lookfor(fp, "Nj");
  read_next_int(fp, &(phys->Nj));
  lookfor(fp, "Nl");
  read_next_int(fp, &(phys->Nl));
  
  lookfor(fp, "K");
  read_next_int(fp, &(phys->K));
  lookfor(fp, "M");
  read_next_int(fp, &(phys->M));

  lookfor(fp, "v");
  read_next_double(fp, &v_dbl);

  phys->v=(mtype)v_dbl;
  lookfor(fp, "}");
  return 0;
} 

int get_connections(FILE *fp, phys_param *phys, 
              src_param *src, det_param *det){
  LINK2D sparse;
  LINK   cur;
  int K, M, k=0, s=0, src_num;
  int first_det_flag=1;
  int status, d;

  sparse=phys->sparse;

  K = phys->K;
  M = phys->M;

  lookfor(fp,"connections");
  lookfor(fp,"{");

  s=0;
  for(k=0; k<K; k++){ 
    read_next_int(fp, &src_num);
    if(src_num!=k){
      fprintf(stderr,"Parse error: in connection list, sources out of order.\n");
      exit(1);
    }
    lookfor(fp,"[");
   
    cur=sparse->d;
    first_det_flag=1;
    while(1){
      status=read_next_int_or_brace(fp, &d);
      if(status==1) {
        break;
      }
      if(!first_det_flag){
        append_to_list(cur);
        cur=cur->next;
      }
      cur->d=d;
      if(det[d].omega!=src[k].omega){
        fprintf(stderr,"Error: found source and detector with different omega.\n");
        exit(1);
      }
      s++;
      first_det_flag=0;
    }
 
    if(k!=(K-1)){
      status=append_to_list_2d(sparse);
      if(status!=0){
        fprintf(stderr,"Problem generating connection list in memory.\n");
        exit(1);
      }
      sparse=sparse->next;
    }
  }

  lookfor(fp,"}");
  phys->S=s;
  printf("S: %d\n", phys->S);
  return 0;
}

phys_param *alloc_phys_param(void){
  
  phys_param *physparam;
  physparam=(phys_param *)malloc(sizeof(phys_param));

  /* Set physics parameters */
  physparam = (phys_param *) malloc(sizeof(phys_param));
  physparam->xmin =0.0;
  physparam->xmax =0.0;
  physparam->ymin =0.0;
  physparam->ymax =0.0;
  physparam->zmin =0.0;
  physparam->zmax =0.0;
  physparam->Ni = 1;
  physparam->Nj = 1;
  physparam->Nl = 1;
  physparam->K  = 1;
  physparam->M  = 1;
  physparam->S  = 1;
  physparam->sparse  = create_new_list_2d();
  physparam->v  = 3.0e10;
  
  return physparam;
}

void delete_phys_param(phys_param *phys){
  delete_list_2d(phys->sparse);
  free(phys);
}

void get_all_phys(FILE *fp, phys_param *phys, src_param **src_ptr, det_param **det_ptr){
  src_param *src;
  det_param *det;
  int k, m;

  get_phys(fp, phys);
  src=(src_param *)malloc(sizeof(src_param)*phys->K);
  det=(det_param *)malloc(sizeof(det_param)*phys->M);

  for(k=0; k<phys->K; k++){
    get_source(fp, &src[k]);
  }
  for(m=0; m<phys->M; m++){
    get_detector(fp, &det[m]);
  }
 
  *src_ptr=src;
  *det_ptr=det;
  
  get_connections(fp, phys, src, det);

  return;
}
/*

int main(void){

  FILE *fp=NULL;
  int status;
  char buf[255];
  src_param *src;
  det_param *det;
  phys_param *phys;

  phys=alloc_phys_param();
  fp=fopen("test","r");

  get_all_phys(fp, phys, &src, &det);

  print_int_list_2d(phys->sparse);

  delete_phys_param(phys);
  free(src);
  free(det);
  return 0;
}

*/
