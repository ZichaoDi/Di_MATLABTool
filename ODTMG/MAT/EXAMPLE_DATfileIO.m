%
% This M-file shows an example of how to read/write dat file. 
%

% Make a two-dimensional array of size 3x4.
% Its each (i,j)-th element will have the value of i+j.

arr = zeros(3,5);
for i=1:3, 
  for j=1:5;
    arr(i,j) = i+j;
   end,
end

% Save 'arr' in the file "test.dat".
% It will be saved with the array name "blah" in the file.
% The format of write_float_array() is 
%   write_float_array(file_id, array_name_to_be_saved_as, array_name, length_of_dimensions, dimensions)

fid=datOpen('test.dat','w+');
write_float_array(fid, 'blah', arr, 2, [3 5]);
fclose(fid);

% Read an array from the "test.dat" file.
% Before doing it, you must find correct array name and dimensions.
% For example, if you open the "test.dat" file,
% it should begin with 
%    > blah 2 3 5 
% "blah" is the array name, "2" is the length of dimensions,
% and the rest numbers ("3 5" in this case) are dimensions.
% The format of read_float_array() is 
%  [status, data_array] = read_float_array(file_id, array_name_to_be_saved_as, length_of_dimensions, dimensions).
% The data to be read will be saved in "data_array".

fid=datOpen('test.dat','r');
[status, data_array]=read_float_array(fid, 'blah', 2, [3 5]);
fclose(fid);


% Check what you got from the file

data_array
