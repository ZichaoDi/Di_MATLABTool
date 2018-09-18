function fid=datOpen(filename, permission)
% Open a DAT file

[fid1, message]=fopen(filename, permission, 'ieee-le.l64');

if (permission(1)=='w')
  initialize_header(fid1);
end

fid=fid1;
