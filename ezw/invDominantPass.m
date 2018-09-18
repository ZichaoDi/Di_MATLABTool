function [yr,bitStream,map,success] = invDominantePass(bitStream,yr,QV,map,qno,LEVEL);
%
% [yr,bitStream,map,success] = invDominantePass(bitStream,yr,QV,map,qno,LEVEL);
%
% Inverse dominant pass for reconstruction
%   Input:
%	bitStream: bit stream to be used for reconstruction
%	yr: reconstructed wavelet coefficients before this pass
%	QV: quantization value for this inverse dominant pass
%	map: gloabl map indicating already reconstructed coefficients
%	qno: number of current inverse dominant pass
%	LEVEL: level of wavelet expansion
%   Output:
%	yr: reconstructed wavelet coefficients after this pass
%	bitStream: bit stream that has not been used so far
%	map: gloabl map indicating already reconstructed coefficients
%	success: indicating whether this pass is performed successfully
%
%   Reference: J. Shapiro, Embedded image coding using zerotree of wavelet 
%   coefficients, IEEE Trans. Signal Proc., vol. 41, no. 12, Dec. 1993.
%   Created: Huipin Zhang Mon Apr 12 18:42:50 CDT 1999

SCN = -2; % coefficient that have been scanned
ZTD = -1; % zerotree descendant
ZTR = 0;  % zerotree root, bit representation: 00
IZ  = 1;  % isolated zero, bit representation: 01
NEG = 2;  % negative significant, bit representation: 10
POS = 3;  % positive significant, bit representation: 11

success = 0; % default false
N = size(yr,1);
L = length(bitStream);

len = 0;
localMap = zeros(N,N);
Nl = N/2^LEVEL;
for i = 1:Nl
  for j = 1:Nl
    if (0 == yr(i,j)) % not reconstructed so far
      if (len+2 > L)
        bitStream = bitStream(len+1:length(bitStream));
        return;
      end

      symbol = bitStream(len+1:2+len);
      symbol = bi2de(symbol');
      if (symbol == ZTR)
        for scale = 1:LEVEL
          step = 2^(scale-1);
          % three different orientation
          localMap(step*(i-1)+1:step*i,step*(Nl+j-1)+1:step*(Nl+j)) = SCN*ones(step,step);
          localMap(step*(Nl+i-1)+1:step*(Nl+i),step*(j-1)+1:step*j) = SCN*ones(step,step);
          localMap(step*(Nl+i-1)+1:step*(Nl+i),step*(Nl+j-1)+1:step*(Nl+j)) = SCN*ones(step,step);
        end
      elseif (symbol == POS)
        yr(i,j) = QV;
        map(i,j) = qno;
      elseif (symbol == NEG)
        yr(i,j) = -QV;
        map(i,j) = qno;
      end
      len = len+2;
    end
  end
end

for scale = 1:LEVEL
  % High-low
  for i = 1:Nl
    for j = 1:Nl
      if (0 == yr(i,j+Nl)) % not reconstructed so far
        if (localMap(i,j+Nl) ~= SCN)
          if (len+2 > L)
            bitStream = bitStream(len+1:length(bitStream));
            return;
          end
 
          symbol = bitStream(len+1:2+len);
          symbol = bi2de(symbol'); % POS, NEG, IZ, ZTR
          if (symbol == ZTR)
            for scl = scale+1:LEVEL
              step = 2^(scl-scale);
              localMap(step*(i-1)+1:step*i,step*(Nl+j-1)+1:step*(Nl+j)) = SCN*ones(step,step);
            end
          elseif (symbol == POS)
            yr(i,j+Nl) = QV;
            map(i,j+Nl) = qno;
          elseif (symbol == NEG)
            yr(i,j+Nl) = -QV;
            map(i,j+Nl) = qno;
          end
          len = len+2;
        end
      end
    end
  end
  % Low-high
  for i = 1:Nl
    for j = 1:Nl
      if (0 == yr(i+Nl,j)) % not reconstructed so far
        if (localMap(i+Nl,j) ~= SCN)
          if (len+2 > L)
            bitStream = bitStream(len+1:length(bitStream));
            return;
          end

          symbol = bitStream(len+1:2+len);
          symbol = bi2de(symbol'); % POS, NEG, IZ, ZTR
          if (symbol == ZTR)
            for scl = scale+1:LEVEL
              step = 2^(scl-scale);
              localMap(step*(Nl+i-1)+1:step*(Nl+i),step*(j-1)+1:step*(j)) = SCN*ones(step,step);
            end
          elseif (symbol == POS)
            yr(i+Nl,j) = QV;
            map(i+Nl,j) = qno;
          elseif (symbol == NEG)
            yr(i+Nl,j) = -QV;
            map(i+Nl,j) = qno;
          end
          len = len+2;
        end
      end
    end
  end
  % High-high
  for i = 1:Nl
    for j = 1:Nl
      if (0 == yr(i+Nl,j+Nl)) % not reconstructed so far
        if (localMap(i+Nl,j+Nl) ~= SCN)
          if (len+2 > L)
            bitStream = bitStream(len+1:length(bitStream));
            return;
          end

          symbol = bitStream(len+1:2+len);
          symbol = bi2de(symbol'); % POS, NEG, IZ, ZTR
          if (symbol == ZTR)
            for scl = scale+1:LEVEL
              step = 2^(scl-scale);
              localMap(step*(Nl+i-1)+1:step*(Nl+i),step*(Nl+j-1)+1:step*(Nl+j)) = SCN*ones(step,step);
            end
          elseif (symbol == POS)
            yr(i+Nl,j+Nl) = QV;
            map(i+Nl,j+Nl) = qno;
          elseif (symbol == NEG)
            yr(i+Nl,j+Nl) = -QV;
            map(i+Nl,j+Nl) = qno;
          end
          len = len+2;
        end
      end
    end
  end

  Nl = Nl*2;
end

bitStream = bitStream(len+1:length(bitStream));
success = 1; % successfully complete this process
return
