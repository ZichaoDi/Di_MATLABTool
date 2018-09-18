function out=morexsection(X,Y,Z, f, colorz, map_flag)
% function out=moreplot(X,Y,Z, f, colorz, map_flag)
figure;
%set(gcf, 'DefaultAxesFontSize',30);


for i=1:16
  subplot(4,4,i);
  surf(X,Y,f(:,:,2*i));
  axis([min(X) max(X) min(Y) max(Y) colorz(1) colorz(2)]);
  view(0,90);
  shading flat;
%  xlabel('x (cm)');
%  ylabel('y (cm)');
  title([ 'z=' num2str(Z(2*i)) ' cm' ]);
  caxis(colorz);
  m=[255:-1:0]'/255;
  if mod(i,4)==0, 
    if map_flag==1
      colormap([m m m]);
    else
      colormap('gray');
    end
  end
  pos1=get(gca,'Position');
%  set(gca,'Position', pos1+[.017 .038 -.07 .00])

  cb=colorbar;

  pos2=get(cb, 'Position');
%  set(cb,'Position', pos2+[-.02 .00 -0.00 0])
end
