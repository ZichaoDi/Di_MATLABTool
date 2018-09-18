function [K,yr] = reconstruction(srcBitStream,T,N,h,LEVEL)
%
% [K,yr] = reconstruction(srcBitStream,T,N,h,LEVEL)
%
% Reconstruct the image from the given bit stream.
%    Input:
%	srcBitStream: bit stream used for reconstruction
%	T: threshold value used when encoded
%	N: image size
%	h: wavelet filter coefficients (orthogonal wavelet transforms only)
%	LEVEL: level used for wavelet expansion (reconstruction)
%    Output:
%	K: reconstructed image (spatial domain)
%	yr: reconstructed image (wavelet domain)
%
%   Reference: J. Shapiro, Embedded image coding using zerotree of wavelet 
%   coefficients, IEEE Trans. Signal Proc., vol. 41, no. 12, Dec. 1993.
%   Revised: Huipin Zhang, Mon Apr 12 18:51:18 CDT 1999

yr = zeros(N,N);
map = zeros(N,N);
stepSize = T;
qno = 1;
while (1)
  if (length(srcBitStream) < 2)
    break;
  end

  QV = 3/2*stepSize; % first reconstruction value
  [yr,srcBitStream,map,success] = invDominantPass(srcBitStream,yr,QV,map,qno,LEVEL);

  stepSize = stepSize/2; % should not move to the end of the loop
  if (1 == success)  
    [yr,srcBitStream] = invSubordinatePass(srcBitStream,yr,stepSize,qno,map,LEVEL);
  end

  qno = qno+1;
end

save yr yr h LEVEL;

K = round(midwt(yr,h,LEVEL));
K = K.*(0<K & K<256)+(K>255)*255;

return
