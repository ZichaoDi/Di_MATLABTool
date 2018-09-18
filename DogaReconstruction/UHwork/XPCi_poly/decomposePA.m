function out = decomposePA(pars,Idet,Iff)

global constant

% define energy bin
energy = getEnergyPar(pars.binMedian);

% flat-field corrected data
I = -log(Idet./Iff);

% Fourier transform of data
ffti = fftShift(fft2(I));

% calculate the bin weighting based on CNR
W = getBinWeights(energy,pars,Idet);

% frequency sampling
du = 2*pi./pars.detLen.*((-pars.detN+1)/2:(pars.detN-1)/2);

% estimation of A1 and A2
A = zeros(pars.detN,pars.detN,2);
K = 4*sqrt(2)*constant.a^4*constant.sigmaT;
for m = 1:pars.detN
    m
    for n = 1:pars.detN
        
        c1 = K.*energy.E.^(-3.4);
        c2 = energy.sigmaC-(pars.state*2*pars.R2./pars.pixelSize).*(2*pi.*constant.re./energy.k.^2).*(1i.*du(m));
        C = [c1' c2'];
        
        % calculate effective atomic number and effective electron density
        A(m,n,:) = pinv(C'*W*C)*C'*W*squeeze(ffti(m,n,:));
        
    end
end

out.intRhoZ = real(ifft2(fftshift(A(:,:,1))));
out.intRho = real(ifft2(fftshift(A(:,:,2))));

end

function W = getBinWeights(energy,pars,Idet)
% calculates the bins based on CNR

if pars.energyWeighting == 0 % no regularization
    W = diag(ones(pars.binN,1));
    
elseif pars.energyWeighting == 1 % covariance regularization
    W = zeros(1,energy.n);
    for m = 1:energy.n
        Id = Idet(:,:,m);
        W(m) = mean(sqrt(Id(:))./Id(:)).^-1; % data covariance
        
    end
    W = diag(W);
    
elseif pars.energyWeighting == 2 % laplace regularization
    
end

end

function x = fftShift(x)

x = x([ceil(end/2)+1:end 1:ceil(end/2)],[ceil(end/2)+1:end 1:ceil(end/2)],:);

end




