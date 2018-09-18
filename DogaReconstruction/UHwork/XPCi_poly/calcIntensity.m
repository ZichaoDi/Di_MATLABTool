function [Idet Iff] = calcIntensity(energy,pars,obj,fluence)

% init matrices
Idet = zeros(pars.detN,pars.detN,pars.binN);
Iff = zeros(pars.detN,pars.detN,pars.binN);

for m = 1:pars.binN % for each bin
    
    % define bin energy
    e = pars.threshold(m,1):pars.threshold(m,2);
    
    % define energy bin
    bin = getEnergyPar(e);
    
    % calculate image-plane intensity
    [Idet(:,:,m) Iff(:,:,m)] = getBinIntensity(fluence,obj,pars,energy,bin);
end

end

function [Idet,Iff] = getBinIntensity(fluence,obj,pars,energy,bin)

% sub-sample detector grid
subSampled = pars;
subSampled.pixelSize = pars.pixelSize/pars.sampleN;
subSampled.detN = pars.detN*pars.sampleN;
subSampled.detLen = subSampled.pixelSize*(subSampled.detN-1);

% calculate projections
proj = calcProj(energy,subSampled,obj);

% calculate pre-sample mask
firstMask = circshift(repmat([zeros(pars.sampleN/2,pars.detN*pars.sampleN);ones(pars.sampleN/2,pars.detN*pars.sampleN)],pars.detN,1),-pars.sampleN/4);

% post-sample mask
secondMask = circshift(firstMask,pars.state*pars.sampleN/4);

% get detected intensity
comp = getMatComp(pars.detMat);
obj = getMatPars(energy,comp);
gainDetector = 1-exp(-pars.detThick.*obj.photoelectric);

% inits
Idet = zeros(pars.detN,pars.detN);
Iff = zeros(pars.detN,pars.detN);

for m = bin.e
    m
    % calculate post-sample projections
    Iobj = (fluence(m)./pars.sampleN^2).*(exp(-proj.mu(:,:,m)).*firstMask);
    prj.delta = proj.delta(:,:,m).*firstMask;
    
    % TIE propagation after sample
    [dX dY] = gradient(prj.delta,subSampled.pixelSize);
    [d2X,~] = gradient(Iobj.*dX,subSampled.pixelSize);
    [~,d2Y] = gradient(Iobj.*dY,subSampled.pixelSize);
    Iwave = Iobj+pars.R2/pars.M.*(d2X+d2Y);
    
    % calculate intensity after post-sample mask
    IdetSub = Iwave.*secondMask;
    
    % sum over pixels
    tmp = reshape(sum(reshape(IdetSub,pars.sampleN,subSampled.detN*pars.detN)),pars.detN,subSampled.detN);
    Idet = gainDetector(m).*(reshape(sum(reshape(tmp',pars.sampleN,pars.detN*pars.detN)),pars.detN,pars.detN)')+Idet;
    
    % flat-field intensity at detector plane
    Iff = gainDetector(m).*fluence(m).*0.25+Iff;
end

% add Poisson noise
if pars.noiseFlag
    Idet = random('poisson',Idet);
end

end
