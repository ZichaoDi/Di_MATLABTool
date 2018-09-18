function [bitStream,slist] = dominantPass(y,S,LEVEL);
%
% [bitStream,slist] = dominantPass(y,S,LEVEL);
%
% Perform a dominante pass.
%   Input:
%	y: wavelet coefficients
%	S: significance map for this dominant pass
%	LEVEL: level of wavelet expansion
%   Output:
%	bitStream: bit stream generated so far
%	slist: subordinate list
%
%   Reference: J. Shapiro, Embedded image coding using zerotree of wavelet 
%   coefficients, IEEE Trans. Signal Proc., vol. 41, no. 12, Dec. 1993.
%   Created: Huipin Zhang Mon Apr 12 18:30:22 CDT 1999

N = size(S,1);

Nl = N/2^LEVEL;
% Low-low
bitStream = [];
slist = [];
for i = 1:Nl
  for j = 1:Nl
    if (S(i,j) >= 0) % POS, NEG, IZ, ZTR
      bitStream = [bitStream; S(i,j)];
      if (S(i,j) > 1) % POS, NEG
        slist = [slist; abs(y(i,j))];
      end
    end
  end
end

for scale = 1:LEVEL
  % High-low
  for i = 1:Nl
    for j = 1:Nl
      if (S(i,j+Nl) >= 0) % POS, NEG, IZ, ZTR
        bitStream = [bitStream; S(i,j+Nl)];
        if (S(i,j+Nl) > 1) % POS, NEG
          slist = [slist; abs(y(i,j+Nl))];
        end
      end
    end
  end
  % Low-high
  for i = 1:Nl
    for j = 1:Nl
      if (S(i+Nl,j) >= 0) % POS, NEG, IZ, ZTR
        bitStream = [bitStream; S(i+Nl,j)];
        if (S(i+Nl,j) > 1) % POS, NEG
          slist = [slist; abs(y(i+Nl,j))];
        end
      end
    end
  end
  % High-high
  for i = 1:Nl
    for j = 1:Nl
      if (S(i+Nl,j+Nl) >= 0) % POS, NEG, IZ, ZTR
        bitStream = [bitStream; S(i+Nl,j+Nl)];
        if (S(i+Nl,j+Nl) > 1) % POS, NEG
          slist = [slist; abs(y(i+Nl,j+Nl))];
        end
      end
    end
  end

  Nl = Nl*2;
end

return
