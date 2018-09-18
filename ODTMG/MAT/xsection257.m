function xsection(mu,u,l);

cmax = 0.12;
cmin = 0.00;

% set(0,'defaultaxesfontsize',28);  % for josaa

set(0,'defaultaxesfontsize',30);    % for isbi02

x=[-4:0.125/4:4]; 
y=[-4:0.125/4:4]; 
%x=[-2.241:2.241*2/32:2.241]; 
%y=[-2.241:2.241*2/32:2.241]; 
%for i=1:256, m(i)=sqrt(abs((i-256)/255)^3); end,
for i=1:256, m(i)=1/2*(1+cos((i-1)/255*pi)); end,
%m=1/255*[255:-1:0]; 
mycmap=[m.' m.' m.']; 
colormap(mycmap); 

h=surf(x,y,shiftdim(mu(u,:,:,l))); 
axis([-3 3 -3 3 0 0.16]);
%axis([-2 2 -2 2 0 0.1]);

view([0 0 1]); 
daspect([1 1 1/100]); 
shading flat; 
rotate(h,[0 90],-90); 
axis on;
box on; 
set(gca, 'XTickLabelMode', 'manual', 'XTick', [], 'XTickLabel', []);
set(gca, 'YTickLabelMode', 'manual', 'YTick', [], 'YTickLabel', []);

if u==1,
  caxis([cmin cmax]);
elseif u==2,
  caxis([0 0.04]);
end
colorbar('vert');
