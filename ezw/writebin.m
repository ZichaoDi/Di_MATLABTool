function [] = writebin(A,filename,width,hight);
%
% [] = writebin(A,filename,width,hight)
 
error1 = sprintf('Cannot open output file %s',filename);
fid = fopen(filename,'w');
if fid==-1
  error1;
  return;
end

size = [width,hight];
A = A';
fwrite(fid,A(1:hight,1:width),'unsigned char');
fclose(fid);
 
return
