function [Idet Iff] = calcIntensity(energy,pars,obj,fluence,flag)

% sub-sample detector grid
N = 8;
subSampled = pars;
subSampled.pixelSize = pars.pixelSize/N;      
subSampled.detN = pars.detN*N;
subSampled.detLen = subSampled.pixelSize*(subSampled.detN-1);      
subFluence = fluence/N/N;

% calculate projections
prj = calcProj(energy,subSampled,obj);   

% calculate pre-sample mask
firstMask = circshift(repmat([zeros(N/2,pars.detN*N);ones(N/2,pars.detN*N)],pars.detN,1),-N/4);

% post-sample mask
secondMask = circshift(firstMask,flag*N/4);

% calculate post-sample projections
Iobj = exp(-prj.mu).*firstMask;
prj.delta = prj.delta.*firstMask;

% flat-field intensity at object plane
Iff = fluence/4.*ones(pars.detN,pars.detN);

% TIE propagation after sample
[dX dY] = gradient(prj.delta,subSampled.pixelSize);
[d2X,~] = gradient(Iobj.*dX,subSampled.pixelSize);
[~,d2Y] = gradient(Iobj.*dY,subSampled.pixelSize);
Iwave = subFluence.*(Iobj+pars.R2/pars.M.*(d2X+d2Y));

% calculate intensity after rpost-sample mask
IdetSub = Iwave.*secondMask;

% sum over pixels
Idet = reshape(sum(reshape(IdetSub,N,subSampled.detN*pars.detN)),pars.detN,subSampled.detN);
Idet = reshape(sum(reshape(Idet',N,pars.detN*pars.detN)),pars.detN,pars.detN)';

% add Poisson noise
if pars.noiseFlag
    
    Idet = random('poisson',Idet);
    
end

end