function retval=write_float(fid, writeme)
%retval=write_float(fid, writeme)
%  Writes an float to a dat file.
%   Milstein 2/2001

status=fwrite(fid, writeme, 'float32');
if(status ~= 1) 
  retval=-1;
  return;
end

retval=0;



