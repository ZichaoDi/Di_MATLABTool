function [final_cum_comp, final_cost, k]=costparse(dirname)

[filename, errmsg] = sprintf('./%s/RESULT', dirname);

fid=fopen(filename,'r'); 
temp=fscanf(fid,'%f'); fclose(fid); 
numlines = size(temp,1)/5;
for i=1: numlines, 
  iter(i) =temp(5*(i-1)+2); 
  resol(i)=temp(5*(i-1)+3); 
  cost(i) =temp(5*(i-1)+4); 
  alpha(i)=temp(5*(i-1)+5); 
end


for i=1:numlines,
  cum_comp(i) = 0;
  final_cum_comp(i)=0;
  final_cost(i)=0;
end
for i=2: numlines, 
  if resol(i)==resol(i-1) & iter(i)==iter(i-1),
    cum_comp(i) = cum_comp(i-1) + 0.125^resol(i); 
  elseif resol(i)==resol(i-1) & iter(i)~=iter(i-1),  
    cum_comp(i) = cum_comp(i-1);      
  elseif resol(i)==resol(i-1)+1,
    cum_comp(i) = cum_comp(i-1) + 0.82 * 0.125^resol(i-1); 
  elseif resol(i)==resol(i-1)-1,
    cum_comp(i) = cum_comp(i-1);   
  end
end


final_cum_comp(1)=0;
k=0;
for i=1:numlines-1,
  if resol(i)==0 & iter(i+1)~=iter(i)+1,
    k=k+1; 
    final_cost(k)=cost(i);
    final_cum_comp(k)=cum_comp(i);
  end  
end

return

