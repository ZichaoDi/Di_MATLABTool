function data=loadmu(foo,var)

foo1=[foo '.dat'];
fid=datOpen(foo1,'r');
%dims=[2 129 33 17];
dims=[2 17 17 17];
[status, data]=read_float_array(fid, var, length(dims), dims);
fclose(fid);

return;
