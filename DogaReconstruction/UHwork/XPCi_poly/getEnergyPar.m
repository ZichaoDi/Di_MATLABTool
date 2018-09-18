function energy = getEnergyPar(e)

global constant

% energy dependent functions [cgs units]
energy.e        = e;                                                    % defined energy [keV]
energy.n        = length(energy.e);                                     % number of samples
energy.k        = energy.e./(constant.hbar*constant.c);                 % wavenumber [1/cm]
energy.lambda   = 2*pi./energy.k;                                       % wavelength [cm]
energy.f        = constant.c./energy.lambda;                            % frequency [1/s]
energy.E        = constant.eV.*energy.e./(constant.me*constant.c.^2);   % reduced energy ratio of the incoming photon
energy.de       = gradient(energy.e);                                   % bandwidths of energy samples

energy.sigmaC	= 2*pi*constant.re^2* ...
    (((1+energy.E)./(energy.E.^2)).* ...
    (2*(1+energy.E)./(1+2*energy.E)-log(1+2*energy.E)./energy.E) ...
    +log(1+2*energy.E)./(2*energy.E)- ...
    (1+3*energy.E)./(1+2*energy.E).^2);                                 % Compton cross-section of the electron [cm^2]

end