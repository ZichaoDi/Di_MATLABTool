function [] = writeBitStream(a,filename);
%
% [] = writeBitStream(a,filename)
%
% Write a 0/1 vector into binary form, 32 bit header 
% is added indicating the length of the stream
%
%    Input:
%	a: a bit stream (0/1 sequence, i.e., vector)
%	filename: file in which bit stream will be written
%
% Created: Huipin Zhang, Mon Apr 12 17:29:11 CDT 1999

fid = fopen(filename,'w');
if (-1 == fid)
  msg = strcat('Cannot open output file: ',filename);
  error(msg);
end

bitsBody = a(:);
len = length(a);
L = mod(len,8);
if (0~=L)
  bitsBody = [bitsBody;zeros(8-L,1)];
end

LengthHeader = de2bi(len,32); % Length of bit stream at most 2^32
bitStream = [LengthHeader';bitsBody];
byteStream = bi2de(reshape(bitStream,length(bitStream)/8,8));
fwrite(fid,byteStream,'unsigned char');
fclose(fid);

return
