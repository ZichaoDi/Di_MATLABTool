% biosample;
%%=======k: index of element
%         A      a     b     c     x0      y0      z0    phi  theta    psi
k=3;
e=cell(k,1);
if(k==1)
    e =  [  1  .6900  .920  .810      0       0       0     -18      0      10];
elseif(k==2)
    e=[2  .6900*0.8  .920*0.7  .780      0  -.0184       0      18      0      10];
elseif(k==3)
    n=10;
    r=0.06;
    a=.6900-r;  b=.920-r;  c=.810-r;
%     rng('shuffle');
%     pert=randi(2,[n,1]);pert(pert==2)=-1;
%     x=pert.*sqrt(rand(n,1)*0.33*(a^2));
%     y=-pert.*sqrt(rand(n,1)*0.33*(b^2));
%     pert=randi(2,[n,1]);pert(pert==2)=-1;
%     z=pert.*sqrt(c^2.*(1-x.^2./(a^2)-y.^2./(b^2)));
    theta=pi*rand(n,1); phi=2*pi*rand(n,1);
    x=a*sin(theta).*cos(phi);
    y=b*sin(theta).*sin(phi);
    z=c.*cos(theta);
    e{1} =  [  1000  .6900  .920  .810      0       0       0     0*-18      0      0*10];
    e{2}=[50  .6900*0.8  .920*0.7  .780      0  -.0184       0      0*18      0     0*10];
    e{3}=[20*ones(n,1),r*ones(n,3),x,y,z,zeros(n,3)];
end
pp=e{1}+e{2}+e{3};
N=100;
for i=1:k
    O(:,:,:,i)=phantom3d(e{i},N);
end
numThetan=360;
Ztot=[15,30,26];
for slice=1:100
    for k=1:4
        k
        slice
        if(k<4)
            W=squeeze(O(:,:,slice,k));
            NumElement=1;
            Z=Ztot(k);
        elseif(k==4)
            W=squeeze(O(:,:,slice,1:3));
            NumElement=3;
            Z=Ztot;
        end
        XTM_Tensor;
        proj(:,:,slice,k)=XTM;
    end
end
save('proj_20micron.mat', 'proj');
return;
for i=1:numThetan
    imwrite(squeeze(fe(i,:,:)),'proj_Fe_0.tif','WriteMode','append');end
return;
pp=map1D(pp,[0,1]);
for i=1:100,imwrite(pp(:,:,i),'sample.tif','WriteMode','append');end
