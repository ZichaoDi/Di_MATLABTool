function bitsBody = readBitStream(filename);
%
% bitsBody = readBitStream(filename)
%
% Read bit stream from a binary file
%
%    Input:
%	filename: file that contains the bits stream
%    Output:
%	bitsBody: bit stream (0/1 sequence) without the header
%
% Created: Huipin Zhang, Mon Apr 12 17:29:11 CDT 1999

fid = fopen(filename,'r');
if (-1 == fid)
  msg = strcat('Cannot open input file: ',filename);
  error(msg);
end

[byteStream,count] = fread(fid,'unsigned char');
bitMatrix = de2bi(byteStream,8);
bitStream = bitMatrix(:);
lengthHeader = bitStream(1:32);
len = bi2de(lengthHeader');

L = floor(len/8);
if (len-8*L>0)
  L = L+1;
end

if (L+4>count)
  error('File not completely read!')
else
  bitsBody = bitStream(33:len+32);
end
  
return
