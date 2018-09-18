*************************************************************************

Nonlinear multigrid inversion code for optical diffusion tomography


  Objective:
    - Reconstruct 3-D images of spatially varying optical absorption
      coefficient and diffusion coefficient in a turbid media
      from a frequency-domain optical measurement set
      with an adaptive nonlinear multigrid inversion algorithm


  System requirements: 
    - Originally developed for Linux 
    - Needs gcc and f77 for source compiling and linking
    - Matlab is used only for processing of the resulting data files. 


  Input/output File formats:
    - Configurations files, such as physical parameter file, 
      and image prior parameter file, are text files. 
    - Image and measurement data is written in a "DAT" file format, 
      which we developed.
      The "MAT" subdirectory contains the matlab M-files for processing 
      this file format. 
      The directory ialso contains an I/O example file 
      named "EXAMPLE_DATfileIO.m".
    

  Reference:
   
    - Detailed description of the 'baseline' algorithm can be found at
      "A general framework for nonlinear multigrid inversion",
      Seungseok Oh, Adam Milstein, Charles Bouman, and Kevin Webb
      IEEE Trans. Image Processing, Jan. 2005. 

    - Its extention to adaptively move in scales can be found at 
      "Adaptive nonlinear multigrid inversion with applications
       to Bayesian optical diffusion tomography",
      Seungseok Oh, Adam Milstein, Charles Bouman, and Kevin Webb
      Proc. IEEE Workshop on Statistical Signal Processing,
      St. Louis, MO, USA, Sep. 2003.

    - For the details of the ICD algorithm, see 
      Jong et. al. "Optical diffusion tomography by iterative-
      coordinate-descent optimization in a Bayesian framework",
      JOSA-A, Oct. 1999

      
  Questions or comments:

    - Prof. Charles Bouman 
      Electrical and Computer Engineering
      Purdue University
      bouman@purdue.edu

    - Prof. Kevin Webb
      Electrical and Computer Engineering
      Purdue University
      webb@purdue.edu

    - Seungseok Oh
      Electrical and Computer Engineering
      Purdue University
      ohs@purdue.edu

*************************************************************************

This package consists of 5 subdirectories: 
  1. 'code': inversion source code 
  2. 'example': a test example 
  3. 'getmu': source code used to generate the synthetic phantom in 'example'
  4. 'getmuinit': source code you can use to generate an initialization image 
  5. 'MAT': matlab m-files to read/write/process/visualize image or data, 
            which are stored as our specific 'dat' files

*************************************************************************

This package provides 2 scripts to demonstrate how to use it. 
They will show step-by stepm how to use this package, 
what are the input/output.

  - Type "RUNMEall_with_Matlab" in the current directory
    if you have Matlab available in your machine,
    or type "RUNMEall_without_Matlab" if you don't. 
    
  (Note)  
  1. What the scripts are doing is 
     1) Generate a simulated true phantom in "getmu" directory,
        and copy it to ./example/mg3level_adapt 
     2) Compile and link the source code in "code" directory,
        and copy it to ./example/mg3level_adapt 
     3) Generate a simulated measurement data in ./example/mg3level_adapt
     4) Reconstruct image from the simulated data 
        with 3 level adaptive multigrid
     5) If you are running "RUNMEall_with_Matlab", 
        then a convergence plot will be generated.
  2. The provided script uses a homogeneous image to initialize 
     the image reconstruction.
     If you want to initialize the image reconstruction 
     with your specified image, 
     generate initial image file by running "./getmuinit/RUNME" script 
     and modify the "./example/mg3level_adap/config" file
     following the direction in the file.
     And then, run the script "RUNMEall_with_Matlab".
  3. If you want to use fixed-grid ICD algorithm, 
     replace the "./example/config" file
     with "./example/fixedr_grid/config",
     and then use the script "RUNMEall_with_Matlab". 
     Its reference results can be found in the
     "./example/fixed_grid/REFERENCE_RESULTS" directory.
  4. These scripts assume vi editor is available in your machine.
     If not, please replace 'vi' in the script with your available editor.
  
*************************************************************************

For programmers who want to modify the sources:

  1. "code/README" describes conventions for naming data structures 
  2. All data structures are defined in "code/structs.h".
  3. All necessary functions are declared in "code/defs.h".

*************************************************************************

Good luck!!!


