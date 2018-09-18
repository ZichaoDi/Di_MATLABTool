close all
clear
clc

global constant
constant = getConstant;

% define energies
en = [10 12];                                   % energy [keV]

% parameters
pars.R1 = 100;                                  % source-to-object distance [cm]
pars.R2 = 50;                                  % object-to-detector distance [cm]
pars.detN = 200;                                % detector number of grids
pars.pixelSize = 55e-4;                         % sample pixel size on x-axis [cm]
pars.detLen = pars.pixelSize*(pars.detN-1);     % detector length [cm]
pars.M = (pars.R1+pars.R2)./pars.R1;         	% image magnification factor
pars.noiseFlag = 1;                             % flag for noisy simulation

fluence = 5e+5;                                 % fluence per pixel

% object definition
obj.mat =  {'pom','pmma','water','ldpe'};
obj.cen = [0 0 -0.18;0 0 -0.05;0 0 0.073;0 0 0.2];
obj.axe = [;0.033 100 0.033;0.023 100 0.023;0.02 100 0.02;0.04 100 0.04];
% obj.mat =  {'pmma','pmma','pmma','pmma','pmma','pmma'};
% obj.cen = [0 0 -0.3;0 0 -0.225;0 0 -0.125;0 0 -0.05;0 0 0.1;0 0 0.25];
% obj.axe = [0.0025 100 0.0025;0.005 100 0.005;0.01 100 0.01;0.02 100 0.02;0.03 100 0.03;0.04 100 0.04];

Id = zeros(pars.detN,pars.detN,length(en));
for m = 1:length(en)
    pars.energy = en(m);
    
    % energy range of the source
    energy = getEnergyPar(pars.energy);
    
    % generate object
    obj = calcObj(obj,energy);
    
    % calc intensity
    [Idet Iff]  = calcIntensity(energy,pars,obj,fluence,-1);
    
    % flat-field corrected intensity
    Id(:,:,m) = Idet./Iff;
end


% --------------------------------
%    RECOVERY OF MU AND DELPHI
% --------------------------------

% measurement energy
energy = getEnergyPar(en);   

% measured data
I = -log(Id);

e = getEnergyPar(en(1));
C = zeros(energy.n,2);
for m = 1:energy.n
    C(m,:) = [2*e.k.^4./energy.k(m).^3 -(2*pars.R2./pars.pixelSize).*e.k.^2./energy.k(m).^2];
end

invC = pinv(C'*C)*C';
A = zeros(pars.detN,pars.detN,2);
for m = 1:pars.detN
    for n = 1:pars.detN
        A(m,n,:) = invC*squeeze(I(m,n,:));
    end
end

beta = A(:,:,1);
delDelta = A(:,:,2);

% control
energy = getEnergyPar(en(1)); 
obj = calcObj(obj,energy);
prj = calcProj(energy,pars,obj);
[~,dY] = gradient(prj.delta,pars.pixelSize);

% visualize
figure('position',[0 400 300 250])
imagesc(Id(:,:,1))
colormap gray
axis equal image
title('measurement 1')

figure('position',[0 0 300 250])
imagesc(Id(:,:,2))
colormap gray
axis equal image
title('measurement 2')

figure('position',[400 0 300 250])
plot(Id(:,pars.detN/2,1),'r','linewidth',2)
hold on
plot(Id(:,pars.detN/2,2),'g','linewidth',2)
grid on
title('crosssection of measurements')

figure('position',[1200 400 300 250])
plot(delDelta(:,pars.detN/2),'linewidth',2)
title('crosssection of recovered del phi')
hold on
plot(dY(:,pars.detN/2),'r')
grid on

figure('position',[1200 0 300 250])
plot(beta(:,pars.detN/2),'linewidth',2)
title('crosssection of recovered absorption')
hold on
plot(prj.beta(:,pars.detN/2),'r')
grid on

figure('position',[800 400 300 250])
imagesc(delDelta)
title('recovered del phi')
colormap gray
axis equal image
colorbar

figure('position',[800 0 300 250])
imagesc(beta)
title('recovered absorption')
colormap gray
axis equal image
colorbar






