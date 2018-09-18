function v_sum=sum_interval(v,nx,ny)
if(ndims(v)<=2)
    [m,n]=size(v);
    ind=(1:n)';
    v_sum=sparse(ceil((1:m)'/nx),(1:m)',1)*v*sparse(ceil(ind/ny),ind,1)';;
else
    [m,n,r] = size(v);
    out = permute(reshape(reshape(permute(v,[1 3 2]),[],n)*sparse(ceil((1:n)'/ny),(1:n)',1)',m,r,[]),[1 3 2]);
    [m1,n1,r1]=size(out);
    v_sum=reshape(sparse(ceil((1:m)'/nx),(1:m)',1)*reshape(out,m,[]),[],n1,r1);
end
    

