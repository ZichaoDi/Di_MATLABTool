function [yr,bitStream] = invSubordinatePass(bitStream,yr,stepSize,qno,map,LEVEL);
%
% [yr,bitStream] = invSubordinatePass(bitStream,yr,stepSize,qno,map,LEVEL);
%
% Inverse subordinate pass for reconstruction
%   Input:
%	bitStream: bit stream to be used for reconstruction
%	yr: reconstructed wavelet coefficients before this pass
%	stepSize: quantization value for this inverse dominant pass
%	map: gloabl map indicating already reconstructed coefficients
%	qno: number of current inverse dominant pass
%	LEVEL: level of wavelet expansion
%   Output:
%	yr: reconstructed wavelet coefficients after this pass
%	bitStream: bit stream that has not been used so far
%
%   Reference: J. Shapiro, Embedded image coding using zerotree of wavelet 
%   coefficients, IEEE Trans. Signal Proc., vol. 41, no. 12, Dec. 1993.
%   Created: Huipin Zhang, Mon Apr 12 18:42:15 CDT 1999
%

N = size(yr,1);
L = length(bitStream);

len = 0;
for k = 1:qno

Nl = N/2^LEVEL;
for i = 1:Nl
  for j = 1:Nl
    if (k == map(i,j))
      if (len+1 > L)
        bitStream = [];
        return;
      end

      symbol = bitStream(len+1);
      temp = round(abs(yr(i,j))/stepSize);
      if (1 == symbol)
        yr(i,j) = sign(yr(i,j))*stepSize*(2*temp+1)/2;
      else
        yr(i,j) = sign(yr(i,j))*stepSize*(2*temp-1)/2;
      end
      len = len+1;
    end
  end
end

for scale = 1:LEVEL
  % High-low
  for i = 1:Nl
    for j = 1:Nl
      if (k == map(i,j+Nl))
        if (len+1 > L)
          bitStream = [];
          return;
        end

        symbol = bitStream(len+1);
        temp = round(abs(yr(i,j+Nl))/stepSize);
        if (1 == symbol)
          yr(i,j+Nl) = sign(yr(i,j+Nl))*stepSize*(2*temp+1)/2;
        else
          yr(i,j+Nl) = sign(yr(i,j+Nl))*stepSize*(2*temp-1)/2;
        end
        len = len+1;
      end
    end
  end
  % Low-high
  for i = 1:Nl
    for j = 1:Nl
      if (k == map(i+Nl,j))
        if (len+1 > L)
          bitStream = [];
          return;
        end

        symbol = bitStream(len+1);
        temp = round(abs(yr(i+Nl,j))/stepSize);
        if (1 == symbol)
          yr(i+Nl,j) = sign(yr(i+Nl,j))*stepSize*(2*temp+1)/2;
        else
          yr(i+Nl,j) = sign(yr(i+Nl,j))*stepSize*(2*temp-1)/2;
        end
        len = len+1;
      end
    end
  end
  % High-high
  for i = 1:Nl
    for j = 1:Nl
      if (k == map(i+Nl,j+Nl))
        if (len+1 > L)
          bitStream = [];
          return;
        end

        symbol = bitStream(len+1);
        temp = round(abs(yr(i+Nl,j+Nl))/stepSize);
        if (1 == symbol)
          yr(i+Nl,j+Nl) = sign(yr(i+Nl,j+Nl))*stepSize*(2*temp+1)/2;
        else
          yr(i+Nl,j+Nl) = sign(yr(i+Nl,j+Nl))*stepSize*(2*temp-1)/2;
        end
        len = len+1;
      end
    end
  end

  Nl = Nl*2;
end

end % k = 1:qno

bitStream = bitStream(len+1:length(bitStream));

return
