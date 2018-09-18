function retval=add_line_to_header(fid, name, dims)

HEADERSIZE=1024;
frewind(fid);

testch='i';

for i=1:HEADERSIZE
  [testch,status]=fscanf(fid, '%c',1);
  if (testch=='_')
    break;
  end
end

if (testch~='_')
  fprintf(1, 'add_line_to_header:\n');
  fprintf(1, 'Header is full. Cannot add %s\n',name);
  retval=-1;
  return;
end

fseek(fid, -1, 'cof');
fprintf(fid, '> %s %d', name, dims(1));

for i=1:dims(1)
  fprintf(fid, ' %d', dims(1+i));
end
fprintf(fid, '\n');

fseek(fid, 0, 'eof');
retval=0;



