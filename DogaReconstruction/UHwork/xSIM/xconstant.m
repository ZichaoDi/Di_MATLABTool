classdef xconstant
    %XCONSTANT Relevant constants in cgs units compiled from different
    %sources.
    %
    %   AVOGADRO_NUMBER             : Avagadro constant [1/mol]
    %  	BOLTZMANN_CONSTANT          : Boltzmann constant [erg/k]
    %  	CLASSICAL_ELECTRON_RADIUS   : Classical electron radius [cm]
    %  	ELECTRONIC_CHARGE           : Electronic charge [esu]
    %  	ELECTRON_VOLT               : Electron volt (keV) [erg]
    %  	ELECTRON_MASS               : Electron mass [g]
    %  	FINE_STRUCTURE_CONSTANT     : Fine structure constant
    %  	PLANCK_CONSTANT             : Reduced planck's constant [keV*s]
    %  	PROTON_MASS                 : Proton mass [g]
    %  	SPEED_OF_LIGHT              : Speed of light in vacuum [cm/s]
    %  	THOMPSON_CROSS_SECTION      : Thomson cross section [cm^2]
    %
    %   See also XSOURCE, XMATERIAL, XDETECTOR, XFORWARD, XINVERSE.
    
    %   written by Doga Gursoy
    %   date: April 22, 2013
    
    properties (Constant)
        AVOGADRO_NUMBER             = 6.02214129e+23;       % Avagadro constant [1/mol]
        BOLTZMANN_CONSTANT          = 1.3806488e-16;        % Boltzmann constant [erg/k]
        CLASSICAL_ELECTRON_RADIUS   = 2.8179402894e-13;     % Classical electron radius [cm]
        ELECTRONIC_CHARGE           = 4.80320425e-10;       % Electronic charge [esu]
        ELECTRON_VOLT               = 1.602176565e-9;       % Electron volt (keV) [erg]
        ELECTRON_MASS               = 9.10938188e-28;       % Electron mass [g]
        FINE_STRUCTURE_CONSTANT     = 7.2973525698e-3;      % Fine structure constant
        PLANCK_CONSTANT             = 6.58211928e-19;       % Reduced planck's constant [keV*s]
        PROTON_MASS                 = 1.67261777e-24;       % Proton mass [g]
        SPEED_OF_LIGHT              = 299792458e+2;         % Speed of light in vacuum [cm/s]
        THOMPSON_CROSS_SECTION      = 6.652458734e-25;      % Thomson cross section [cm^2]
    end
    
end

