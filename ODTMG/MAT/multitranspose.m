function out=multitranspose(in)

dims=size(in);
ndims=max(size(dims));

dims_new=dims(ndims:-1:1);

if (ndims~=2)
  out1=shiftdim(in, ndims-1);
  out=zeros(dims_new);

  for (i=1:dims(ndims))
    in2=reshape(out1(i,:),dims(1:ndims-1));
    out2=multitranspose(in2);
    out(i,:)=out2(:);
  end
else 
  out=in.';
end

return;



