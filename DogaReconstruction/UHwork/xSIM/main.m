% Tutorial code for xSIM

% written by Doga Gursoy
% date: May 15, 2013

clear
close all
clc

% all required parameters as a struct array is first defined
x.tubePeakVoltage = 120;             % tube peak voltage [kVp]
x.sourceToObjectDistance = 100;      % source-to-object distance [cm]
x.objectToDetectorDistance = 100;    % object-to-detector distance [cm]
x.filterMaterial = 'al';             % tube filtration material
x.filterThickness = 0;               % filter thickness [cm]
x.appliedDose = 10;                  % applied dose [mGy]
x.pixelSize = 1e-2;                  % detector pixel size [cm]
x.numberOfPixels = 100;              % number of pixels 
x.focalSpotSize = 0;                 % focal spot size of the source [cm]
x.detectorMaterial = 'cdznte';       % detector material
x.detectorThickness = 0.03;          % detector thickness [cm]
x.numberOfBins = 8;                  % number of bins 
x.ellipseMaterial = {'pmma'};        % ellipse material
x.ellipseCenter = [0 0 0];           % center coordinates of the ellipse
x.ellipseAxes = [0.1 0.1 0.1];       % axes length of the ellipse

% calculate intensity
I = xforward.getDetectedIntensity(x);

% absorption and phase retrieval
y = xinverse.retrieval(x,I);

% retrieved values at 50keV
energy = 50;
absorption = xinverse.getAbsorption(y,energy);
phase = xinverse.getPhase(y,energy);

% show images
xforward.showImage(absorption,1);
xforward.showImage(phase,1);