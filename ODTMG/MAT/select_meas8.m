function [meas2, pair] = select_meas8(meas);

src=[1 1 1 1 1 1 1 1 ];
  
det=[1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 ...
     3 3 3 3 3 3 3 3 3 4 4 4 4 4 4 4 4 4 ...
     5 5 5 5 5 5 5 5 5 6 6 6 6 6 6 6 6 6 ];

s=1; p=1;
for k=1:8,
for m=1:54,
  if src(k)~=det(m),
    meas2(s,:)=meas(p,:); 
    pair(s,1)=src(k); pair(s,2)=det(m);
    s = s+1;
  end,

  p=p+1;
end,
end,
