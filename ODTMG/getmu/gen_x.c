/* 
 * This is an example C code to generate a synthetic simulated phantom object.
 * 
 * mu[0][][][]: 3-D absorption (mu_a) image 
 * mu[1][][][]: 3-D diffusion (D) image 
 *
 * Change Ni, Nj, Nl to specify # of grid points.
 * Change the code to change specification of image.
 */


#include "defs.h"

/* BEGIN- Specification of grid points in image */
#define Ni  65  
#define Nj  65
#define Nl  65
/* END- Specification of grid points in image */


int main(int argc, char *argv[]){
  char datname[255] ; 
  char varname[255] ; 
  FILE *fpd;
  float mu[2][Ni][Nj][Nl]; 
  int n, u, i, j, l, bi, bj, bl;

  if(argc!=2){
    printf("Usage: %s filename\n",argv[0]);
    exit(-1);
  }

  strcpy(datname, argv[1]);
  strcpy(varname, "mu");
  strcat(datname, ".dat");

/* BEGIN- Specification of image */  
  bi = 4; 
  bj = 4;
  bl = 4;
  
  for(i=0; i<Ni; i++)
  for(j=0; j<Nj; j++)
  for(l=0; l<Nl; l++) {
    mu[0][i][j][l] = 0.02;
    mu[1][i][j][l] = 0.03;
  }

  for(i=bi; i<Ni-bi; i++)
  for(j=bj; j<Nj-bj; j++)
  for(l=bl; l<Nl-bl; l++) {
    mu[0][i][j][l] += 0.01 + (i-17.0)*0.020/13.0;   

    if ( (i-15)*(i-15)+(j-20)*(j-20)+(l-17)*(l-17) < 25.0 ) 
      mu[0][i][j][l] = 0.12;  
  }

  for(u=0; u<2; u++)
  for(i=bi; i<Ni-bi; i++)
  for(j=bj; j<Nj-bj; j++)
  for(l=bl; l<Nl-bl; l++) {
    if (mu[u][i][j][l] < 5.0e-4)
      mu[u][i][j][l] = 5.0e-4;
  }
/* END- Specification of image */  

  fpd = datOpen(datname, "w+b");
  write_float_array(fpd, varname, &mu[0][0][0][0], 4, 2, Ni, Nj, Nl);
  datClose(fpd);

  return 0;
}
