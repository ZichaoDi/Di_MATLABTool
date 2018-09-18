#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "fileop.h"


FILE *datOpen(char *filename, char *mode){
  FILE *fp=NULL;
  char mode2[4];

  if(mode[0]=='w')
    strcpy(mode2, "w+b");
  else
    strcpy(mode2, "rb");
   
  
  fp=fopen( filename, mode2 );
  if(fp==NULL) {
    fprintf(stderr, "Error: can't open `%s`.\n", filename);
    exit(1);
  }
  if(mode[0]=='w')
    initialize_header(fp);
  return fp;
}

void datClose(FILE *fp){
  fclose(fp);
}

int byte_order_test(void){
  int btest=0, *btestptr=NULL;
  int retval;
  char *cptr=NULL;

  btestptr=&btest;
  cptr=(char *)btestptr;
  cptr[0]=1;

  if(btest!=1){
     retval = BIGEND;
  }
  else{
     retval = SMALLEND;
  }

  return retval;
}


int write_int(FILE *fp, int byte_order, int writeme){
  int *writeme_smallend=NULL; 
  int status, i; 
  char *oldchar, newchar[4];

  oldchar= (char *)(&writeme);

  for(i=0; i<4; i++){
    if(byte_order==BIGEND)
      newchar[i]=oldchar[3-i];
    else
      newchar[i]=oldchar[i];
  }
   
  writeme_smallend=(int *)(&newchar[0]);

  status=fwrite( writeme_smallend, sizeof(int), 1, fp);
  return status;
}

int read_int(FILE *fp, int byte_order, int *readme){
  int *readme_smallend=NULL; 
  int status, i; 
  char *newchar, filechar[4];

  readme_smallend=(int *)(&filechar[0]);
  newchar= (char *)(readme);
  
  status=fread( readme_smallend, sizeof(int), 1, fp);
  if(status!=1) return status;

  for(i=0; i<4; i++){
    if(byte_order==BIGEND)
      newchar[i]=filechar[3-i];
    else
      newchar[i]=filechar[i];
  }
  return status;
}


int write_float(FILE *fp, int byte_order, float writeme){
  float *writeme_smallend=NULL; 
  int status, i; 
  char *oldchar, newchar[4];

  oldchar= (char *)(&writeme);

  for(i=0; i<4; i++){
    if(byte_order==BIGEND)
      newchar[i]=oldchar[3-i];
    else
      newchar[i]=oldchar[i];
  }
   
  writeme_smallend=(float *)(&newchar[0]);

  status=fwrite( writeme_smallend, sizeof(float), 1, fp);
  return status;
}

int read_float(FILE *fp, int byte_order, float *readme){
  float *readme_smallend=NULL; 
  int status, i; 
  char *newchar, filechar[4];

  readme_smallend=(float *)(&filechar[0]);
  newchar= (char *)(readme);
  
  status=fread( readme_smallend, sizeof(float), 1, fp);
  if(status!=1) return status;

  for(i=0; i<4; i++){
    if(byte_order==BIGEND)
      newchar[i]=filechar[3-i];
    else
      newchar[i]=filechar[i];
  }
  return status;
}

int write_float_array(FILE *fp, char *name, float *data, int ndims, ...){
  va_list  ap;
  int *dims=NULL;
  int num_elements=1, i, status=0;
  int byte_order=-1;

  byte_order=byte_order_test();

  dims=(int *)malloc((ndims+1)*sizeof(int));  
  if(dims==NULL) return FOERR;

  dims[0]=ndims;

  va_start(ap, ndims);
  for(i=0; i<ndims; i++){
    dims[i+1]=va_arg(ap, int);
    num_elements*=dims[i+1];
  }
  va_end(ap);

  status=add_line_to_header(fp, name, dims);
  if(status!=0) return FOERR;

  status=write_int(fp, byte_order, 0);
  if(status!=1) return FOERR;
  for(i=0; i<num_elements; i++){
    status=write_float(fp, byte_order, data[i]);
    if(status!=1) return FOERR;
  }
 
  free(dims);
  return 0;

}

int read_float_array(FILE *fp, char *name, float *data, int ndims, ...){
  va_list  ap;
  int *dims=NULL;
  int byte_order=-1;
  int num_elements=1, i, status;
  int argflag=0, *dim_array_arg=NULL;

  byte_order=byte_order_test();

  dims=(int *)malloc((ndims+1)*sizeof(int));  
  if(dims==NULL) return FOERR;

  dims[0]=ndims;

  va_start(ap, ndims);

  argflag=va_arg(ap, int);
  if(argflag==-1) {
    dim_array_arg=va_arg(ap, int *);
  }
  else{
    dims[1]=argflag;
    num_elements*=dims[1];
  }

  for(i=0; i<(ndims); i++){
    if(argflag==-1){
      dims[i+1]=dim_array_arg[i];
    }
    else{
      if(i==0) continue;
      dims[i+1]=va_arg(ap, int);
    }
    num_elements*=dims[i+1];
  }
  va_end(ap);

  status=find_array_with_name(fp, name, dims);
  if(status!=0) return FOERR;

/*  printf("Num elements %d\n", num_elements);
  for(i=0; i<(ndims+1); i++){
    printf("dims(%d) is %d\n", i, dims[i]);
  }
*/
  for(i=0; i<num_elements; i++){
    status=read_float(fp, byte_order, &data[i]);
    if(status!=1) return FOERR;
  }

 
  free(dims);
  return 0;

}


int add_line_to_header(FILE *fp, char *name, int *dims){
  char testch='i';
  int status=-1, i;

  rewind(fp);

  for(i=0; i<HEADERSIZE-1; i++){
    status=fscanf(fp,"%c",&testch);    
    if(testch=='_') break;
  }
  if(testch!='_'){
    fprintf(stderr,"add_line_to_header:\n");
    fprintf(stderr,"Header is full. Cannot add %s\n",name);
    return FOERR;
  }

  fseek(fp, -1, SEEK_CUR);
  fprintf(fp, "> %s %d", name, dims[0]);
  for(i=0; i<dims[0]; i++){
    fprintf(fp, " %d", dims[i+1]);
  }
  fprintf(fp, "\n");

  fseek(fp, 0, SEEK_END);
  return 0;
}

void initialize_header(FILE *fp){
  int i;

  rewind(fp);
 
  for(i=0; i<HEADERSIZE; i++){
    fprintf(fp, "%c",'_');
  }

  return;
}


int find_array_with_name(FILE *fp, char *name, int *dims){
  char buf[HEADERSIZE+1], testch;
  int i,j, dim_cur, status, ndims, offset_sum=0, 
     dim_product=1, sanity_test=-1, byte_order=-1;

  byte_order=byte_order_test();
  rewind(fp);

  for(i=0; i<HEADERSIZE-1; i++){
    status=fscanf(fp,"%c",&testch);    
    dim_product=1;
    if(testch=='>') {
      fscanf(fp, "%s ", &buf[0]);
      if(strcmp(buf, name)==0){
        break;
      }
      fscanf(fp, "%d ",&ndims);
      for(j=0; j<ndims; j++){
        fscanf(fp, "%d ",&dim_cur);
        dim_product*=dim_cur;
      }
      offset_sum+=dim_product+1;
    }
  }  

  if(strcmp(buf, name)!=0){
    fprintf(stderr,"find_array_with_name:\n");
    fprintf(stderr,"%s not found in file\n",name);
    return FOERR;
  }

  fseek(fp, HEADERSIZE+4*offset_sum, SEEK_SET);

  read_int(fp, byte_order, &sanity_test);
  if(sanity_test!=0){ 
    fprintf(stderr,"read_float_array:\n");
    fprintf(stderr,"File header discrepancy. Can't read %s\n",name);
    return FOERR;
  }

  return 0;
}

/*
int main(void){
  float bme[5]={1.1, 2.2, 3.3, 4.4, 5.5};
  float cme[6]={1.2, 2.3, 3.4, 4.5, 5.6, 6.7};
  float dme[4]={1.6, 2.6, 3.6, 4.6};
  float readme[6];
  int byte_order=-1, num_preceding, i;
  int dims[3]={1, 2, 2};
  FILE *fp_write, *fp_read;

  fp_write=datOpen("stuff.txt", "w+b");

  write_float_array(fp_write, "bme", &bme[0], 5,1,1,1,1,5);
  write_float_array(fp_write, "cme", &cme[0], 3,2,2,2);
  write_float_array(fp_write, "dme", &dme[0], 1,4);
  write_float_array(fp_write, "cme", &cme[0], 1,6);
  write_float_array(fp_write, "bme", &bme[0], 1,5);
 
  read_float_array(fp_write, "dme", &readme[0], 2,2,2);
  for(i=0; i<4; i++){
    printf("%f\n",readme[i]);
  }


  datClose(fp_write);
  return 0;
     
}
*/
