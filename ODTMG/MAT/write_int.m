function retval=write_int(fid, writeme)
%retval=write_int(fid, writeme)
%  Writes an integer to a dat file.
%   Milstein 2/2001

status=fwrite(fid, writeme, 'int32');
if(status ~= 1) 
  retval=-1;
  return;
end

retval=0;



