% close all
clear
clc

global constant
constant = getConstant;

% parameters
pars.tubeV = 30;                                % tube voltage [kVp]
pars.tubeFilter = 'al';                         % tube filtration
pars.filterThickness = 0;                       % filter thickness [cm]
pars.dose = 4;                                  % absorbed dose [mGy]
pars.R1 = 100;                                  % source-to-object distance [cm]
pars.R2 = 100;                                  % object-to-detector distance [cm]
pars.detN = 140;                                % detector number of grids
pars.pixelSize = 80e-4;                         % sample pixel size on x-axis [cm]
pars.detLen = pars.pixelSize*(pars.detN-1);     % detector length [cm]
pars.M = (pars.R1+pars.R2)./pars.R1;         	% image magnification factor
pars.detMat = 'cdznte';                         % detector material
pars.detThick = 0.03;                           % detector thickness [cm]
pars.noiseFlag = 1;                             % flag for noisy simulation
pars.energyWeighting = 1;                       % flag for energy weighting
pars.binN = 1;                                  % number of different bins
pars.state = 1;                                 % post-object aperture positioning (1 or -1)
pars.sampleN = 8;                               % sampling of the detector (%4)
    
% object definition
obj.mat =  {'pom','pmma','water','ldpe'};
obj.cen = [0 0 -0.16;0 0 -0.05;0 0 0.073;0 0 0.2];
obj.axe = [;0.032 100 0.032;0.023 100 0.023;0.02 100 0.02;0.04 100 0.04];

energy = getEnergyPar(1:pars.tubeV);                        % energy range of the source
fluence = calcSourceSpec(energy,pars);                      % get incident fluence per detector
pars.threshold = calcEqualBins(energy,pars,fluence);        % define thresholds
obj = calcObj(obj,energy);                                  % generate object
[Idet1 Iff1]  = calcIntensity(energy,pars,obj,fluence);       % calculate intensity at each bin

pars.state = -1;                                 
[Idet2 Iff2]  = calcIntensity(energy,pars,obj,fluence);       % calculate intensity at each bin

% attenuation and phase recovery
I1 = Idet1./Iff1;
I2 = Idet2./Iff2;
mu = -log((I1+I2)/2);
delPhi = pars.pixelSize/(2*pars.R2)*(I1-I2)./(I1+I2);

% control
energy = getEnergyPar(26);
obj = calcObj(obj,energy);
proj = calcProj(energy,pars,obj); 
[~,dY] = gradient(proj.delta,pars.pixelSize);

figure('position',[800 0 400 300])
imagesc(mu)
set(gca,'xtick',0:20:1000)
set(gca,'ytick',0:20:1000)
axis equal image
title('Attenuation')
colormap gray
% saveas(gcf,'/home/doga/Desktop/XPCimgs/dpcAtt','eps')

figure('position',[800 400 400 300])
imagesc(-delPhi)
set(gca,'xtick',0:20:1000)
set(gca,'ytick',0:20:1000)
axis equal image
title('Phase')
colormap gray
% saveas(gcf,'/home/doga/Desktop/XPCimgs/dpcPhi','eps')

figure('position',[1200 400 400 300])
plot(-delPhi(:,pars.detN/2),'linewidth',2)
hold on
plot(dY(:,pars.detN/2),'r','linewidth',2)
grid on

figure('position',[1200 0 400 300])
plot(mu(:,pars.detN/2),'linewidth',2)
title('crosssection of recovered values')
hold on
plot(proj.mu(:,pars.detN/2),'r','linewidth',2)
grid on

figure('position',[0 400 400 300])
imagesc(Idet1)
set(gca,'xtick',0:20:1000)
set(gca,'ytick',0:20:1000)
colormap gray
axis equal image
% saveas(gcf,'/home/doga/Desktop/XPCimgs/dpcData1','eps')

figure('position',[0 0 400 300])
imagesc(Idet2)
set(gca,'xtick',0:20:1000)
set(gca,'ytick',0:20:1000)
colormap gray
axis equal image
% saveas(gcf,'/home/doga/Desktop/XPCimgs/dpcData2','eps')

figure('position',[400 0 400 300])
plot(Idet1(:,pars.detN/2),'r','linewidth',2)
hold on
plot(Idet2(:,pars.detN/2),'g','linewidth',2)
grid on
title('crosssection of measurements')







