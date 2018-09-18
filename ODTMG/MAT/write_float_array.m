function retval=write_float_array(fid, name, data, ndims, dims1)
%retval=write_float_array(fid, name, data, ndims, dims)
% Write a float array to a dat file
%
% A Milstein 2/2001

dims=[ndims dims1];

status=add_line_to_header(fid, name, dims);

if (status ~= 0)
  retval=-1;
  return ;
end

status=write_int(fid,0);
if (status ~= 0)
  retval=-1;
  return ;
end

num_elements=prod(dims1);

data1=multitranspose(data);

for i=1:num_elements
  status=write_float(fid, data1(i));
  if (status ~= 0)
    retval=-1;
    return ;
  end

end  

retval=0; 

