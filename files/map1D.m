function A=map1D(a,b)
%---- map vector a from its original region to the region of b
if(max(a(:))== min(a(:)))
    A=a;
else
    A=min(b(:))*(max(a(:))-min(a(:)))+(max(b(:))-min(b(:)))*(a-min(a(:)));
    A=A./(max(a(:))-min(a(:)));
end
