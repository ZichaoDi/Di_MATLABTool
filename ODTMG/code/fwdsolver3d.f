c234567890123456789022345678903234567890423456789052345678906234567890712
c     
c     fwdsolver3d - Front end for elliptic PDE forward solver.
c     
c     div (alpha * grad (phi)) + beta * phi = rhs
c
c     Arguments:
c    /* Input */
c int *nnx,   /* 3-D array dimensions */
c int *nny,
c int *nnz,
c float *xmin, /* Ranges of physical coords */
c float *xmax,
c float *ymin,
c float *ymax,
c float *zmin,
c float *zmax,
c float *alpha, /* Array containing 1st PDE coeff: In C, alpha[i][j][l][c]
c                * In FORTRAN, alpha(c+1,l+1,j+1,i+1) */
c float *beta,  /* Array containing 2nd PDE coeff: beta[i][j][l][c]
c                * In FORTRAN, beta(c+1,l+1,j+1,i+1) */
c float *rhs,   /* Array containing RHS of PDE : rhs[i][j][l][c]
c                * In FORTRAN, rhs(c+1,l+1,j+1,i+1) */
c int *iguessflag, /* 1 if initial guess should be used, 0 otherwise
c int *workspace,  /* Size of workspace for MUDPACK.
c                   * See cud3.d for more details */
c int *ncycles,    /* Number of multigrid cycles to be used by MUDPACK*/
c                   * See cud3.d for more details */
c                  * See cud3.d for more details */
c /* Input/Output*/
c float *phi       /* Input: initial guess, if iguessflag=1.  Should be
c                   *   initialized to zeros otherwise.
c                   * Output: solution of PDE.  In C, phi[i][j][l][c]
c                   * In FORTRAN, phi(c+1,l+1,j+1,i+1) */
c
c
c   HISTORY
c    10/7/00 Milstein
c
c    10/11/00 Milstein
c      Added last 3 arguments to the function for more flexibility.
c      Implemented them.
c
c    10/13/00 Milstein
c      The answers were wrong for nnx.ne.nny because
c      I improperly accounted for the different array indexing in
c      C and FORTRAN.  (This got by us until now because nnx was 
c      always equal to nny for our test cases previously.)
c      If there is a 2-D array allocated in C using allocate.c fcns,
c      then array[a][b] in C corresponds to array(b+1,a+1) in FORTRAN.
c      Hence, if array is size dim1xdim2 in C, it is size dim2xdim1 in
c      FORTRAN.  
c      I fixed the problem as follows:  in FORTRAN, the argument arrays
c      that were size nnx X nny in C are now size nny X nnx in FORTRAN.
c      Since MUDPACK accepts 2-D arrays in the form array(xcoord,ycoord),
c      I transpose these arrays when converting them to complex matrices
c      to put them in the correct order.  I transpose phi back to the 
c      way it was before upon returning the result back to C.
c      An alternate fix would have been to declare all the arrays 
c      as size nny X nnx, and then tell MUDPACK to solve a 2-D diff eq
c      of dimension nny X nnx, but I thought this was too confusing.
c
c      I also fixed a line which was accidentally overwriting intial
c      guesses for phi!
c
c
      integer function fwd3df(nnx,nny,nnz, xmin, xmax, 
     +              ymin, ymax, zmin, zmax, alpha, 
     +              beta,
     +              rhs, iguessflag, mudpkworkspace, mudpkworksize,
     +              rhsworkspace, phiworkspace,
     +              ncycles, phi) 

      implicit none
      integer nnx, nny, nnz

      real xmin, xmax, ymin, ymax, zmin, zmax,
     +    alpha(2, nnz, nny,nnx), 
     +    beta(2, nnz,nny,nnx),  
     +    rhs(2, nnz,nny,nnx),  
     +    phi(2, nnz,nny,nnx)
      integer iguessflag, mudpkworksize, ncycles

  
      complex rhsworkspace(nnx,nny,nnz),phiworkspace(nnx,nny,nnz)
      complex mudpkworkspace(mudpkworksize)

      integer iprm(23),mgopt(4)
      real fprm(8)
      integer intl,nxa,nxb,nyc,nyd,nze,nzf,ixp,jyq,kzr,
     +              iex,jey,kez,nx,ny,nz,
     +              iguess,maxcy,method,meth2,length,
     +              lwrkqd,itero
      common/itcud3/intl,nxa,nxb,nyc,nyd,nze,nzf,ixp,jyq,kzr,
     +              iex,jey,kez,nx,ny,nz,
     +              iguess,maxcy,method,meth2,length,
     +              lwrkqd,itero

      real xa,xb,yc,yd,ze,zf,tolmax,relmax
      common/ftcud3/xa,xb,yc,yd,ze,zf,tolmax,relmax

      equivalence(intl,iprm)
      equivalence(xa,fprm)
      integer i,j,l,ierror
      real dlx,dly,dlz

c    Statically allocated copy of alpha and beta matrices
      COMMON/DATA2/Acof(129,65,65),Bcof(129,65,65)
      COMPLEX      Acof,Bcof

c
c     declare coefficient and boundary condition input subroutines external
c
      external cof3d,bndc3d
c
      nx=nnx
      ny=nny
      nz=nnz

      do i=1, nx
        do j=1, ny
          do l=1, nz
            rhsworkspace(i,j,l)=cmplx(rhs(1,l,j,i), rhs(2,l,j,i)) 

            if (iguessflag.eq.1) then
              phiworkspace(i,j,l)=cmplx(phi(1,l,j,i), phi(2,l,j,i))
            else
              phiworkspace(i,j,l)=cmplx(0.0,0.0)
            endif
            if (i.eq.1) phiworkspace(i,j,l)=cmplx(0.0,0.0)
            if (j.eq.1) phiworkspace(i,j,l)=cmplx(0.0,0.0)
            if (l.eq.1) phiworkspace(i,j,l)=cmplx(0.0,0.0)
            if (i.eq.nx) phiworkspace(i,j,l)=cmplx(0.0,0.0)
            if (j.eq.ny) phiworkspace(i,j,l)=cmplx(0.0,0.0)
            if (l.eq.nz) phiworkspace(i,j,l)=cmplx(0.0,0.0)

            Acof(i,j,l)=cmplx(alpha(1,l,j,i), alpha(2,l,j,i)) 
            Bcof(i,j,l)=cmplx(beta(1,l,j,i), beta(2,l,j,i)) 
          end do
        end do
      end do
c
c
c     set input integer arguments
c
      intl = 0
c
c     set boundary condition flags
c       for "specified" boundary - pre-initialized to zero
      nxa = 1
      nxb = 1
      nyc = 1
      nyd = 1
      nze = 1
      nzf = 1
c
c     set grid sizes from parameter statements
c
      ixp = 2
      jyq = 2
      kzr = 2
      
      iex=nint(log(float(nx-1))/log(2.0))
      jey=nint(log(float(ny-1))/log(2.0))
      kez=nint(log(float(nz-1))/log(2.0))

c
c     set # of multigrid cycles
c

      maxcy = ncycles

c
c     set work space length approximation from argument
c
      length = mudpkworksize

c
c     set point relaxation
c
      method = 0
      meth2 = 0
c
c     flag determining use of initial guess
c
      iguess = iguessflag
c
c     set end points of solution box in (x,y,z) space
c
      xa = xmin 
      xb = xmax
      yc = ymin
      yd = ymax
      ze = zmin
      zf = zmax
c
c     set mesh increments
c
      dlx = (xb-xa)/float(nx-1)
      dly = (yd-yc)/float(ny-1)
      dlz = (zf-ze)/float(nz-1)
c
c     set for no error control
c
      tolmax = 0.0
c
c     set default multigrid opitons
c
      mgopt(1) = 0
      mgopt(2) = 2
      mgopt(3) = 1
      mgopt(4) = 3
c
c
c
c     intialization call
c
      intl = 0
c
      call cud3(iprm,fprm,mudpkworkspace,cof3d,bndc3d,rhsworkspace,
     +          phiworkspace,mgopt,ierror)
c
c
      if (ierror.ne.0) write (*,105) ierror,length
  105 format(' ierror = ',i2, ' minimum work space = ',i7)
      if (ierror.gt.0) call exit(0)
c
c     attempt solution
c
      intl = 1
      call cud3(iprm,fprm,mudpkworkspace,cof3d,bndc3d,rhsworkspace,
     +          phiworkspace,mgopt,ierror)

      if (ierror.ne.0) write (*,105) ierror,length

      do i=1,nx
        do j=1, ny
          do l=1, nz

            phi(1,l,j,i)=real(phiworkspace(i,j,l))
            phi(2,l,j,i)=aimag(phiworkspace(i,j,l))
          end do
        end do
      end do

  106 format(E10.3, E10.3)

      fwd3df = 0

      return

      end 

C========================================================================
        SUBROUTINE COF3D(X,Y,Z,CXX,CYY,CZZ,CX,CY,CZ,CE)

      integer intl,nxa,nxb,nyc,nyd,nze,nzf,ixp,jyq,kzr,
     +              iex,jey,kez,nx,ny,nz,
     +              iguess,maxcy,method,meth2,length,
     +              lwrkqd,itero
      common/itcud3/intl,nxa,nxb,nyc,nyd,nze,nzf,ixp,jyq,kzr,
     +              iex,jey,kez,nx,ny,nz,
     +              iguess,maxcy,method,meth2,length,
     +              lwrkqd,itero
      COMMON/DATA2/Acof(129,65,65),Bcof(129,65,65)
      COMPLEX      Acof,Bcof

      real xa,xb,yc,yd,ze,zf,tolmax,relmax
      common/ftcud3/xa,xb,yc,yd,ze,zf,tolmax,relmax

      equivalence(intl,iprm)
C subroutine argument

        REAL        X,Y,Z
        COMPLEX     CXX,CYY,CZZ,CX,CY,CZ,CE
C========================================================================


        DLX = (XB-XA)/FLOAT(NX-1)
        DLY = (YD-YC)/FLOAT(NY-1)
        DLZ = (ZF-ZE)/FLOAT(NZ-1)

        I = INT(1.+(X-XA)/DLX+0.001)
        J = INT(1.+(Y-YC)/DLY+0.001)                              
        K = INT(1.+(Z-ZE)/DLZ+0.001)                                            
        CXX = Acof(i,j,k)
        CYY = Acof(i,j,k)
        CZZ = Acof(i,j,k)
        IF ( I .gt. 1 .and. I .lt. NX ) THEN
          CX=cmplx( real(Acof(i+1,j,k)-Acof(i-1,j,k))/(DLX*2.0),0.0 )
        ELSE
          CX=(0.0e0,0.0e0)
        ENDIF
        IF ( J .gt. 1 .and. J .lt. NY ) THEN
          CY=cmplx( real(Acof(i,j+1,k)-Acof(i,j-1,k))/(DLY*2.0),0.0 )
        ELSE
          CY  = (0.0e0,0.0e0)
        ENDIF
        IF ( K .gt. 1 .and. K .lt. NZ ) THEN
          CZ=cmplx( real(Acof(i,j,k+1)-Acof(i,j,k-1))/(DLY*2.0),0.0 )
        ELSE
          CZ  = (0.0e0,0.0e0)
        ENDIF


        CE  =  Bcof(i,j,k)
        RETURN
        END                                              



C========================================================================
        SUBROUTINE BNDC3D(KBDY,XORY,YORZ,ALFA,GBDY)
        real xa,xb,yc,yd,ze,zf,tolmax,relmax
        common/ftcud3/xa,xb,yc,yd,ze,zf,tolmax,relmax
        COMPLEX ALFA,GBDY
        RETURN
        END 
