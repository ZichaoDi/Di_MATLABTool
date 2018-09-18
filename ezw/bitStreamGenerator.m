function [I,y,L] = bitStreamGenerator(bitfilename,srcfilename,size,h,LEVEL,tol);
%
% [I,y,L] = bitStreamGenerator(bitfilename,srcfilename,size,h,LEVEL,tol);
%
% For a given image generate the bit stream which can reconstruct it perfectly.
% See the example at the end of the file for usage.
%
%    Input:
%	bitfilename: file in which the bit stream will be written
%	srcfilename: binary file containing the cource image
%	size: size of the source image
%	h: wavelet filter coefficients (orthogonal wavelet transforms only)
%	LEVEL: level of wavelet expansion
%	tol: smallest coefficient (in module) that can be reconstructed by the bit stream
%    Output:
%	I: image in spatial domain
%	y: image in wavelet domain
%	L: number of bytes of the source code (including 5 bytes header)
%
%   Reference: J. Shapiro, Embedded image coding using zerotree of wavelet 
%   coefficients, IEEE Trans. Signal Proc., vol. 41, no. 12, Dec. 1993.
%   Created: Huipin Zhang, Mon Tue Mar 30 00:00:14 CST 1999

SCN = -2; % coefficient that have been scanned
ZTD = -1; % zerotree descendant
ZTR = 0;  % zerotree root, bit representation: 00
IZ  = 1;  % isolated zero, bit representation: 01
NEG = 2;  % negative significant, bit representation: 10
POS = 3;  % positive significant, bit representation: 11

% input image
N = size;
I = readbin(srcfilename,N,N);

% Wavelet transform

load y.mat;

%y = mdwt(I,h,LEVEL);
T = 2^floor(log2(max(max(abs(y)))));

% write header at the very beginning of the bit stream (optional)
% number of wavelet scales (LEVEL)	4 bits (sixteen level maximal)
% image dimension (N)			10 bits (1024x1024 maximal)
% initial threshold (T)			26 bits (OK for general image)
% Total:				40 bits = 5 bytes
header = [de2bi(LEVEL,4)'; de2bi(N,10)'; de2bi(T,26)'];
bitStream = header;

% start generating bit stream using EZW algorithm
qno = 1;
dominantList = ones(N,N);
stepSize = T;
subordinateList = [];
while (stepSize > tol)

  S = significanceMap(dominantList,y,stepSize,LEVEL);
  [bits,sl] = dominantPass(y,S,LEVEL);

  subordinateList = [subordinateList;sl];
  bits = reshape(de2bi(bits,2)',2*length(bits),1);
  bitStream =[bitStream;bits];

  bits = subordinatePass(subordinateList,T,qno);
  bitStream = [bitStream;bits];

  dominantList = (S > SCN).*(S < NEG);
  stepSize = stepSize/2;
  qno = qno + 1;
end

L = floor(length(bitStream)/8);
bitStreamSave = bitStream(1:8*L);
bss = bi2de(reshape(bitStreamSave,L,8));
writebin(bss,bitfilename,L,1);

return

clear;clf
N = 256;
h = daubcqf(8,'min');
LEVEL = 6;
tol = 0.1;
[I,y,L] = bitStreamGenerator('bitLenna','lenna.256',N,h,LEVEL,tol);

figure(1)
imshow(I,gray(256))

figure(2)
imshow(y,gray(32))
