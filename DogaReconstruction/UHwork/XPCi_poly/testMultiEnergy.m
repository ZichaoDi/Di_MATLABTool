close all
clear
clc

global constant
constant = getConstant;

% parameters
pars.tubeV = 25;                                % tube voltage [kVp]
pars.tubeFilter = 'al';                         % tube filtration
pars.filterThickness = 0;                       % filter thickness [cm]
pars.dose = 8;                                  % absorbed dose [mGy]
pars.R1 = 100;                                  % source-to-object distance [cm]
pars.R2 = 50;                                  % object-to-detector distance [cm]
pars.detN = 200;                                % detector number of grids
pars.pixelSize = 55e-4;                         % sample pixel size on x-axis [cm]
pars.detLen = pars.pixelSize*(pars.detN-1);     % detector length [cm]
pars.M = (pars.R1+pars.R2)./pars.R1;         	% image magnification factor
pars.detMat = 'cdznte';                         % detector material
pars.detThick = 3;                              % detector thickness [cm]
pars.noiseFlag = 1;                             % flag for noisy simulation
pars.energyWeighting = 1;                       % flag for energy weighting
pars.binN = 6;                                  % number of different bins
pars.state = 1;                                 % post-object aperture positioning (1 or -1)
pars.sampleN = 8;                               % sampling of the detector (%4)
pars.thickness = 5;
    
% object definition
obj.mat =  {'pom','pmma','water','ldpe'};
obj.cen = [0 0 -0.16;0 0 -0.05;0 0 0.073;0 0 0.2];
obj.axe = [;0.032 100 0.032;0.023 100 0.023;0.02 100 0.02;0.04 100 0.04];

energy = getEnergyPar(1:pars.tubeV);                        % energy range of the source
fluence = calcSourceSpec(energy,pars);                      % get incident fluence per detector
pars.threshold = calcEqualBins(energy,pars,fluence);        % define thresholds
obj = calcObj(obj,energy);                                  % generate object
[Idet Iff]  = calcIntensity(energy,pars,obj,fluence);       % calculate intensity at each bin
pars.binMedian = calcBinMedian(pars,energy,fluence);        % find energy corresponds to the detected median quanta for each bin
out = decomposePA(pars,Idet,Iff);                           % decompose phase and absorption components
recon = getRecon(pars,out,obj,35);                          % display plots

% control
energy = getEnergyPar(26);
obj = calcObj(obj,energy);
proj = calcProj(energy,pars,obj); 
[~,dY] = gradient(proj.delta,pars.pixelSize);

figure('position',[400 0 400 300])
imagesc(recon.absCalc)
set(gca,'xtick',0:20:1000)
set(gca,'ytick',0:20:1000)
axis equal image
colormap gray

figure('position',[400 400 400 300])
imagesc(recon.phiCalc)
set(gca,'xtick',0:20:1000)
set(gca,'ytick',0:20:1000)
axis equal image off
colormap gray

figure('position',[800 400 400 300])
imagesc(gradient(recon.phiCalc')')
set(gca,'xtick',0:20:1000)
set(gca,'ytick',0:20:1000)
axis equal image off
colormap gray

figure('position',[1200 400 400 300])
plot(recon.phiCalc(:,pars.detN/2),'linewidth',2)
hold on
plot(recon.phiTrue(:,pars.detN/2),'r','linewidth',2)
grid on

figure('position',[1200 0 400 300])
plot(recon.absCalc(:,pars.detN/2),'linewidth',2)
title('crosssection of recovered values')
hold on
plot(recon.absTrue(:,pars.detN/2),'r','linewidth',2)
grid on

% figure('position',[800 1000 400 300])
% [~, dY] = gradient(recon.phiCalc,pars.pixelSize);
% imagesc(dY)
% set(gca,'xtick',0:20:1000)
% set(gca,'ytick',0:20:1000)
% axis equal image
% title('Phase')
% colormap gray
% % saveas(gcf,'/home/doga/Desktop/XPCimgs/xpcGradPhi','eps')

% for m = 1:pars.binN
% %     figure('position',[(m-1)*300 0 300 250])
% %     plot(Idet(:,pars.detN/2,m));hold on
% %     plot(Iff(:,pars.detN/2,m),'r')
% %     grid on
%     
%     figure('position',[(m-1)*300 300 300 250])
%     imagesc(Idet(:,:,m))
%     colormap gray
%     axis equal image
% %     saveas(gcf,['/home/doga/Desktop/XPCimgs1/xpcData',num2str(m)],'eps')
% end
