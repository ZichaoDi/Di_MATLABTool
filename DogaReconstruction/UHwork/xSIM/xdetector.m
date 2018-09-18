classdef xdetector
    %XDETECTOR class for detector related methods.
    %
    %   Methods:
    %       y = getDetectorGain(x)
    %       y = getEnergyBins(x,fluence)
    %       y = calcBinMedian(x,fluence)
    %
    %   See also GETDETECTORGAIN, GETENERGYBINS, CALCBINMEDIAN, XCONSTANT,
    %   XSOURCE, XMATERIAL, XFORWARD, XINVERSE.
    
    %   written by Doga Gursoy
    %   date: April 22, 2013
    
    methods (Static)
        function y = getDetectorGain(x)
            %GETDETECTORGAIN returns the detector gain
            %
            %   Example: 
            %       x.tubePeakVoltage = 120;
            %       x.detectorMaterial = 'cdznte';
            %       x.detectorThickness = 0.03;
            %       y = xdetector.getDetectorGain(x);
            
            %   written by Doga Gursoy
            %   date: April 22, 2013
            
            % calculate the mass ratios and density of the material
            composition = xmaterial.getComposition(x.detectorMaterial);
            
            % calcualte the material absorption
            material = xmaterial.getAttributes(composition,1:x.tubePeakVoltage);
            
            % calculate xdetector gain
            y = 1-exp(-x.detectorThickness.*material.photoAbsorption);
        end
        
        function energyBins = getEnergyBins(x,fluence)
            %GETENERGYBINS calculates the energy bins so that the total
            %detected photon counts in each bin is equal.
            %
            %   Example:
            %       x.tubePeakVoltage = 120;
            %       x.filterMaterial = 'al';
            %       x.filterThickness = 1;
            %       x.sourceToObjectDistance = 100;
            %       x.objectToDetectorDistance = 100;
            %       x.appliedDose = 1;
            %       x.detectorMaterial = 'cdznte';
            %       x.detectorThickness = 0.03;
            %       x.numberOfBins = 8;
            %       x.pixelSize = 1e-2;
            %       fluence = xsource.getFluence(x);
            %       y = xdetector.getEnergyBins(x,fluence);
            %
            %   See also GETFLUENCE, CALCBINMEDIAN.
            
            %   written by Doga Gursoy
            %   date: April 22, 2013
                        
            % calculate xdetector gain
            detectorGain = xdetector.getDetectorGain(x);
            
            % detected x-ray fluence
            detectedFluence = detectorGain.*fluence;
            
            % normalized fluence
            detectedFluence = detectedFluence./sum(detectedFluence);
            
            % calculate the x-ray energy bins
            energyBins = ones(x.numberOfBins,2);
            level = cumsum(1/x.numberOfBins*ones(x.numberOfBins,1));
            for m = 1:x.numberOfBins-1
                tmp = max(find((cumsum(detectedFluence)) >= level(m),1,'first'));
                energyBins(m,2) = tmp-1;
                energyBins(m+1,1) = tmp;
                
            end
            energyBins(end,2) = x.tubePeakVoltage;
        end
        
        function binMedian = calcBinMedian(x,fluence)
            %CALCBINMEDIAN calculates the median energy of each bin.
            %
            %   Example:
            %       x.tubePeakVoltage = 120;
            %       x.filterMaterial = 'al';
            %       x.filterThickness = 1;
            %       x.sourceToObjectDistance = 100;
            %       x.objectToDetectorDistance = 100;
            %       x.appliedDose = 1;
            %       x.detectorMaterial = 'cdznte';
            %       x.detectorThickness = 0.03;
            %       x.numberOfBins = 8;
            %       x.pixelSize = 1e-2;
            %       fluence = xsource.getFluence(x);
            %       y = xdetector.calcBinMedian(x,fluence);
            %
            %   See also GETFLUENCE, GETENERGYBINS.
            
            %   written by Doga Gursoy
            %   date: April 22, 2013
            
            % calculate thresholds
            energyBins = xdetector.getEnergyBins(x,fluence);
            
            % calculate xdetector gain
            detectorGain = xdetector.getDetectorGain(x);
            
            % detected x-ray fluence
            detectedFluence = detectorGain.*fluence;
            
            % median of each bin
            binMedian = size(1,x.numberOfBins);
            for m = 1:x.numberOfBins
                % bin index
                ind = energyBins(m,1):energyBins(m,2);
                
                % normalize to have a probability function
                Ibin = detectedFluence(ind)./sum(detectedFluence(ind));
                
                % find median
                binMedian(m) = max(find((cumsum(Ibin)) > 0.5,1,'first'))+energyBins(m,1)-1;
            end
        end
    end
end

