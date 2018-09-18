function [retval,readme]=read_int(fid)
%[retval, readme]=read_int(fid)
%  Reads an integer from a dat file.
%   Milstein 2/2001

[out, status]=fread(fid, 1 , 'int32');
if(status ~= 1) 
  retval=-1;
  readme=0;
  return;
end

retval=0;
readme=out;



