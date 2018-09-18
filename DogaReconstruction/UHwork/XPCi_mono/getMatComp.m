function comp = getMatComp(compoundName)
% get the mass ratios and density values for tissue and compounds in a structure.

switch lower(compoundName)
    
    case 'blood' % according to NIST database (ICRU-44)
        
        comp.ratio.h = 0.102;
        comp.ratio.c = 0.110;
        comp.ratio.n = 0.033;
        comp.ratio.o = 0.745;
        comp.ratio.na = 0.001;
        comp.ratio.p = 0.001;
        comp.ratio.s = 0.002;
        comp.ratio.cl = 0.003;
        comp.ratio.k = 0.002;
        comp.ratio.fe = 0.001;
        
        comp.density = 1.06; % [g/cm^3]
        
    case 'adipose_wernick'
        
        % ratios
        comp.ratio.h = 0.118;
        comp.ratio.c = 0.656;
        comp.ratio.n = 0.009;
        comp.ratio.o = 0.217;
        comp.ratio.cl = 0.001;
        comp.ratio.p = 0.001;
        
        comp.density = 0.925; % [g/cm^3]
        
    case 'glandular_wernick'
        
        % ratios
        comp.ratio.h = 0.098;
        comp.ratio.c = 0.184;
        comp.ratio.n = 0.038;
        comp.ratio.o = 0.678;
        comp.ratio.p = 0.005;
        
        comp.density = 1.038; % [g/cm^3]
        
    case 'adipose_hammerstein'
        
        % ratios
        comp.ratio.h = 0.112;
        comp.ratio.c = 0.619;
        comp.ratio.n = 0.017;
        comp.ratio.o = 0.251;
        comp.ratio.p = 0.001;
        
        comp.density = 0.928; % [g/cm^3]
        
    case 'glandular_hammerstein'
        
        % ratios
        comp.ratio.h = 0.102;
        comp.ratio.c = 0.1815;
        comp.ratio.n = 0.032;
        comp.ratio.o = 0.677;
        comp.ratio.p = 0.005;
        
        comp.density = 1.047; % [g/cm^3]
        
    case 'lesion_hammerstein'
        
        % ratios
        comp.ratio.h = 0.102;
        comp.ratio.c = 0.1815;
        comp.ratio.n = 0.032;
        comp.ratio.o = 0.675;
        comp.ratio.p = 0.005;
        comp.ratio.ca = 0.002;
        
        comp.density = 1.147; % [g/cm^3]
        
    case 'breast' % according to NIST database (ICRU-44)
        
        % ratios
        comp.ratio.h = 0.106;
        comp.ratio.c = 0.332;
        comp.ratio.n = 0.03;
        comp.ratio.o = 0.527;
        comp.ratio.na = 0.001;
        comp.ratio.p = 0.001;
        comp.ratio.s = 0.002;
        comp.ratio.cl = 0.001;
        
        comp.density = 1.02; % [g/cm^3]
        
    case 'adipose' % according to NIST database (ICRU-44)
        
        % ratios
        comp.ratio.h = 0.114;
        comp.ratio.c = 0.598;
        comp.ratio.n = 0.007;
        comp.ratio.o = 0.278;
        comp.ratio.na = 0.001;
        comp.ratio.s = 0.001;
        comp.ratio.cl = 0.001;
        
        comp.density = 0.95; % [g/cm^3]
        
    case 'lesion' % user-defined lesion w.r.t glandular tissue
        
        % ratios
        comp.ratio.h = 0.102;
        comp.ratio.c = 0.1775;
        comp.ratio.n = 0.032;
        comp.ratio.o = 0.677;
        comp.ratio.p = 0.005;
        comp.ratio.ca = 0.004;
        
        comp.density = 1.047*1.04; % [g/cm^3]
        
    case 'be-t' % compact bone equivalent compound
        
        comp.ratio.h = 0.037;
        comp.ratio.c = 0.292;
        comp.ratio.n = 0.012;
        comp.ratio.o = 0.327;
        comp.ratio.p = 0.102;
        comp.ratio.cl = 0.001;
        comp.ratio.ca = 0.229;
        
        comp.density = 1.73; % [g/cm^3]
        
    case 'sz160' % cartilage-bone equivalent compound
        
        comp.ratio.h = 0.083;
        comp.ratio.c = 0.678;
        comp.ratio.n = 0.038;
        comp.ratio.o = 0.156;
        comp.ratio.p = 0.010;
        comp.ratio.cl = 0.035;
        
        comp.density = 1.11; % [g/cm^3]
        
    case 'sz207' % soft tissue equivalent compound
        
        comp.ratio.h = 0.084;
        comp.ratio.c = 0.692;
        comp.ratio.n = 0.039;
        comp.ratio.o = 0.154;
        comp.ratio.p = 0.007;
        comp.ratio.cl = 0.024;
        
        comp.density = 1.06; % [g/cm^3]
        
    case 'sz49' % adipose tissue equivalent compound
        
        comp.ratio.h = 0.092;
        comp.ratio.c = 0.720;
        comp.ratio.n = 0.024;
        comp.ratio.o = 0.164;
        
        comp.density = 1; % [g/cm^3]
        
    case 'hydroxylapatite' % Ca5(PO4)3(OH) calcification equivalent compound
        
        % get element data
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        o = importdata('/home/doga/Documents/MATLAB/data/atomProperties/o.mat');
        p = importdata('/home/doga/Documents/MATLAB/data/atomProperties/p.mat');
        ca = importdata('/home/doga/Documents/MATLAB/data/atomProperties/ca.mat');
        
        a = [1 13 3 5];
        
        comp.ratio.h = a(1)*h.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*p.Ar+a(4)*ca.Ar);
        comp.ratio.o = a(2)*o.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*p.Ar+a(4)*ca.Ar);
        comp.ratio.p = a(3)*p.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*p.Ar+a(4)*ca.Ar);
        comp.ratio.ca = a(4)*ca.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*p.Ar+a(4)*ca.Ar);
        
        comp.density = 3.16; % [g/cm^3]
        
    case 'weddellite' % CaC2O4·2H2O calcification equivalent compound
        
        % get element data
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        c = importdata('/home/doga/Documents/MATLAB/data/atomProperties/c.mat');
        o = importdata('/home/doga/Documents/MATLAB/data/atomProperties/o.mat');
        ca = importdata('/home/doga/Documents/MATLAB/data/atomProperties/ca.mat');
        
        a = [3 2 6 1];
        
        comp.ratio.h = a(1)*h.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*ca.Ar);
        comp.ratio.c = a(2)*c.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*ca.Ar);
        comp.ratio.o = a(3)*o.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*ca.Ar);
        comp.ratio.ca = a(4)*ca.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*ca.Ar);
        
        comp.density = 2.02; % [g/cm^3]
        
    case 'water' % h2o
        
        % get element data
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        o = importdata('/home/doga/Documents/MATLAB/data/atomProperties/o.mat');
        
        a = [2 1];
        
        comp.ratio.h = a(1)*h.Ar./(a(1)*h.Ar+a(2)*o.Ar);
        comp.ratio.o = a(2)*o.Ar./(a(1)*h.Ar+a(2)*o.Ar);
        
        comp.density = 1; % [g/cm^3]
        
    case 'pmma' % c5o2h8
        
        % get element data
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        c = importdata('/home/doga/Documents/MATLAB/data/atomProperties/c.mat');
        o = importdata('/home/doga/Documents/MATLAB/data/atomProperties/o.mat');
        
        a = [8 5 2];
        
        comp.ratio.h = a(1)*h.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar);
        comp.ratio.c = a(2)*c.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar);
        comp.ratio.o = a(3)*o.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar);
        
        comp.density = 1.18; % [g/cm^3]
        
    case 'pom' % ch2o
        
        % get element data
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        c = importdata('/home/doga/Documents/MATLAB/data/atomProperties/c.mat');
        o = importdata('/home/doga/Documents/MATLAB/data/atomProperties/o.mat');
        
        a = [2 1 1];
        
        comp.ratio.h = a(1)*h.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar);
        comp.ratio.c = a(2)*c.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar);
        comp.ratio.o = a(3)*o.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar);
        
        comp.density = 1.41; % [g/cm^3]
        
    case 'ptfe' % c2f4
        
        % get element data
        c = importdata('/home/doga/Documents/MATLAB/data/atomProperties/c.mat');
        f = importdata('/home/doga/Documents/MATLAB/data/atomProperties/f.mat');
        
        a = [2 4];
        
        comp.ratio.c = a(1)*c.Ar./(a(1)*c.Ar+a(2)*f.Ar);
        comp.ratio.f = a(2)*f.Ar./(a(1)*c.Ar+a(2)*f.Ar);
        
        comp.density = 2.2; % [g/cm^3]
        
    case 'polystrene' % c8h8
        
        % get element data
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        c = importdata('/home/doga/Documents/MATLAB/data/atomProperties/c.mat');
        
        a = [8 8];
        
        comp.ratio.h = a(1)*h.Ar./(a(1)*h.Ar+a(2)*c.Ar);
        comp.ratio.c = a(2)*c.Ar./(a(1)*h.Ar+a(2)*c.Ar);
        
        comp.density = 1.1; % [g/cm^3]
        
    case 'ldpe' % c2h4
        
        % get element data
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        c = importdata('/home/doga/Documents/MATLAB/data/atomProperties/c.mat');
        
        a = [4 2];
        
        comp.ratio.h = a(1)*h.Ar./(a(1)*c.Ar+a(2)*h.Ar);
        comp.ratio.c = a(2)*c.Ar./(a(1)*c.Ar+a(2)*h.Ar);
        
        comp.density = 0.91; % [g/cm^3]
        
    case 'ps' %
        
        % get element data
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        c = importdata('/home/doga/Documents/MATLAB/data/atomProperties/c.mat');
        
        a = [8 8];
        
        comp.ratio.h = a(1)*h.Ar./(a(1)*c.Ar+a(2)*h.Ar);
        comp.ratio.c = a(2)*c.Ar./(a(1)*c.Ar+a(2)*h.Ar);
        
        comp.density = 1.05; % [g/cm^3]
        
    case 'lesion1' % user-defined lesion w.r.t glandular tissue
        
        % ratios
        comp.ratio.h = 0.106;
        comp.ratio.c = 0.332;
        comp.ratio.n = 0.03;
        comp.ratio.o = 0.527;
        comp.ratio.na = 0.001;
        comp.ratio.p = 0.001;
        comp.ratio.s = 0.002;
        comp.ratio.cl = 0.001;
        
        comp.density = 1.04; % [g/cm^3]
        
    case 'lesion2' % user-defined lesion w.r.t glandular tissue
        
        % ratios
        comp.ratio.h = 0.106;
        comp.ratio.c = 0.332;
        comp.ratio.n = 0.03;
        comp.ratio.o = 0.527;
        comp.ratio.na = 0.001;
        comp.ratio.p = 0.001;
        comp.ratio.s = 0.002;
        comp.ratio.cl = 0.001;
        
        comp.density = 1.06; % [g/cm^3]
        
    case 'lesion3' % user-defined lesion w.r.t glandular tissue
        
        % ratios
        comp.ratio.h = 0.106;
        comp.ratio.c = 0.332;
        comp.ratio.n = 0.03;
        comp.ratio.o = 0.527;
        comp.ratio.na = 0.001;
        comp.ratio.p = 0.001;
        comp.ratio.s = 0.002;
        comp.ratio.cl = 0.001;
        
        comp.density = 1.08; % [g/cm^3]
        
    case 'lesion4' % user-defined lesion w.r.t glandular tissue
        
        % ratios
        comp.ratio.h = 0.106;
        comp.ratio.c = 0.332;
        comp.ratio.n = 0.03;
        comp.ratio.o = 0.527;
        comp.ratio.na = 0.001;
        comp.ratio.p = 0.001;
        comp.ratio.s = 0.002;
        comp.ratio.cl = 0.001;
        
        comp.density = 1.1; % [g/cm^3]
        
    case 'lesion5' % user-defined lesion w.r.t glandular tissue
        
        % ratios
        comp.ratio.h = 0.106;
        comp.ratio.c = 0.332;
        comp.ratio.n = 0.03;
        comp.ratio.o = 0.527;
        comp.ratio.na = 0.001;
        comp.ratio.p = 0.001;
        comp.ratio.s = 0.002;
        comp.ratio.cl = 0.001;
        
        comp.density = 1.12; % [g/cm^3]
        
    case 'lesion6' % user-defined lesion w.r.t glandular tissue
        
        % ratios
        comp.ratio.h = 0.106;
        comp.ratio.c = 0.332;
        comp.ratio.n = 0.03;
        comp.ratio.o = 0.527;
        comp.ratio.na = 0.001;
        comp.ratio.p = 0.001;
        comp.ratio.s = 0.002;
        comp.ratio.cl = 0.001;
        comp.ratio.ca = 0.001;
        
        comp.density = 1.14; % [g/cm^3]
        
    case 'lesiona' % user-defined lesion w.r.t glandular tissue
        
        % ratios
        comp.ratio.h = 0.106;
        comp.ratio.c = 0.33;
        comp.ratio.n = 0.03;
        comp.ratio.o = 0.527;
        comp.ratio.na = 0.001;
        comp.ratio.p = 0.001;
        comp.ratio.s = 0.002;
        comp.ratio.cl = 0.001;
        comp.ratio.ca = 0.002;
        
        comp.density = 1.02; % [g/cm^3]
        
    case 'lesionb' % user-defined lesion w.r.t glandular tissue
        
        % ratios
        comp.ratio.h = 0.106;
        comp.ratio.c = 0.328;
        comp.ratio.n = 0.03;
        comp.ratio.o = 0.527;
        comp.ratio.na = 0.001;
        comp.ratio.p = 0.001;
        comp.ratio.s = 0.002;
        comp.ratio.cl = 0.001;
        comp.ratio.ca = 0.004;
        
        comp.density = 1.02; % [g/cm^3]
        
    case 'lesionc' % user-defined lesion w.r.t glandular tissue
        
        % ratios
        comp.ratio.h = 0.106;
        comp.ratio.c = 0.326;
        comp.ratio.n = 0.03;
        comp.ratio.o = 0.527;
        comp.ratio.na = 0.001;
        comp.ratio.p = 0.001;
        comp.ratio.s = 0.002;
        comp.ratio.cl = 0.001;
        comp.ratio.ca = 0.006;
        
        comp.density = 1.02; % [g/cm^3]
        
    case 'lesiond' % user-defined lesion w.r.t glandular tissue
        
        % ratios
        comp.ratio.h = 0.106;
        comp.ratio.c = 0.324;
        comp.ratio.n = 0.03;
        comp.ratio.o = 0.527;
        comp.ratio.na = 0.001;
        comp.ratio.p = 0.001;
        comp.ratio.s = 0.002;
        comp.ratio.cl = 0.001;
        comp.ratio.ca = 0.008;
        
        comp.density = 1.02; % [g/cm^3]
        
    case 'lesione' % user-defined lesion w.r.t glandular tissue
        
        % ratios
        comp.ratio.h = 0.106;
        comp.ratio.c = 0.322;
        comp.ratio.n = 0.03;
        comp.ratio.o = 0.527;
        comp.ratio.na = 0.001;
        comp.ratio.p = 0.001;
        comp.ratio.s = 0.002;
        comp.ratio.cl = 0.001;
        comp.ratio.ca = 0.01;
        
        comp.density = 1.02; % [g/cm^3]
        
    case 'lesionf' % user-defined lesion w.r.t glandular tissue
        
        % ratios
        comp.ratio.h = 0.106;
        comp.ratio.c = 0.32;
        comp.ratio.n = 0.03;
        comp.ratio.o = 0.527;
        comp.ratio.na = 0.001;
        comp.ratio.p = 0.001;
        comp.ratio.s = 0.002;
        comp.ratio.cl = 0.001;
        comp.ratio.ca = 0.012;
        
        comp.density = 1.02; % [g/cm^3]
        
    case 'alumina' % Al2o3
        
        % get element data
        al = importdata('/home/doga/Documents/MATLAB/data/atomProperties/al.mat');
        o = importdata('/home/doga/Documents/MATLAB/data/atomProperties/o.mat');
        
        a = [2 3];
        
        comp.ratio.al = a(1)*al.Ar./(a(1)*al.Ar+a(2)*o.Ar);
        comp.ratio.o = a(2)*o.Ar./(a(1)*al.Ar+a(2)*o.Ar);
        
        comp.density = 3.95; % [g/cm^3]
        
    case 'csi' % CsI scintillation detector
        
        % get element data
        cs = importdata('/home/doga/Documents/MATLAB/data/atomProperties/cs.mat');
        i = importdata('/home/doga/Documents/MATLAB/data/atomProperties/i.mat');
        
        a = [1 1];
        
        comp.ratio.cs = a(1)*cs.Ar./(a(1)*cs.Ar+a(2)*i.Ar);
        comp.ratio.i = a(2)*i.Ar./(a(1)*cs.Ar+a(2)*i.Ar);
        
        comp.density = 4.51; % [g/cm^3]
        
    case 'cdte' % Cadmium-Telluride 
        
        % get element data
        cd = importdata('/home/doga/Documents/MATLAB/data/atomProperties/cd.mat');
        te = importdata('/home/doga/Documents/MATLAB/data/atomProperties/te.mat');
        
        a = [1 1];
        
        comp.ratio.cd = a(1)*cd.Ar./(a(1)*cd.Ar+a(2)*te.Ar);
        comp.ratio.te = a(2)*te.Ar./(a(1)*cd.Ar+a(2)*te.Ar);
        
        comp.density = 5.85; % [g/cm^3]
        
    case 'cdznte' % Cadmium-Telluride 
        
        comp.ratio.cd = 0.4215;
        comp.ratio.te = 0.4785;
        comp.ratio.zn = 0.1;
        
        comp.density = 5.85*0.9+7.12*0.1; % [g/cm^3]
        
    case 'lead' % Pb
        
        % ratios
        pb = importdata('/home/doga/Documents/MATLAB/data/atomProperties/pb.mat');
        comp.ratio.pb = 1;
        
        comp.density = pb.rho; % [g/cm^3]
        
        
    case 'al' % Aluminum
        
        % ratios
        al = importdata('/home/doga/Documents/MATLAB/data/atomProperties/al.mat');
        comp.ratio.al = 1;
        
        comp.density = al.rho; % [g/cm^3]
        
    case 'h' % Hydrogen
        
        % ratios
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        comp.ratio.h = 1;
        
        comp.density = h.rho; % [g/cm^3]
        
    case 'o' % Oxygen
        
        % ratios
        o = importdata('/home/doga/Documents/MATLAB/data/atomProperties/o.mat');
        comp.ratio.o = 1;
        
        comp.density = o.rho; % [g/cm^3]
        
    case 'c' % Carbon
        
        % ratios
        c = importdata('/home/doga/Documents/MATLAB/data/atomProperties/c.mat');
        comp.ratio.c = 1;
        
        comp.density = c.rho; % [g/cm^3]
        
    case 'n' % Nitrogen
        
        % ratios
        n = importdata('/home/doga/Documents/MATLAB/data/atomProperties/n.mat');
        comp.ratio.n = 1;
        
        comp.density = n.rho; % [g/cm^3]
        
    case 'i' % Iodine
        
        % ratios
        i = importdata('/home/doga/Documents/MATLAB/data/atomProperties/i.mat');
        comp.ratio.i = 1;
        
        comp.density = i.rho; % [g/cm^3]
        
    case 'be' % Berilium
        
        % ratios
        be = importdata('/home/doga/Documents/MATLAB/data/atomProperties/be.mat');
        comp.ratio.be = 1;
        
        comp.density = be.rho; % [g/cm^3]
        
    case 'si' % Silicon
        
        % ratios
        si = importdata('/home/doga/Documents/MATLAB/data/atomProperties/si.mat');
        comp.ratio.si = 1;
        
        comp.density = si.rho; % [g/cm^3]
        
    case 'nitroglycerin' % c3h5n3o9
        
        % get element data
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        c = importdata('/home/doga/Documents/MATLAB/data/atomProperties/c.mat');
        o = importdata('/home/doga/Documents/MATLAB/data/atomProperties/o.mat');
        n = importdata('/home/doga/Documents/MATLAB/data/atomProperties/n.mat');
        
        a = [3 5 3 9];
        
        comp.ratio.h = a(1)*h.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.c = a(2)*c.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.o = a(3)*o.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.n = a(4)*n.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        
        comp.density = 1.6; % [g/cm^3]
        
    case 'rdx' % nitroamine c3h6n6o6
        
        % get element data
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        c = importdata('/home/doga/Documents/MATLAB/data/atomProperties/c.mat');
        o = importdata('/home/doga/Documents/MATLAB/data/atomProperties/o.mat');
        n = importdata('/home/doga/Documents/MATLAB/data/atomProperties/n.mat');
        
        a = [3 6 6 6];
        
        comp.ratio.h = a(1)*h.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.c = a(2)*c.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.o = a(3)*o.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.n = a(4)*n.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        
        comp.density = 1.82; % [g/cm^3]
        
    case 'hmx' % c4h8n8o8
        
        % get element data
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        c = importdata('/home/doga/Documents/MATLAB/data/atomProperties/c.mat');
        o = importdata('/home/doga/Documents/MATLAB/data/atomProperties/o.mat');
        n = importdata('/home/doga/Documents/MATLAB/data/atomProperties/n.mat');
        
        a = [4 8 8 8];
        
        comp.ratio.h = a(1)*h.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.c = a(2)*c.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.o = a(3)*o.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.n = a(4)*n.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        
        comp.density = 1.91; % [g/cm^3]
        
    case 'petn' % Pentaerythritol tetranitrate c5h8n4o12
        
        % get element data
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        c = importdata('/home/doga/Documents/MATLAB/data/atomProperties/c.mat');
        o = importdata('/home/doga/Documents/MATLAB/data/atomProperties/o.mat');
        n = importdata('/home/doga/Documents/MATLAB/data/atomProperties/n.mat');
        
        a = [5 8 4 12];
        
        comp.ratio.h = a(1)*h.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.c = a(2)*c.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.o = a(3)*o.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.n = a(4)*n.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        
        comp.density = 1.77; % [g/cm^3]
        
    case 'tnt' % Trinitrotoluene c7h5n3o6
        
        % get element data
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        c = importdata('/home/doga/Documents/MATLAB/data/atomProperties/c.mat');
        o = importdata('/home/doga/Documents/MATLAB/data/atomProperties/o.mat');
        n = importdata('/home/doga/Documents/MATLAB/data/atomProperties/n.mat');
        
        a = [7 5 3 6];
        
        comp.ratio.h = a(1)*h.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.c = a(2)*c.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.o = a(3)*o.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.n = a(4)*n.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        
        comp.density = 1.654; % [g/cm^3]
        
    case 'tetryl' % c3h5n3o9
        
        % get element data
        h = importdata('/home/doga/Documents/MATLAB/data/atomProperties/h.mat');
        c = importdata('/home/doga/Documents/MATLAB/data/atomProperties/c.mat');
        o = importdata('/home/doga/Documents/MATLAB/data/atomProperties/o.mat');
        n = importdata('/home/doga/Documents/MATLAB/data/atomProperties/n.mat');
        
        a = [7 5 5 8];
        
        comp.ratio.h = a(1)*h.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.c = a(2)*c.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.o = a(3)*o.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        comp.ratio.n = a(4)*n.Ar./(a(1)*h.Ar+a(2)*o.Ar+a(3)*c.Ar+a(4)*n.Ar);
        
        comp.density = 1.73; % [g/cm^3]
end

end

