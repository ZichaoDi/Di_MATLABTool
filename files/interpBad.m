function D=interpBad(D,mode)
[m,n]=size(D);
if(strcmp(mode,'inf'))
[n1,n2]=find(isinf(D));
ind=find(isinf(D));
elseif(strcmp(mode,'nan'))
[n1,n2]=find(isnan(D));
ind=find(isnan(D));
end
DD=D; DD(ind)=0;
D_temp=zeros(m+2,n+2);
D_temp(2:end-1,2:end-1)=DD;
for ni=1:length(n1)
        D(n1(ni),n2(ni))=(D_temp(n1(ni)+1+1,n2(ni)+1)+D_temp(n1(ni)+1-1,n2(ni)+1)+D_temp(n1(ni)+1,n2(ni)+1-1)+D_temp(n1(ni)+1,n2(ni)+1+1))/4;
end


