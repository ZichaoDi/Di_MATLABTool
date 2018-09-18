function obj = getMatPars(energy,comp)
% returns the attenuation coefficient of the selected obj tissue model

global constant

names = fieldnames(comp.ratio); % get the element names
numberOfElements = length(names); % number of different elements in the obj

% initializations
obj.delta = zeros(numberOfElements,energy.n);               % real part of the refractive index [e/atom]
obj.beta = zeros(numberOfElements,energy.n);                % imaginary part of the refractive index [e/atom]
obj.rho = zeros(numberOfElements,energy.n);                 % effective electron density [1/cm^3]
obj.mu = zeros(numberOfElements,energy.n);                  % total attenuation [1/cm]
obj.photoelectric = zeros(numberOfElements,energy.n);       % photoelectric attenuation [1/cm]
obj.compton = zeros(numberOfElements,energy.n);             % Compton attenuation [1/cm]
obj.control = zeros(numberOfElements,energy.n);             % mu calculated from NIST data

for m = 1:numberOfElements
    
    % regular sampling of atomic parameters at defined energies
    element = importdata(['/home/doga/Documents/MATLAB/data/atomProperties/',lower(names{m}),'.mat']);
    
    % number of atoms per unit volume
    N = comp.density.*comp.ratio.(names{m}).*constant.Na/element.Ar; % [1/cm^3]
    
    % interpolated form factors and attenuation coefficient based on defined energy
    f1 = interp1(element.f1(:,1),element.f1(:,2),energy.e);
    f2 = interp1(element.f2(:,1),element.f2(:,2),energy.e);
    
    % attenuation coefficients based on interpolated attenuation dataset of elements
    obj.control(m,:) = comp.ratio.(names{m}).*interp1(element.mu(:,1),element.mu(:,2),energy.e).*comp.density./element.rho;
    
    % scaled refractive indices calculated from form factors
    obj.delta(m,:) = N.*constant.re*energy.lambda.^2./(2*pi).*f1;
    obj.beta(m,:) = N.*constant.re*energy.lambda.^2./(2*pi).*f2;
    
    % effective electron density
    obj.rho(m,:) = N.*f1;
    
    % photoelectric mass attenuation coefficient calculated from refractive indices
    sigma = 2*constant.re.*energy.lambda.*f2;           % photoelectric cross-section [cm^2]
    obj.photoelectric(m,:) = N*sigma;                   % photoabsorption coefficient [1/cm]
    
    % Compton mass attenuation coefficient [1/cm]
    sigma = element.Z*energy.sigmaC;                    % total electronic Compton cross-section for the element [cm^2]
    obj.compton(m,:) = N*sigma;                         % Compton-scattering coefficient [1/cm]
    
    % total mass attenuation [1/cm]
    obj.mu(m,:) = obj.photoelectric(m,:)+obj.compton(m,:);
    
end

if numberOfElements > 1
    
    % sum of the contribution of each element
    obj.delta = sum(obj.delta);
    obj.beta = sum(obj.beta);
    obj.rho = sum(obj.rho);
    obj.mu = sum(obj.mu);
    obj.photoelectric = sum(obj.photoelectric);
    obj.compton = sum(obj.compton);
    obj.control = sum(obj.control);
    
end

end

