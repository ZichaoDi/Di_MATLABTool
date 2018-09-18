function threshold = calcEqualBins(energy,pars,fluence)

% get detected intensity
comp = getMatComp(pars.detMat);
obj = getMatPars(energy,comp);
gainDetector = 1-exp(-pars.detThick.*obj.photoelectric);

I = gainDetector.*fluence;

% normalize I
I = I./sum(I);

% calc median of each bin
threshold = min(energy.e)*ones(pars.binN,2);
level = cumsum(1/pars.binN*ones(pars.binN,1));
for m = 1:pars.binN-1
    tmp = max(find((cumsum(I)) >= level(m),1,'first'));
    threshold(m,2) = tmp-1;
    threshold(m+1,1) = tmp;
    
end
threshold(end,2) = pars.tubeV;


end
