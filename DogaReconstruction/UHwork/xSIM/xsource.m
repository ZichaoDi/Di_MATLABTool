classdef xsource
    %XSOURCE class for x-ray source and generation
    %
    %   Methods:
    %       fluence = getFluence(x)
    %       scale = scaleFluence(fluence,x)
    %       showIncidentFluence(fluence)
    %
    %   See also GETFLUENCE, SCALEFLUENCE, SHOWFLUENCE, XCONSTANT,
    %   XMATERIAL, XDETECTOR, XFORWARD, XINVERSE.
    
    %   written by Doga Gursoy
    %   date: May 13, 2013
    
    methods (Static)
        function fluence = getFluence(x)
            %GETFLUENCE returns Tungsten spectrum based on TASMIP.
            %
            %   Example:
            %       x.tubePeakVoltage = 120;
            %       x.filterMaterial = 'al';
            %       x.filterThickness = 1;
            %       x.sourceToObjectDistance = 100;
            %       x.objectToDetectorDistance = 100;
            %       x.appliedDose = 1;
            %       x.pixelSize = 1e-2;
            %       y = xsource.getFluence(x);
            %
            %   Units: tubePeakVoltage [kvP], filterMaterial (cell),
            %   filterThickness [cm], sourceToObjectDistance [cm],
            %   objectToDetectorDistance [cm], appliedDose [mGy], pixelSize
            %   [cm]
            %
            %   Note that filter material and the spectrum for dose
            %   scaling should be located in the atomProperties and
            %   spectrums folders respectively.
            %
            %   References:
            %       [1] Med. Phys. 24, 1661 (1997).
            %
            %   See also XSOURCE, SCALEFLUENCE, SHOWFLUENCE, GETENERGYBINS.
            
            %   written by Doga Gursoy
            %   date: May 13, 2013
            
            % import the energy
            energy = 1:x.tubePeakVoltage;
            fluence = spektrSpectrum(x.tubePeakVoltage)';
            fluence = fluence(energy);
            
            % add x-ray filtration
            composition = xmaterial.getComposition(x.filterMaterial);
            material = xmaterial.getAttributes(composition,energy);
            fluence = fluence.*exp(-material.attenuation*x.filterThickness);
            
            % scale incident intensity according to dose
            scale = xsource.scaleFluence(fluence,x);
            fluence = scale.*fluence;
        end
        
        function scale = scaleFluence(fluence,x)
            %SCALEFLUENCE returns the scaling factor to adjust fluence
            %based on the defined applied dose level.
            %
            %   References:
            %       [1] Handbook of Medical Imaging Vol. 1 Physics and
            %       Psychophysics, SPIE
            %
            %   See also XSOURCE, GETFLUENCE, SHOWFLUENCE, GETENERGYBINS.
            
            %   written by Doga Gursoy
            %   date: May 13, 2013
            
            % import the required scaling spectrum from file
            energy = 1:x.tubePeakVoltage;
            obj = importdata('spectrums/R050.dgn');
            DgN = obj(energy,5)'*1e-2; % [mGy/R]
            
            % defined constants
            a = -5.023290717769674e-6;
            b = 1.810595449064631e-7;
            c = 0.008838658459816926;
            xi = (a+b*sqrt(energy).*log(energy)+c./energy.^2)*1e-3;  % [R/photons/mm^2]
            
            % glandular dose
            glandularDose = sum(fluence.*xi.*DgN); % [mGy]
            
            % magnification factor
            magnificationFactor = xforward.getMagnificationFactor(x);
            
            % scale for normalized fluence spectrum
            scale = (1e2*x.pixelSize^2./magnificationFactor^2)*x.appliedDose./glandularDose;
        end
        
        function showFluence(fluence)
            %SHOWFLUENCE plots the given fluence spectrum.
            %
            %   Example:
            %       x.tubePeakVoltage = 120;
            %       x.filterMaterial = 'al';
            %       x.filterThickness = 1;
            %       x.sourceToObjectDistance = 100;
            %       x.objectToDetectorDistance = 100;
            %       x.appliedDose = 1;
            %       x.pixelSize = 1e-2;
            %       y = xsource.getFluence(x);
            %       xsource.showFluence(y);
            %
            %   See also XSOURCE, GETFLUENCE, SCALEFLUENCE.
            
            %   written by Doga Gursoy
            %   date: May 13, 2013
            
            figure
            plot(fluence)
            grid on
            title('X-ray xsource spectrum','fontsize',14)
            xlabel('Energy [keV]','fontsize',12);
            ylabel('X-ray quanta','fontsize',12);
            set(gca,'fontsize',12);
        end
    end
end

