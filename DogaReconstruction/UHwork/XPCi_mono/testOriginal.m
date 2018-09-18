close all
clear
clc

global constant
constant = getConstant;

% parameters
pars.energy = 12;                               % energy [keV]
pars.R1 = 100;                                  % source-to-object distance [cm]
pars.R2 = 50;                                   % object-to-detector distance [cm]
pars.detN = 100;                                % detector number of grids
pars.pixelSize = 55e-4;                         % sample pixel size on x-axis [cm]
pars.detLen = pars.pixelSize*(pars.detN-1);     % detector length [cm]
pars.M = (pars.R1+pars.R2)./pars.R1;         	% image magnification factor
pars.noiseFlag = 1;                             % flag for noisy simulation

energy = getEnergyPar(pars.energy);             % energy range of the source
fluence = 1e+4;                                 % fluence per pixel

% object definition
% obj.mat =  {'pom','pmma','water','ldpe'};
% obj.cen = [0 0 -0.18;0 0 -0.05;0 0 0.073;0 0 0.2];
% obj.axe = [;0.033 100 0.033;0.023 100 0.023;0.02 100 0.02;0.04 100 0.04];
obj.mat =  {'glandular_hammerstein','glandular_hammerstein','lesion_hammerstein'};
obj.cen = [0 0 0;0 0 -0.05;0 0 0.05];
obj.axe = [0.1 100 0.1;0.025 100 0.025;0.025 100 0.025];
% obj.mat =  {'pmma','pmma','pmma','pmma','pmma','pmma'};
% obj.cen = [0 0 -0.3;0 0 -0.225;0 0 -0.125;0 0 -0.05;0 0 0.1;0 0 0.25];
% obj.axe = [0.0025 100 0.0025;0.005 100 0.005;0.01 100 0.01;0.02 100 0.02;0.03 100 0.03;0.04 100 0.04];

% generate object
obj = calcObj(obj,energy);

% calc intensity
[Idet1 Iff1]  = calcIntensity(energy,pars,obj,fluence,1);    
[Idet2 Iff2]  = calcIntensity(energy,pars,obj,fluence,-1);

% flat-field corrected intensity
I1 = Idet1./Iff1;
I2 = Idet2./Iff2;

% attenuation and phase recovery
mu = -log((I1+I2)/2);
delPhi = pars.pixelSize/(2*pars.R2)*(I1-I2)./(I1+I2);

% control
prj = calcProj(energy,pars,obj);
[~,dY] = gradient(prj.delta,pars.pixelSize);

% visualize
figure('position',[0 400 300 250])
imagesc(I1)
title('measurement 1')
axis equal image
colormap gray
colorbar

figure('position',[0 0 300 250])
imagesc(I2)
title('measurement 2')
axis equal image
colormap gray
colorbar

figure('position',[400 0 300 250])
plot(I1(:,pars.detN/2),'r','linewidth',2)
hold on
plot(I2(:,pars.detN/2),'g','linewidth',2)
grid on
% title('cross section of the measurements')

figure('position',[1200 300 300 250])
plot(delPhi(:,pars.detN/2),'linewidth',2)
grid on
hold on
% title('crosssection of recovered del phi')
plot(-2*dY(:,pars.detN/2),'r')

figure('position',[1200 0 300 250])
plot(mu(:,pars.detN/2),'linewidth',2)
hold on
% title('crosssection of recovered attenuation')
plot(prj.mu(:,pars.detN/2),'r')
grid on

% err1 = (1*dY(:,pars.detN/2)-delPhi(:,pars.detN/2))./(1*dY(:,pars.detN/2));
% err1(abs(err1) == inf) = 1;
% figure('position',[1200 300 300 250])
% plot(err1,'linewidth',2)
% grid on
% 
% err2 = (prj.mu(:,pars.detN/2)-mu(:,pars.detN/2))./prj.mu(:,pars.detN/2);
% err2(abs(err2) == inf) = 1;
% figure('position',[1200 0 300 250])
% plot(err2,'linewidth',2)
% grid on

figure('position',[800 400 300 250])
imagesc(delPhi)
% title('recovered del phi')
axis equal image
colormap gray
colorbar

figure('position',[800 0 300 250])
imagesc(mu)
axis equal image
% title('recovered attenuation')
colormap gray
grid on
colorbar
hold on



