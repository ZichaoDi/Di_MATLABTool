function A = readbin(filename,width,hight);
%
% A = readbin(filename,width,hight)

error1 = sprintf('Cannot open input file %s',filename);
fid = fopen(filename,'r');
if fid == -1
  error1;
  return;
end

size = [width,hight];
A = fread(fid,size,'unsigned char');
A = A';
fclose(fid);
 
return
