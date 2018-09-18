function binMedian = calcBinMedian(pars,energy,fluence)

% get detected intensity
comp = getMatComp(pars.detMat);
obj = getMatPars(energy,comp);
gainDetector = 1-exp(-pars.detThick.*obj.photoelectric);

I = gainDetector.*fluence;

% median of each bin
binMedian = size(1,pars.binN);
for m = 1:pars.binN
    
    % bin index
    ind = pars.threshold(m,1):pars.threshold(m,2);
    
    % normalize to have a probability function
    Ibin = I(ind)./sum(I(ind));
    
    % find median
    binMedian(m) = max(find((cumsum(Ibin)) > 0.5,1,'first'))+pars.threshold(m,1)-1;
    
end

end
