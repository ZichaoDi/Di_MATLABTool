classdef xinverse
    %XINVERSE class for image reconstruction
    %
    %   Methods:
    %       y = retrieval(x,intensity)
    %       y = getAbsorption(x,energy)
    %       y = getPhase(x,energy)
    %       y = getAttenuation(x,energy)
    %
    %   See also RETRIEVAL, GETABSORPTION, GETPHASE, GETATTENUATION,
    %   XCONSTANT, XSOURCE, XMATERIAL, XDETECTOR, XFORWARD.
    
    %   written by Doga Gursoy
    %   date: April 22, 2013
    
    methods (Static)
        function y = retrieval(x,intensity)
            %RETRIEVAL returns the projected quantities a1 and a2 as
            %defined in equation 7 in [1]. a1 and a2 are then used to
            %obtain absorption and phase images. The formulation is based
            %on Transport-of-Intensity equation and the solution is
            %obtained by weighted least-square method.
            %
            %   Example:
            %       x.tubePeakVoltage = 120;
            %       x.sourceToObjectDistance = 100;
            %       x.objectToDetectorDistance = 100;
            %       x.filterMaterial = 'al';
            %       x.filterThickness = 0;
            %       x.appliedDose = 10;
            %       x.pixelSize = 1e-2;
            %       x.numberOfPixels = 100;
            %       x.focalSpotSize = 0;
            %       x.detectorMaterial = 'cdznte';
            %       x.detectorThickness = 0.03;
            %       x.numberOfBins = 8;
            %       x.ellipseMaterial = {'pmma'};
            %       x.ellipseCenter = [0 0 0];
            %       x.ellipseAxes = [0.1 0.1 0.1];
            %       I = xforward.getDetectedIntensity(x);
            %
            %       y = xinverse.retrieval(x,I);
            %
            %   References:
            %       [1] Alvarez and Macovsky, Phys Med Biol 21 733, 1976. 
            %       [2] Gursoy and Das, Opt Lett 38 9, 2013
            %
            %   See also GETABSORPTION, GETPHASE, GETATTENUATION, XINVERSE.
            
            %   written by Doga Gursoy
            %   date: Apr 22, 2013
    
            % obtain spectrum
            fluence = xsource.getFluence(x);
            
            % define energy bin
            binMedianEnergy = xdetector.calcBinMedian(x,fluence);
            
            % get flat-field corrected data
            intensity = -log(intensity.detected./intensity.flatField);
            
            % Fourier transform of data
            ffti = xinverse.fftShift(fft2(intensity));
            
            % calculate the bin weighting based on SNR of each bin
            W = diag(ones(x.numberOfBins,1));
            
            % magnification factor
            magnificationFactor = xforward.getMagnificationFactor(x);
            
            % length of the detector
            totalLength = (x.numberOfPixels-1)*x.pixelSize;
            
            % frequency sampling
            du = 2*pi./totalLength.*((-x.numberOfPixels+1)/2:(x.numberOfPixels-1)/2);
            dv = 2*pi./totalLength.*((-x.numberOfPixels+1)/2:(x.numberOfPixels-1)/2);
            
            % reduced energy massRatio of the incoming photon
            E = xconstant.ELECTRON_VOLT.*binMedianEnergy./(xconstant.ELECTRON_MASS*xconstant.SPEED_OF_LIGHT.^2);
            
            % Compton cross-section of the electron [cm^2]
            comptonCrossSection = 2*pi*xconstant.CLASSICAL_ELECTRON_RADIUS^2* ...
                (((1+E)./(E.^2)).*(2*(1+E)./(1+2*E)-log(1+2*E)./E)+log(1+2*E)./(2*E)-(1+3*E)./(1+2*E).^2);
            
            % wavelength of x-rays
            wavelength = 2*pi*xconstant.PLANCK_CONSTANT*xconstant.SPEED_OF_LIGHT./binMedianEnergy;
            
            % initialize solution matrix
            A = zeros(x.numberOfPixels,x.numberOfPixels,2);
            
            % constant in equation 4 [1]
            K = 4*sqrt(2)*xconstant.FINE_STRUCTURE_CONSTANT^4*xconstant.THOMPSON_CROSS_SECTION;
            
            % retrieve values independently for each pixel
            for m = 1:x.numberOfPixels
                for n = 1:x.numberOfPixels
                    % first term on the right hand side of equation 8 [1]
                    c1 = K.*E.^(-3.4);
                    
                    % second term on the right hand side of equation 8 [1]
                    c2 = comptonCrossSection+(x.objectToDetectorDistance/magnificationFactor.*wavelength.^2.*xconstant.CLASSICAL_ELECTRON_RADIUS./(2*pi)).*(du(m).^2+dv(n).^2);
                    
                    % combine c1 and c2 in a vector
                    C = [c1' c2'];
                    
                    % solve for a1 and a2
                    A(m,n,:) = pinv(C'*W*C)*C'*W*squeeze(ffti(m,n,:));
                end
            end
            
            % estimated projections
            y.intRhoZ = real(ifft2(xinverse.fftShift(A(:,:,1)))); % a1 in eqn 7 in [1]
            y.intRho = real(ifft2(xinverse.fftShift(A(:,:,2)))); % a2 in eqn 7 in [1]
        end
        
        function y = getAbsorption(x,energy)
            %GETABSORPTION returns the absorption projection [1/cm] using
            %projection of Z^4 times electron density (INTRHOZ). X is a
            %struct containing the INTRHOZ field. The absorption is
            %calculated for the given ENERGY.
            %
            %   Example:
            %       x.tubePeakVoltage = 120;
            %       x.sourceToObjectDistance = 100;
            %       x.objectToDetectorDistance = 100;
            %       x.filterMaterial = 'al';
            %       x.filterThickness = 0;
            %       x.appliedDose = 10;
            %       x.pixelSize = 1e-2;
            %       x.numberOfPixels = 100;
            %       x.focalSpotSize = 0;
            %       x.detectorMaterial = 'cdznte';
            %       x.detectorThickness = 0.03;
            %       x.numberOfBins = 8;
            %       x.ellipseMaterial = {'pmma'};
            %       x.ellipseCenter = [0 0 0];
            %       x.ellipseAxes = [0.1 0.1 0.1];
            %       I = xforward.getDetectedIntensity(x);
            %       a = xinverse.retrieval(x,I);
            %
            %       energy = 40;
            %       y = getAbsorption(a,energy)
            %
            %   See also GETPHASE, GETATTENUATION, RETRIEVAL, XINVERSE.
            
            %   written by Doga Gursoy
            %   date: Apr 22, 2013
            
            % reduced energy massRatio of the incoming photon
            E = xconstant.ELECTRON_VOLT.*energy./(xconstant.ELECTRON_MASS*xconstant.SPEED_OF_LIGHT.^2);
            
            % attenuation from photoelectric effect [1/cm]
            y = 4*sqrt(2)*xconstant.FINE_STRUCTURE_CONSTANT^4*xconstant.THOMPSON_CROSS_SECTION/E^3.4*x.intRhoZ;            
        end
        
        function y = getPhase(x,energy)
            %GETPHASE returns the phase image using projected electron
            %density (INTRHO). X is a struct containing the INTRHO field.
            %The phase is calculated for the given ENERGY.
            %
            %   Example:
            %       x.tubePeakVoltage = 120;
            %       x.sourceToObjectDistance = 100;
            %       x.objectToDetectorDistance = 100;
            %       x.filterMaterial = 'al';
            %       x.filterThickness = 0;
            %       x.appliedDose = 10;
            %       x.pixelSize = 1e-2;
            %       x.numberOfPixels = 100;
            %       x.focalSpotSize = 0;
            %       x.detectorMaterial = 'cdznte';
            %       x.detectorThickness = 0.03;
            %       x.numberOfBins = 8;
            %       x.ellipseMaterial = {'pmma'};
            %       x.ellipseCenter = [0 0 0];
            %       x.ellipseAxes = [0.1 0.1 0.1];
            %       I = xforward.getDetectedIntensity(x);
            %       a = xinverse.retrieval(x,I);
            %
            %       energy = 40;
            %       y = getPhase(a,energy)
            %
            %   See also GETABSORPTION, GETATTENUATION, RETRIEVAL, XINVERSE.
            
            %   written by Doga Gursoy
            %   date: Apr 22, 2013
            
            % wavenumber
            wavenumber = energy./(xconstant.PLANCK_CONSTANT*xconstant.SPEED_OF_LIGHT);
            
            % phase 
            y = 2*pi*xconstant.CLASSICAL_ELECTRON_RADIUS/wavenumber*x.intRho;
        end
        
        function y = getAttenuation(x,energy)
            %GETATTENUATION returns the total attenuation projection [1/cm]
            %using projection of Z^4 times electron density (INTRHOZ) and
            %projection of electron density (INTRHO). X is a struct
            %containing the INTRHOZ and INTRHO fields. The attenuation is
            %calculated for the given ENERGY.
            %
            %   Example:
            %       x.tubePeakVoltage = 120;
            %       x.sourceToObjectDistance = 100;
            %       x.objectToDetectorDistance = 100;
            %       x.filterMaterial = 'al';
            %       x.filterThickness = 0;
            %       x.appliedDose = 10;
            %       x.pixelSize = 1e-2;
            %       x.numberOfPixels = 100;
            %       x.focalSpotSize = 0;
            %       x.detectorMaterial = 'cdznte';
            %       x.detectorThickness = 0.03;
            %       x.numberOfBins = 8;
            %       x.ellipseMaterial = {'pmma'};
            %       x.ellipseCenter = [0 0 0];
            %       x.ellipseAxes = [0.1 0.1 0.1];
            %       I = xforward.getDetectedIntensity(x);
            %       a = xinverse.retrieval(x,I);
            %
            %       energy = 40;
            %       y = getAttenuation(a,energy)
            %
            %   See also GETABSORPTION, GETPHASE, RETRIEVAL, XINVERSE.
            
            %   written by Doga Gursoy
            %   date: Apr 22, 2013
            
            % reduced energy massRatio of the incoming photon
            E = xconstant.ELECTRON_VOLT.*energy./(xconstant.ELECTRON_MASS*xconstant.SPEED_OF_LIGHT.^2);
            
            % Compton cross-section of the electron [cm^2]
            comptonCrossSection = 2*pi*xconstant.CLASSICAL_ELECTRON_RADIUS^2* ...
                (((1+E)./(E.^2)).*(2*(1+E)./(1+2*E)-log(1+2*E)./E)+log(1+2*E)./(2*E)-(1+3*E)./(1+2*E).^2);
            
            % total attenuation [1/cm]
            y = 4*sqrt(2)*xconstant.FINE_STRUCTURE_CONSTANT^4*xconstant.THOMPSON_CROSS_SECTION/E^3.4*x.intRhoZ+comptonCrossSection.*x.intRho;
        end
        
        function y = fftShift(x)
            %FFTSHIFT shifts zero-frequency component to center of the
            %spectrum image.
            
            %   written by Doga Gursoy
            %   date: Apr 22, 2013
            
            y = x([ceil(end/2)+1:end 1:ceil(end/2)],[ceil(end/2)+1:end 1:ceil(end/2)],:);
            
        end
    end
end

