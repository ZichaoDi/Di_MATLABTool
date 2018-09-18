function [retval,readme]=read_float(fid)
%retval=read_float(fid)
%  Reads a float from a dat file.
%   Milstein 2/2001

[out, status]=fread(fid, 1 , 'float32');
if(status ~= 1) 
  retval=-1;
  readme=0;
  return;
end

retval=0;
readme=out;



