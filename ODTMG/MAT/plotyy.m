function plotz(array,option)

maxarray = max(max(max(array)));
minarray = min(min(min(array)));

set(0,'defaultaxesfontsize',10);

stepsize = floor(size(array,2)/16);
%stepsize =1;

nplot=0;
for N=1:stepsize:size(array,2),
  nplot=nplot+1;   
  figure(ceil(nplot/9)),
  subplot(3,3,mod(nplot-1,9)+1),

  if option==1,
%    m=1/255*[255:-1:0]; mycmap=[m.' m.' m.']; colormap(mycmap);
%    caxis([0 0.30]);
    h=surf(abs(shiftdim(shiftdim(array(:,N,:))))); 
    axis([1 size(array,1) minarray  1.11*maxarray-0.1*minarray 1 size(array,3)] );
%    view([0 0 1]); daspect([1 1 1]); shading flat; rotate(h,[0 90],-90);
%    box on; axis off; 
elseif option==2,
    h=surf(real(array(:,N,:))); axis([1 size(array,1) 1 size(array,2) minarray  1.11*maxarray-0.1*minarray ]);  
%    surf(real(array(:,N,:)), 
elseif option==3,
    surf(imag(array(:,N,:))),
end  
  xlabel('i'); ylabel('l');
 
  str = sprintf('j=%d', N);
  title(str), 
  
end
