close all
clear
clc

global constant
constant = getConstant;

% define energies
en = [25 50];                                   % energy [keV]

% parameters
pars.R1 = 100;                                  % source-to-object distance [cm]
pars.R2 = 50;                                  % object-to-detector distance [cm]
pars.detN = 200;                                % detector number of grids
pars.pixelSize = 55e-4;                         % sample pixel size on x-axis [cm]
pars.detLen = pars.pixelSize*(pars.detN-1);     % detector length [cm]
pars.M = (pars.R1+pars.R2)./pars.R1;         	% image magnification factor
pars.noiseFlag = 1;                             % flag for noisy simulation

fluence = 1e+7;                                 % fluence per pixel

% object definition
obj.mat =  {'pom','pmma','water','ldpe'};
obj.cen = [0 0 -0.16;0 0 -0.05;0 0 0.073;0 0 0.2];
obj.axe = [;0.032 100 0.032;0.023 100 0.023;0.02 100 0.02;0.04 100 0.04];
% obj.mat =  {'glandular_hammerstein','lesion_hammerstein','lesion_hammerstein'};
% % obj.mat =  {'adipose_hammerstein','lesion_hammerstein','glandular_hammerstein'};
% obj.cen = [0 0 0;0 0 -0.05;0 0 0.05];
% obj.axe = [0.1 100 0.1;0.035 100 0.035;0.035 100 0.035];
% obj.mat =  {'glandular_hammerstein','lesion_hammerstein'};
% % obj.mat =  {'adipose_hammerstein','lesion_hammerstein','glandular_hammerstein'};
% obj.cen = [0 0 0;0 0 -0.05];
% obj.axe = [0.1 100 0.1;0.035 100 0.035];

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

% Fourier transform of data
ffti = fftShift(fft2(I));

% frequency sampling
du = 2*pi./pars.detLen.*((-pars.detN+1)/2:(pars.detN-1)/2);

% estimation of A1 and A2
A = zeros(pars.detN,pars.detN,2);
K = 4*sqrt(2)*constant.a^4*constant.sigmaT;
for m = 1:pars.detN
    for n = 1:pars.detN
        
        c1 = K.*energy.E.^(-3.4);
        c2 = energy.sigmaC+(2*pars.R2./pars.pixelSize).*(2*pi.*constant.re./energy.k.^2).*(1i.*du(m));
        C = [c1' c2'];
        
        % calculate effective atomic number and effective electron density
        A(m,n,:) = pinv(C'*C)*C'*squeeze(ffti(m,n,:));
        
    end
end

intRhoZ = real(ifft2(fftshift(A(:,:,1))));
intRho = real(ifft2(fftshift(A(:,:,2))));

% energy = getEnergyPar(en(1));
% muCalc = 4*sqrt(2)*constant.a^4*constant.sigmaT/energy.E^3.4*intRhoZ+energy.sigmaC.*intRho;
% absCalc = 4*sqrt(2)*constant.a^4*constant.sigmaT/energy.E^3.4*intRhoZ;
% delPhi = -(I(:,:,1)-muCalc)/(2*pars.R2./pars.pixelSize);

% control
energy = getEnergyPar(30);
obj = calcObj(obj,energy);
proj = calcProj(energy,pars,obj); 
[~,dY] = gradient(proj.delta,pars.pixelSize);

absTrue = 4*pi./energy.lambda.*proj.beta;
absCalc = 4*sqrt(2)*constant.a^4*constant.sigmaT/energy.E^3.4*intRhoZ;
phiTrue = energy.k*proj.delta;
phiCalc = 2*pi*constant.re/energy.k*intRho;
attTrue = proj.mu;
attCalc = 4*sqrt(2)*constant.a^4*constant.sigmaT/energy.E^3.4*intRhoZ+energy.sigmaC.*intRho;
[~,delPhiCalc] = gradient(phiCalc,pars.pixelSize);
absCalc(absCalc < 0) = 0;
phiCalc(phiCalc < 0) = 0; 
attCalc(attCalc < 0) = 0; 

figure('position',[0 0 300 250])
imagesc(attCalc)
% title('recovered del phi')
colormap gray
axis equal image
colorbar

figure('position',[0 400 300 250])
plot(attCalc(:,pars.detN/2),'linewidth',2)
% title('crosssection of recovered absorption')
hold on
plot(attTrue(:,pars.detN/2),'r')
grid on





figure('position',[1200 400 300 250])
plot(phiCalc(:,pars.detN/2),'linewidth',2)
% title('crosssection of recovered del phi')
hold on
plot(phiTrue(:,pars.detN/2),'r')
grid on

figure('position',[1200 0 300 250])
plot(absCalc(:,pars.detN/2),'linewidth',2)
% title('crosssection of recovered absorption')
hold on
plot(absTrue(:,pars.detN/2),'r')
grid on

figure('position',[1200 800 300 250])
plot(gradient(phiCalc(:,pars.detN/2),pars.pixelSize),'linewidth',2)
% title('crosssection of recovered del phi')
hold on
plot(gradient(phiTrue(:,pars.detN/2),pars.pixelSize),'r')
grid on


figure('position',[800 0 300 250])
imagesc(absCalc)
% title('recovered absorption')
colormap gray
axis equal image
colorbar

figure('position',[800 400 300 250])
imagesc(phiCalc)
% title('recovered del phi')
colormap gray
axis equal image
colorbar

figure('position',[800 1200 300 250])
imagesc(gradient(phiCalc',pars.pixelSize)')
% title('recovered del phi')
colormap gray
axis equal image
colorbar













err1 = (phiCalc(:,pars.detN/2)-phiTrue(:,pars.detN/2));%./phiTrue(:,pars.detN/2);
err1(abs(err1) == inf) = 0;
figure('position',[400 0 300 250])
plot(abs(err1),'r','linewidth',2)
grid on

errPhi1 = sum(abs(err1(1:60)))./25;
errPhi2 = sum(abs(err1(61:105)))./18;
errPhi3 = sum(abs(err1(106:150)))./16;
errPhi4 = sum(abs(err1(151:200)))./30;
errPhi = [errPhi1 errPhi2 errPhi3 errPhi4];

err2 = (absCalc(:,pars.detN/2)-absTrue(:,pars.detN/2));%./absCalc(:,pars.detN/2);
err2(abs(err2) == inf) = 0;
figure('position',[400 400 300 250])
plot(abs(err2),'r','linewidth',2)
grid on

errAbs1 = sum(abs(err2(1:60)))./25;
errAbs2 = sum(abs(err2(61:105)))./18;
errAbs3 = sum(abs(err2(106:150)))./16;
errAbs4 = sum(abs(err2(151:200)))./30;
errAbs = [errAbs1 errAbs2 errAbs3 errAbs4];

qTrue = gradient(phiTrue(:,pars.detN/2),pars.pixelSize);
qCalc = gradient(phiCalc(:,pars.detN/2),pars.pixelSize);
err3 = (qCalc-qTrue);%./absCalc(:,pars.detN/2);
err3(abs(err3) == inf) = 0;
figure('position',[400 1200 300 250])
plot(abs(err3),'r','linewidth',2)
grid on

% figure('position',[1200 0 300 250])
% bar(errAbs)
% grid on
% figure('position',[1200 0 300 250])
% bar(errPhi,'r')
% grid on

% % visualize
% figure('position',[0 400 400 300])
% imagesc(Id(:,:,1))
%  colormap(gray(1e4))
% axis equal image
% title('measurement 1')
% 
% figure('position',[0 0 400 300])
% imagesc(Id(:,:,2))
%  colormap(gray(1e4))
% axis equal image
% title('measurement 2')
% 
% figure('position',[400 0 400 300])
% plot(Id(:,pars.detN/2,1),'r','linewidth',2)
% hold on
% plot(Id(:,pars.detN/2,2),'g','linewidth',2)
% grid on
% title('crosssection of measurements')
% 
% figure('position',[1200 400 400 300])
% plot(delPhi(:,pars.detN/2),'linewidth',2)
% hold on
% plot(dY(:,pars.detN/2),'r','linewidth',2)
% plot(delPhiCalc(:,pars.detN/2),'g','linewidth',2)
% grid on
% 
% figure('position',[1200 0 400 300])
% plot(absCalc(:,pars.detN/2),'linewidth',2)
% title('crosssection of recovered values')
% hold on
% plot(absTrue(:,pars.detN/2),'r')
% grid on
% 
% figure('position',[800 400 400 300])
% imagesc(delPhi)
% % title('recovered del phi new method')
%  colormap(gray(1e4))
% axis equal image
% colorbar
% 
% figure('position',[800 0 400 300])
% imagesc(muCalc)
% % title('recovered absorption')
% colormap(gray(1e4))
% axis equal image
% colorbar
% 
% figure('position',[400 400 400 300])
% imagesc(phiCalc)
% % title('recovered del phi')
% colormap(gray(1e4))
% axis equal image
% colorbar






