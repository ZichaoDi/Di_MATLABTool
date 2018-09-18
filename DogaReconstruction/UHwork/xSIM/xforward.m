classdef xforward
    %XFORWARD class for the forward simulation
    %
    %   Methods:
    %       y = getDetectorCoordinates(x)
    %       y = getSourceCoordinates(x)
    %       y = getProjection(x)
    %       y = getDetectedIntensity(x)
    %       y = getOpticalTransferFunction(x)
    %       img = addFocalSpotBlur(x,img)
    %       y = addNoise(x)
    %       showImage(img,index)
    %   
    %   See also GETDETECTORCOORDINATES, GETSOURCECOORDINATES,
    %   GETPROJECTION, GETDETECTEDINTENSITY, GETOPTICALTRANSFERFUNCTION,
    %   ADDPOISSONNOISE, SHOWIMAGE, XCONSTANT, XSOURCE, XMATERIAL,
    %   XDETECTOR, XINVERSE.
    
    %   written by Doga Gursoy
    %   date: April 22, 2013
    
    methods (Static)
        function  y = getDetectorCoordinates(x)
            %GETDETECTORCOORDINATES returns the xdetector coordinates of the
            %pixel centers as a struct array Y. X is the struct having
            %NUMBEROFPIXELS, PIXELSIZE and OBJECTTODETECTORDISTANCE fields.
            % 
            %   Example:
            %       x.numberOfPixels = 100;
            %       x.pixelSize = 1e-2;
            %       x.objectToDetectorDistance = 100;
            %       y = xforward.getDetectorCoordinates(x);
            %       
            %   See also XFORWARD, GETSOURCECOORDINATES.
            
            %   written by Doga Gursoy
            %   date: April 22, 2013
            
            % length of the xdetector
            detectorLength = x.numberOfPixels*x.pixelSize;
            
            % xdetector plane is located on negative x-axis in parallel to yz-plane
            px = -x.objectToDetectorDistance*ones(x.numberOfPixels,x.numberOfPixels);
            
            % origin of the xdetector is on x-axis
            [py pz] = meshgrid(-detectorLength/2+x.pixelSize/2:x.pixelSize:detectorLength/2-x.pixelSize/2,...
                -detectorLength/2+x.pixelSize/2:x.pixelSize:detectorLength/2-x.pixelSize/2);
            
            % set output structure
            y = struct('px',px,'py',py,'pz',pz);
        end
        
        function y = getSourceCoordinates(x)
            %GETSOURCECOORDINATES returns the source coordinates as a
            %struct array Y. X is the struct having SOURCETOOBJECTDISTANCE
            %field.
            %
            %   Example:
            %       x.sourceToObjectDistance = 100;
            %       y = xforward.getSourceCoordinates(x);
            %
            %   See also XFORWARD, GETDETECTORCOORDINATES.
            
            %   written by Doga Gursoy
            %   date: April 22, 2013
            
            % x-ray xsource is located on positive x-axis
            y = struct('px',x.sourceToObjectDistance,'py',0,'pz',0);
        end
        
        function y = getProjection(x)
            %GETPROJECTION returns the projected BETA, DELTA and
            %ATTENUATION fields in Y structure. BETA and DELTA are
            %respectively the projected imaginary and real part (minus 1)
            %of the refractive index. ATTENUATION is the total projected
            %x-ray attenuation.
            %
            %   Example:
            %       x.tubePeakVoltage = 120;
            %       x.sourceToObjectDistance = 100;
            %       x.objectToDetectorDistance = 100;
            %       x.numberOfPixels = 100;
            %       x.pixelSize = 1e-2;
            %       x.ellipseMaterial = {'pmma'};
            %       x.ellipseCenter = [0 0 0];       
            %       x.ellipseAxes = [0.1 0.1 0.1];
            %       y = xforward.getProjection(x);
            %
            %   Reference:
            %   [1] Siddon Med Phys 12 2, 1985
            %
            %   See also XFORWARD, GETDETECTEDINTENSITY.
            
            %   written by Doga Gursoy
            %   date: April 22, 2013
                        
            % number of ellipses in the object
            numberOfEllipses = length(x.ellipseMaterial);
            
            % define number of energy samples
            numberOfEnergySamples = x.tubePeakVoltage;
            
            % define projections
            y.beta = zeros(x.numberOfPixels,x.numberOfPixels,numberOfEnergySamples);
            y.delta = zeros(x.numberOfPixels,x.numberOfPixels,numberOfEnergySamples);
            y.attenuation = zeros(x.numberOfPixels,x.numberOfPixels,numberOfEnergySamples);
            
            % get x-ray xsource and xdetector coordinates
            src = xforward.getSourceCoordinates(x);
            det = xforward.getDetectorCoordinates(x);
            
            for n = 1:numberOfEllipses
                % get object attributes
                composition = xmaterial.getComposition(x.ellipseMaterial{n});
                material = xmaterial.getAttributes(composition,1:x.tubePeakVoltage);
                
                % intersection points of the line with the ellipse
                xDiff = det.px-src.px;
                yDiff = det.py-src.py;
                zDiff = det.pz-src.pz;
                
                xDiff0 = src.px-x.ellipseCenter(n,1);
                yDiff0 = src.py-x.ellipseCenter(n,2);
                zDiff0 = src.pz-x.ellipseCenter(n,3);
                
                A2 = x.ellipseAxes(n,1)^2;
                B2 = x.ellipseAxes(n,2)^2;
                C2 = x.ellipseAxes(n,3)^2;
                
                A2B2 = A2*B2;
                B2C2 = B2*C2;
                A2C2 = A2*C2;
                
                a = B2C2*xDiff.^2+A2C2*yDiff.^2+A2B2*zDiff.^2;
                b = 2*(B2C2*xDiff0.*xDiff+A2C2*yDiff0.*yDiff+A2B2*zDiff0.*zDiff);
                c = B2C2*xDiff0.^2+A2C2*yDiff0.^2+A2B2*zDiff0.^2-A2*B2*C2;
                
                alpha1 = (-b+sqrt(b.^2-4*a.*c))./(2*a);
                alpha2 = (-b-sqrt(b.^2-4*a.*c))./(2*a);
                
                len = sqrt((alpha2-alpha1).^2.*(xDiff.^2+yDiff.^2+zDiff.^2));
                len = reshape(real(len),x.numberOfPixels*x.numberOfPixels,1);
                
                % note: bsxfun is used because it is faster
                y.beta = reshape(bsxfun(@times,len,material.beta),x.numberOfPixels,x.numberOfPixels,numberOfEnergySamples)+y.beta;
                y.delta = reshape(bsxfun(@times,len,material.delta),x.numberOfPixels,x.numberOfPixels,numberOfEnergySamples)+y.delta;
                y.attenuation = reshape(bsxfun(@times,len,material.attenuation),x.numberOfPixels,x.numberOfPixels,numberOfEnergySamples)+y.attenuation;
            end
        end
        
        function y = getDetectedIntensity(x)
            %GETDETECTEDINTENSITY returns the number of detected photons
            %based on the Transport-of-Intensity Equation (TIE) and the xdetector
            %parameters. Y.DETECTEDINTENSITY and Y.FLATFIELDINTENSITY are
            %the 2-D matrices representing measured and flat-field
            %intensity respectively. 
            %
            %   Note that Poisson noise is not added on flat-field
            %   intensity.
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
            %       y = xforward.getDetectedIntensity(x);
            %       
            %   References:
            %   [1] Wilkins, Nature 373 595, 1995
            %   [2] Paganin, Coherent X-Ray Optics (Oxford, 2009)
            %   [3] Teague, JOSA-A 73 1434, 1983
            %   [4] Sordo et al. Sensors 9 3491, 2009
            %
            %   See also XFORWARD, GETPROJECTION.
            
            %   written by Doga Gursoy
            %   date: April 22, 2013
                        
            % obtain spectrum
            fluence = xsource.getFluence(x);
            
            % calculate thresholds
            x.energyBins = xdetector.getEnergyBins(x,fluence);
            
            % magnification factor
            magnificationFactor = xforward.getMagnificationFactor(x);
            
            % get projections
            proj = xforward.getProjection(x);
            
            % number of bins
            numberOfBins = size(x.energyBins,1);
            
            % initialize matrices
            detectedIntensity = zeros(x.numberOfPixels,x.numberOfPixels,numberOfBins);
            flatFieldIntensity = zeros(x.numberOfPixels,x.numberOfPixels,numberOfBins);
            
            % calculate xdetector gain
            detectorGain = xdetector.getDetectorGain(x);
            
            for m = 1:numberOfBins % for each bin
                % define bin energy
                currentEnergyBin = x.energyBins(m,1):x.energyBins(m,2);
                
                for n = currentEnergyBin
                    % intensity at object plane
                    objectPlaneIntensity = fluence(n).*exp(-proj.attenuation(:,:,n));
                    
                    % propagation operator based on TIE
                    [dX dY] = gradient(proj.delta(:,:,n),x.pixelSize);
                    [d2X,~] = gradient(objectPlaneIntensity.*dX,x.pixelSize);
                    [~,d2Y] = gradient(objectPlaneIntensity.*dY,x.pixelSize);
                    
                    % intensity at xdetector plane
                    detectedIntensity(:,:,m) = detectorGain(n).*(objectPlaneIntensity+x.objectToDetectorDistance/magnificationFactor.*(d2X+d2Y))+detectedIntensity(:,:,m);
                    
                    % flat-field intensity at xdetector plane
                    flatFieldIntensity(:,:,m) = detectorGain(n).*fluence(n)+flatFieldIntensity(:,:,m);
                end
                
                % add focal-spot blur
                detectedIntensity(:,:,m) = xforward.addFocalSpotBlur(x,detectedIntensity(:,:,m));
                
                % adds Poisson noise to data
                detectedIntensity(:,:,m) = xforward.addPoissonNoise(detectedIntensity(:,:,m));
                
                % set output structure
                y = struct('detected',detectedIntensity,'flatField',flatFieldIntensity);
            end
        end
        
        function y = addFocalSpotBlur(x,img)
            %ADDFOCALSPOTBLUR returns blurred image Y. The blurring is
            %calculated according to the optical transfer function of the
            %imaging setup.
            %
            %   Example:
            %       x.numberOfPixels = 100;
            %       x.pixelSize = 1e-2;
            %       x.objectToDetectorDistance = 100;
            %       x.sourceToObjectDistance = 100;
            %       x.focalSpotSize = 1e-2;
            %       img = phantom(x.numberOfPixels);
            %       y = xforward.addFocalSpotBlur(x,img);
            %
            %   See also XFORWARD, GETOPTICALTRANSFERFUNCTION.
            
            %   written by Doga Gursoy
            %   date: April 22, 2013
            
            % calculate optical transfer function
            opticalTransferFunction = xforward.getOpticalTransferFunction(x);
            
            % apply focal spot blur
            y = abs(ifft2(fftshift(fft2(img)).*opticalTransferFunction));
            
        end
        
        function y = getOpticalTransferFunction(x)
            %GETOPTICALTRANSFERFUNCTION returns the optical transfer
            %function (OTF) given the input X as a struct array. 
            %
            %   Example:
            %       x.numberOfPixels = 100;
            %       x.pixelSize = 1e-2;
            %       x.objectToDetectorDistance = 100;
            %       x.sourceToObjectDistance = 100;
            %       x.focalSpotSize = 1e-2;
            %       y = xforward.getOpticalTransferFunction(x);
            %
            %   See also XFORWARD.
            
            %   written by Doga Gursoy
            %   date: April 22, 2013
            
            % length of the xdetector
            totalLength = (x.numberOfPixels-1)*x.pixelSize;
            
            % frequency sampling
            [du dv] = meshgrid(2*pi./totalLength.*((-x.numberOfPixels+1)/2:(x.numberOfPixels-1)/2), ...
                2*pi./totalLength.*((-x.numberOfPixels+1)/2:(x.numberOfPixels-1)/2));
            u = sqrt(du.^2+dv.^2);
            
            % magnification factor
            magnificationFactor = xforward.getMagnificationFactor(x);
            
            % calculate optical transfer function
            y = sinc((magnificationFactor-1)./magnificationFactor*x.focalSpotSize*u);
        end
        
        function y = addPoissonNoise(x)
            %ADDPOISSONNOISE adds Poisson noise to a given X matrix.
            %
            %   Example:
            %       img = 1e2*phantom(1e2);
            %       y = xforward.addPoissonNoise(img);
            %
            %   See also XFORWARD.
            
            %   written by Doga Gursoy
            %   date: April 22, 2013
            
            % adds Poisson noise to data
            y = random('poisson',x);
        end
        
        function y = getMagnificationFactor(x)
            %GETMAGNIFICATIONFACTOR returns the magnification factor. X is
            %a struct with fields SOURCETOOBJECTDISTANCE and
            %OBJECTTODETECTORDISTANCE.
            %
            %   Example:
            %       x.sourceToObjectDistance = 100;
            %       x.objectToDetectorDistance = 100;
            %       y = xforward.getMagnificationFactor(x);
            
            %   written by Doga Gursoy
            %   date: May 14, 2013
            
            y = (x.sourceToObjectDistance+x.objectToDetectorDistance)./x.sourceToObjectDistance;
        end
        
        function showImage(x,index)
            %SHOWIMAGE shows the image given by X. INDEX determines the
            %dimension of the image to be shown.
            %
            %   Example:
            %       img = phantom(1e2);
            %       xforward.showImage(img,1);
            %
            %   See also XFORWARD.
            
            %   written by Doga Gursoy
            %   date: April 22, 2013
            
            figure
            imagesc(squeeze(x(:,:,index)))
            axis equal image
            colormap gray
            colorbar
        end
    end
    
end

