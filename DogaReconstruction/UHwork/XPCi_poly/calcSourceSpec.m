function Iin = calcSourceSpec(energy,pars)

% get Tungsten spectrum
spec = spektrSpectrum(pars.tubeV)';
spec = spec(energy.e);

% filtration
comp = getMatComp(pars.tubeFilter);                    
filter = getMatPars(energy,comp);
spec = spec.*exp(-filter.mu*pars.filterThickness);

% scale according to dose accordingly
scale = scaleSpec(spec,energy,pars);

% incident intensity
Iin = scale.*spec;

end

function scale = scaleSpec(spec,energy,pars)
% handbook of med imaging

obj = importdata('/home/doga/Documents/MATLAB/data/spectrums/R050.dgn');
DgN = obj(energy.e,5)'*1e-2; % [mGy/R]

a = -5.023290717769674e-6;
b = 1.810595449064631e-7;
c = 0.008838658459816926;
xi = (a+b*sqrt(energy.e).*log(energy.e)+c./energy.e.^2)*1e-3;  % [R/photons/mm^2]

% glandular dose
GD = sum(spec.*xi.*DgN); % [mGy]

scale = (1e2*pars.pixelSize^2./pars.M^2)*pars.dose./GD;

end