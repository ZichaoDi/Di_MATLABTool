function initialize_header(fid)
%initialize_header(fid): initialize header of dat file

HEADERSIZE=1024;

for i=0:(HEADERSIZE-1)
  fprintf(fid, '%c', '_');
end 

