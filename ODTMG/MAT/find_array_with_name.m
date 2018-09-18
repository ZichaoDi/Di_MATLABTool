function retval=find_array_with_name(fid, name, dims)
% retval=find_array_with_name(fid, name, dims)
%  Searches header of dat file for the dimensions of
%  array called "name".  It then advances the file position
%  indicator of fid to the location of the data.  

frewind(fid);
HEADERSIZE=1024;
offset_sum=0;
for i=1:HEADERSIZE
  [testch, status]=fscanf(fid, '%c',1);
  dim_product=1;
  if (testch=='>')
    [buf, status]=fscanf(fid, '%s ', 1);
    if (strcmp(buf,name))
      break;
    end
    [ndims, status]=fscanf(fid, '%d ',1);
    for j=1:ndims
      [dim_cur, status]=fscanf(fid, '%d ',1);
      dim_product=dim_product*dim_cur;
    end
    offset_sum=offset_sum+dim_product+1;
  end
end

if (strcmp(buf,name)~=1)
  fprintf(1,'find_array_with_name:\n'); 
  fprintf(1,'%s is not found in file\n',name);  
  retval=-1;
  return;
end
fseek(fid, HEADERSIZE+4*offset_sum, 'bof');

[status, sanity_test]=read_int(fid);

if (sanity_test~=0)
  fprintf(1,'read_float_array:\n'); 
  fprintf(1,'File header discrepancy. Can`t read %s.\n',name);  
  retval=-1;
  return;
end
  
retval=0;
 

