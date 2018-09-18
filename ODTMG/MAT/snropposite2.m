function snr3 = snropposite(snr);

src=[1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 3 3 3 3 3 3 3 3  ...
     4 4 4 4 4 4 4 4 5 5 5 5 5 5 5 5 6 6 6 6 6 6 6 6];
  
det=[1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 ...
     3 3 3 3 3 3 3 3 3 4 4 4 4 4 4 4 4 4 ...
     5 5 5 5 5 5 5 5 5 6 6 6 6 6 6 6 6 6 ];
n=1; p=1;
for k=1:48,
for m=1:54,
  if ( mod(src(k),2)==1 & det(m)==src(k)+1) ...
     | (mod(src(k),2)==0 & det(m)==src(k)-1) ,
    snr3(n) = snr(p);
    n = n+1;
  end,
 
  if (src(k)~=det(m))
    p=p+1;
  end,
end,
end,
