classdef xmaterial
    %XMATERIAL class for calculating material properties
    %
    %   Methods:
    %       attributes = getAttributes(composition,energy)
    %       composition = getComposition(material)
    %
    %   See also GETATTRIBUTES, GETCOMPOUNDMASSRATIO, XCONSTANT, XSOURCE,
    %   XDETECTOR, XFORWARD, XINVERSE.
    
    %   written by Doga Gursoy
    %   date: Apr 22, 2013
    
    methods (Static)
        function attributes = getAttributes(composition,energy)
            %GETATTRIBUTES returns the ATTRIBUTES of a material or
            %compound defined by the COMPOSITION vector for a given ENERGY
            %vector.
            %
            %   Returned ATTRIBUTES is a struct with following fields:
            %   - beta: imaginary part of the refractive index
            %   - delta: real part of the refractive index
            %   - photoAbsorption: photoelectric absorption [1/cm]
            %   - comptonScattering: compton scattering [1/cm]
            %   - atteunation: total attenuation [1/cm]
            %   - electronDensity: electron density [e/cm^3]
            %
            %   Other attenuation mechanisms other than incoherent
            %   scattering and photoabsorption are not assumed in the
            %   calculation of attenuation. 
            %
            %   Energy range is 0-400 keV.
            %
            %   Input COMPOSITION struct can be obtained from
            %   GETCOMPOSITION function. It should have the following
            %   fields:
            %   - composition.massRatio.~ (between 0 and 1)
            %   - composition.density [g/cm^3]
            %
            %   Example:
            %       material = 'polystrene';
            %       energy = 1:120;
            %       composition = xmaterial.getComposition(material);
            %       attributes = xmaterial.getAttributes(composition,energy);
            %
            %   References:
            %       [1] McParland, Nuclear Medicine Radiation Dosimetry:
            %       Advanced Theoretical Principles (Springer, 2010)
            %
            %   See also XMATERIAL, GETCOMPOSITION
            
            %   written by Doga Gursoy
            %   date: Apr 22, 2013
            
            % get the element names
            names = fieldnames(composition.massRatio);
            
            % number of different elements
            numberOfElements = length(names);
            
            % wavelength of x-rays
            wavelength = 2*pi*xconstant.PLANCK_CONSTANT*xconstant.SPEED_OF_LIGHT./energy;
            
            % reduced energy massRatio of the incoming photon
            E = xconstant.ELECTRON_VOLT.*energy./(xconstant.ELECTRON_MASS*xconstant.SPEED_OF_LIGHT.^2);
            
            % Compton cross-section of the electron [cm^2]
            comptonCrossSection = 2*pi*xconstant.CLASSICAL_ELECTRON_RADIUS^2* ...
                (((1+E)./(E.^2)).*(2*(1+E)./(1+2*E)-log(1+2*E)./E)+log(1+2*E)./(2*E)-(1+3*E)./(1+2*E).^2);
            
            % initialize vectors
            attributes.beta = zeros(numberOfElements,length(energy));              % imaginary part of the refractive index
            attributes.delta = zeros(numberOfElements,length(energy));             % real part of the refractive index
            attributes.photoAbsorption = zeros(numberOfElements,length(energy));   % photoelectric absorption [1/cm]
            attributes.comptonScattering = zeros(numberOfElements,length(energy)); % compton scattering [1/cm]
            attributes.attenuation = zeros(numberOfElements,length(energy));       % total attenuation [1/cm]
            attributes.electronDensity = zeros(numberOfElements,length(energy));   % electron density [e/cm^3]
            
            for m = 1:numberOfElements
                % regular sampling of atomic parameters at defined energies
                element = importdata(['atomProperties/',lower(names{m}),'.mat']);
                
                % number of atoms per unit volume
                atomConcentration = composition.density.*composition.massRatio.(names{m}).*xconstant.AVOGADRO_NUMBER/element.Ar; % [1/cm^3]
                
                % interpolated form factors and attenuation coefficient based on defined energy
                f1 = interp1(element.f1(:,1),element.f1(:,2),energy);
                f2 = interp1(element.f2(:,1),element.f2(:,2),energy);
                
                % real part of refractive index
                attributes.delta(m,:) = atomConcentration.*xconstant.CLASSICAL_ELECTRON_RADIUS*wavelength.^2./(2*pi).*f1;
                
                % imaginary part of refractive index
                attributes.beta(m,:) = atomConcentration.*xconstant.CLASSICAL_ELECTRON_RADIUS*wavelength.^2./(2*pi).*f2;
                
                % x-ray attenuation from photoelectric effect [1/cm]
                attributes.photoAbsorption(m,:) = 2*atomConcentration*xconstant.CLASSICAL_ELECTRON_RADIUS.*wavelength.*f2;
                
                % x-ray attenuation from Compton scattering [1/cm]
                attributes.comptonScattering(m,:) = atomConcentration*element.Z*comptonCrossSection;
                
                % total x-ray attenuation [1/cm]
                attributes.attenuation(m,:) = attributes.photoAbsorption(m,:)+attributes.comptonScattering(m,:);
                
                % electron density [e/cm^3]
                attributes.electronDensity(m,:) = atomConcentration.*f1;
            end
            
            if numberOfElements > 1
                % sum of the contribution of each element
                attributes.beta = sum(attributes.beta);
                attributes.delta = sum(attributes.delta);
                attributes.photoAbsorption = sum(attributes.photoAbsorption);
                attributes.comptonScattering = sum(attributes.comptonScattering);
                attributes.attenuation = sum(attributes.attenuation);
                attributes.electronDensity = sum(attributes.electronDensity);
            end
        end
        
        function massRatio = getCompoundMassRatio(str)
            %GETCOMPOUNDMASSRATIO returns the MASSRATIO struct given the
            %compound formula as a string.
            %
            %   Example:
            %       str = 'H2O';
            %       massRatio = xmaterial.getCompoundMassRatio(str);
            %
            %   See also XMATERIAL, GETCOMPOSITION, GETATTRIBUTES
            
            %   written by Doga Gursoy
            %   date: Apr 22, 2013
            
            % decompose the element letters and numbers
            [elementList,~,eleEnd] = regexp(str,['[','A':'Z','][','a':'z',']?'],'match');
            elementList = lower(elementList);
            [num,numStart] = regexp(str,'\d+','match');
            numberOfAtoms = ones(size(elementList));
            Index = ismember(eleEnd+1,numStart);
            numberOfAtoms(Index) = cellfun(@str2num,num);
            
            % import files based on elements
            atomicWeight = zeros(size(elementList));
            for m = 1:length(elementList)
                % import atomic weigths of the elements
                tmp = importdata(['atomProperties/',elementList{m},'.mat']);
                
                % collect atomic weights
                atomicWeight(m) = tmp.Ar;
            end
            
            % compute the mass ratios based on atomic weights
            for m = 1:length(elementList)
                massRatio.(elementList{m}) = numberOfAtoms(m).*atomicWeight(m)./(numberOfAtoms*atomicWeight');
            end   
        end
        
        function composition = getComposition(material)
            %GETCOMPOSITION returns the mass ratios and the density of a
            %material or compound as a struct COMPOSITION. MATERIAL is a
            %char array as defined below.
            %
            %   Note that the properties of the elements are imported from
            %   the files located in atomProperties folder. New materials
            %   or compounds can be added to the existing ones.
            %
            %   Available compounds:
            %       - HA (Hydroxyapatite)                       :Ca5(PO4)3(OH)
            %       - Weddelite                                 :CaC2O4·2H2O
            %       - Water                                     :H2O
            %       - PMMA (Polymethyl methacrylate)            :C5O2H8
            %       - POM (Polyoxymethylene)                    :CH2O
            %       - PTFE (Polytetrafluoroethylene)            :C2F4
            %       - PS (Polystyrene)                          :C8H8
            %       - LDPE (Low-density polyethylene)           :C2H4
            %       - Alumina (Aluminum Oxide)                  :Al2O3
            %       - CSI (Cesium Iodide)                       :CsI
            %       - CDTE (Cadmium Telluride)                  :CdTe
            %       - NTG (Nitroglycerin)                       :C3H5N3O9
            %       - RDX (Nitroamine)                          :C3H6N6O6
            %       - HMX (Octogen)                             :C4H8N8O8
            %       - PETN (Pentaerythritol tetranitrate)       :C5H8N4O12
            %       - TNT (Trinitrotoluene)                     :C7H5N3O6
            %       - TETRYL (Trinitrophenylmethylnitramine)    :C3H5N3O9
            %
            %   Available materials:
            %       - CDZNTE (Cadmium Zinc Telluride) 90%CdTe+10%Zn
            %       - Blood (ICRU-44)
            %       - Breast (ICRU-44)
            %       - Adipose (ICRU-44)
            %       - BE-T (compact bone equivalent material)
            %       - SZ160 (cartilage bone equivalent material)
            %       - SZ207 (soft tissue equivalent material)
            %       - SZ49 (fat equivalent material)
            %       - LP (lung equivalent material)
            %
            %   Available elements:
            %       - Al :Aluminum
            %       - Au :Gold
            %       - Be :Beryllium
            %       - C  :Carbon
            %       - Ca :Calcium
            %       - Cd :Cadmium
            %       - Cl :Chlorine
            %       - Cs :Cesium
            %       - F  :Florine
            %       - Fe :Iron
            %       - H  :Hydrogen
            %       - I  :Iodine
            %       - K  :Potassium
            %       - Mg :Magnesium
            %       - N  :Nitrogen
            %       - Na :Sodium
            %       - O  :Oxygen
            %       - P  :Phosphorus
            %       - Pb :Lead
            %       - S  :Sulphur
            %       - Si :Silicon
            %       - Te :Telluride
            %       - Zn :Zinc
            %
            %   References:
            %   [1] Phys. Med. Biol. 48 673, 2003
            %   [2] ICRU Report 44, 1989
            %
            %   Example:
            %       material = 'pmma';
            %       composition = xmaterial.getComposition(material);
            %
            %   See also XMATERIAL, GETATTRIBUTES, GETCOMPOUNDMASSRATIO
            
            %   written by Doga Gursoy
            %   date: May 13, 2013
            
            str = lower(material);
            switch str
                % compounds
                case 'ha' % Hydroxyapatite Ca5(PO4)3(OH)
                    composition.massRatio = xmaterial.getCompoundMassRatio('Ca5P3O13H');
                    composition.density = 3.16; % [g/cm^3]
                    
                case 'weddellite' % CaC2O4·2H2O
                    composition.massRatio = xmaterial.getCompoundMassRatio('CaC2O6H4');
                    composition.density = 2.02; % [g/cm^3]
                    
                case 'water'
                    composition.massRatio = xmaterial.getCompoundMassRatio('H2O');
                    composition.density = 1; % [g/cm^3]
                    
                case 'pmma' % Polymethyl methacrylate
                    composition.massRatio = xmaterial.getCompoundMassRatio('C5O2H8');
                    composition.density = 1.18; % [g/cm^3]
                    
                case 'pom' % Polyoxymethylene
                    composition.massRatio = xmaterial.getCompoundMassRatio('CH2O');
                    composition.density = 1.41; % [g/cm^3]
                    
                case 'ptfe' % Polytetrafluoroethylene
                    composition.massRatio = xmaterial.getCompoundMassRatio('C2F4');
                    composition.density = 2.2; % [g/cm^3]
                    
                case 'ldpe' % Low-density polyethylene
                    composition.massRatio = xmaterial.getCompoundMassRatio('C2H4');
                    composition.density = 0.91; % [g/cm^3]
                    
                case 'ps' % Polystyrene
                    composition.massRatio = xmaterial.getCompoundMassRatio('C8H8');
                    composition.density = 1.05; % [g/cm^3]
                    
                case 'alumina' % Aluminum Oxide
                    composition.massRatio = xmaterial.getCompoundMassRatio('Al2O3');
                    composition.density = 3.95; % [g/cm^3]
                    
                case 'csi' % Cesium Iodide
                    composition.massRatio = xmaterial.getCompoundMassRatio('CsI');
                    composition.density = 4.51; % [g/cm^3]
                    
                case 'cdte' % Cadmium Telluride
                    composition.massRatio = xmaterial.getCompoundMassRatio('CdTe');
                    composition.density = 5.85; % [g/cm^3]
                    
                case 'ntg' % Nitroglycerin
                    composition.massRatio = xmaterial.getCompoundMassRatio('C3H5N3O9');
                    composition.density = 1.6; % [g/cm^3]
                    
                case 'rdx' % Nitroamine
                    composition.massRatio = xmaterial.getCompoundMassRatio('C3H6N6O6');
                    composition.density = 1.82; % [g/cm^3]
                    
                case 'hmx' % Octogen
                    composition.massRatio = xmaterial.getCompoundMassRatio('C4H8N8O8');
                    composition.density = 1.91; % [g/cm^3]
                    
                case 'petn' % Pentaerythritol tetranitrate
                    composition.massRatio = xmaterial.getCompoundMassRatio('C5H8N4O12');
                    composition.density = 1.77; % [g/cm^3]
                    
                case 'tnt' % Trinitrotoluene
                    composition.massRatio = xmaterial.getCompoundMassRatio('C7H5N3O6');
                    composition.density = 1.654; % [g/cm^3]
                    
                case 'tetryl' % Trinitrophenylmethylnitramine
                    composition.massRatio = xmaterial.getCompoundMassRatio('C3H5N3O9');
                    composition.density = 1.73; % [g/cm^3]
                    
                % Elements (in alphabetical order)
                case 'al' % Aluminum
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'au' % Gold
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'be' % Beryllium
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'c' % Carbon
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'ca' % Calcium
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'cd' % Cadmium
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'cl' % Chlorine
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'cs' % Cesium
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'f' % Fluorine
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'fe' % Iron
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'h' % Hydrogen
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'i' % Iodine
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'k' % Potassium
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'mg' % Magnesium
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'n' % Nitrogen
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'na' % Sodium
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'o' % Oxygen
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'p' % Phosphorus
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'pb' % Lead
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 's' % Sulpfur
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'si' % Silicon
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'te' % Telluride
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                case 'zn' % Zinc
                    var = importdata(['atomProperties/',str,'.mat']);
                    composition.massRatio.(str) = 1;
                    composition.density = var.rho; % [g/cm^3]
                    
                % materials (user-defined)
                case 'cdznte' % (Cadmium Zinc Telluride) 90%CdTe+10%Zn
                    composition.massRatio.cd = 0.4215;
                    composition.massRatio.te = 0.4785;
                    composition.massRatio.zn = 0.1;
                    composition.density = 5.85*0.9+7.12*0.1; % [g/cm^3]
                    
                case 'blood' % ICRU-44
                    composition.massRatio.h = 0.102;
                    composition.massRatio.c = 0.110;
                    composition.massRatio.n = 0.033;
                    composition.massRatio.o = 0.745;
                    composition.massRatio.na = 0.001;
                    composition.massRatio.p = 0.001;
                    composition.massRatio.s = 0.002;
                    composition.massRatio.cl = 0.003;
                    composition.massRatio.k = 0.002;
                    composition.massRatio.fe = 0.001;
                    composition.density = 1.06; % [g/cm^3]
                    
                case 'breast' % ICRU-44
                    composition.massRatio.h = 0.106;
                    composition.massRatio.c = 0.332;
                    composition.massRatio.n = 0.03;
                    composition.massRatio.o = 0.527;
                    composition.massRatio.na = 0.001;
                    composition.massRatio.p = 0.001;
                    composition.massRatio.s = 0.002;
                    composition.massRatio.cl = 0.001;
                    composition.density = 1.02; % [g/cm^3]
                    
                case 'adipose' % ICRU-44
                    composition.massRatio.h = 0.114;
                    composition.massRatio.c = 0.598;
                    composition.massRatio.n = 0.007;
                    composition.massRatio.o = 0.278;
                    composition.massRatio.na = 0.001;
                    composition.massRatio.s = 0.001;
                    composition.massRatio.cl = 0.001;
                    composition.density = 0.95; % [g/cm^3]
                    
                case 'be-t' % compact bone equivalent material
                    composition.massRatio.h = 0.037;
                    composition.massRatio.c = 0.292;
                    composition.massRatio.n = 0.012;
                    composition.massRatio.o = 0.327;
                    composition.massRatio.p = 0.102;
                    composition.massRatio.cl = 0.001;
                    composition.massRatio.ca = 0.229;
                    composition.density = 1.73; % [g/cm^3]
                    
                case 'sz160' % cartilage-bone equivalent material
                    composition.massRatio.h = 0.083;
                    composition.massRatio.c = 0.678;
                    composition.massRatio.n = 0.038;
                    composition.massRatio.o = 0.156;
                    composition.massRatio.p = 0.010;
                    composition.massRatio.cl = 0.035;
                    composition.density = 1.11; % [g/cm^3]
                    
                case 'sz207' % soft tissue equivalent material
                    composition.massRatio.h = 0.084;
                    composition.massRatio.c = 0.692;
                    composition.massRatio.n = 0.039;
                    composition.massRatio.o = 0.154;
                    composition.massRatio.p = 0.007;
                    composition.massRatio.cl = 0.024;
                    composition.density = 1.06; % [g/cm^3]
                    
                case 'sz49' % adipose tissue equivalent material
                    composition.massRatio.h = 0.092;
                    composition.massRatio.c = 0.720;
                    composition.massRatio.n = 0.0246;
                    composition.massRatio.o = 0.164;
                    composition.density = 1; % [g/cm^3]
                    
                case 'lp' % lung equivalent material
                    composition.massRatio.h = 0.07;
                    composition.massRatio.c = 0.502;
                    composition.massRatio.n = 0.015;
                    composition.massRatio.al = 0.351;
                    composition.massRatio.si = 0.05;
                    composition.massRatio.cl = 0.01;
                    composition.massRatio.p = 0.001;
                    composition.density = 0.3; % [g/cm^3]
            end
        end
    end
end

