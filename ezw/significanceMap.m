function S = significanceMap(dlist,y,T,LEVEL);
%
% S = significanceMap(dlist,y,T,LEVEL);
%
% Determine the matrix for constructing the 
% significance map for wavelet domain image y.
%
%   Input:
%	dlist: dominant list
%	y: wavelet coefficients
%	T: threshold
%	LEVEL: level of wavelet expansion
%   Output:
%	S: significance map
%
%   Reference: J. Shapiro, Embedded image coding using zerotree of wavelet 
%   coefficients, IEEE Trans. Signal Proc., vol. 41, no. 12, Dec. 1993.
%   Revised: Huipin Zhang, Mon Apr 12 19:27:01 CDT 1999

SCN = -2; % coefficient that have been scanned
ZTD = -1; % zerotree descendant
ZTR = 0;  % zerotree root, bit representation: 00
IZ  = 1;  % isolated zero, bit representation: 01
NEG = 2;  % negative significant, bit representation: 10
POS = 3;  % positive significant, bit representation: 11

N = size(y,1);
S = POS*(y>=T)+NEG*(y<=-T);
S = S.*dlist; % only 0, NEG or POS in S

% initial raw mapping step
Nl = N/2;
for level = LEVEL-1:-1:1
  Nl = Nl/2;
  for i = 1:Nl
    for j = 1:Nl
      % High-low
      if (0 == S(i,j+Nl))
        block = S(2*i-1:2*i,2*Nl+2*j-1:2*Nl+2*j);
        if (1 > block) % block == zeros(2,2)
          S(2*i-1:2*i,2*Nl+2*j-1:2*Nl+2*j) = ZTD*ones(2,2);
        else
          S(i,j+Nl) = IZ;
        end
      end
      % Low-high
      if (0 == S(i+Nl,j))
        block = S(2*Nl+2*i-1:2*Nl+2*i,2*j-1:2*j);
        if (1 > block)
          S(2*Nl+2*i-1:2*Nl+2*i,2*j-1:2*j) = ZTD*ones(2,2);
        else
          S(i+Nl,j) = IZ;
        end
      end
      % High-high 
      if (0 == S(i+Nl,j+Nl))
        block = S(2*Nl+2*i-1:2*Nl+2*i,2*Nl+2*j-1:2*Nl+2*j);
        if (1 > block)
          S(2*Nl+2*i-1:2*Nl+2*i,2*Nl+2*j-1:2*Nl+2*j) = ZTD*ones(2,2);
        else
          S(i+Nl,Nl+j) = IZ;
        end
      end

    end
  end
end

% Low-low
for i = 1:Nl
  for j = 1:Nl
    if (0 == S(i,j))
      if (0 < S(i,j+Nl) | 0 < S(i+Nl,j) | 0 < S(i+Nl,j+Nl))  % could be IZ, POS, NEG
        S(i,j) = IZ;
      else
        S(i,j+Nl) = ZTD;
        S(i+Nl,j) = ZTD;
        S(i+Nl,j+Nl) = ZTD;
      end
    end
  end
end

% Proporgate correction step
% if a node is mapped as a ZTR, but it was significant,
% this step is used to correct it.

% Low-low
for i = 1:Nl
  for j = 1:Nl
    if (ZTR == S(i,j) & 0 == dlist(i,j))
      S(i,j+Nl) = ZTR;
      S(i+Nl,j) = ZTR;
      S(i+Nl,j+Nl) = ZTR;
    end
  end
end

for k = 1:LEVEL-1
  for i = 1:Nl
    for j = 1:Nl
      % High-low
      if (ZTR == S(i,j+Nl) & 0 == dlist(i,j+Nl))
        S(2*i-1:2*i,2*Nl+2*j-1:2*Nl+2*j) = ZTR*ones(2,2);
      end
      % Low-high
      if (ZTR == S(i+Nl,j) & 0 == dlist(i+Nl,j))
        S(2*Nl+2*i-1:2*Nl+2*i,2*j-1:2*j) = ZTR*ones(2,2);
      end
      % High-high
      if (ZTR == S(i+Nl,j+Nl) & 0 == dlist(i+Nl,j+Nl))
        S(2*Nl+2*i-1:2*Nl+2*i,2*Nl+2*j-1:2*Nl+2*j) = ZTR*ones(2,2);
      end
    end
  end
  Nl = Nl*2;
end

S = S.*dlist + SCN*(1-dlist);
return

clear
% Test the following 8x8 image
T = 32;
LEVEL = 3;
N = 8;
y = [
    63   -34    49    10     7    13   -12     7;
   -31    23    14   -13     3     4     6    -1;
    15    14     3   -12     5    -7     3     9;
    -9    -7   -14     8     4    -2     3     2;
    -5     9    -1    47     4     6    -2     2;
     3     0    -3     2     3    -2     0     4;
     2    -3     6    -4     3     6     3     6;
     5    11     5     6     0     3    -4     4
];

y = [
 
    18     3     2     2
     6    -5     1    -2
     8    13    -6     4
    -7     1     3    -2
];

