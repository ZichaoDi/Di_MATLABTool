function w_sim=window_cross_sim(data1, data2, t, w)

%data1, data2 - data
%t - threshold vector of probabilities. An example [0.5 0.9 0.95]
%w - window size
%w_sim - window cross-similarity for each threshold

for i=1:length(t)
    s12=0;
    s1=0;
    s2=0;
    x=data1>quantile(data1(~isnan(data1)),t(i));
    y=data2>quantile(data2(~isnan(data2)),t(i));
    for j=1:floor(length(data1)/w)
        s12=s12+max(x(((j-1)*w+1):(j*w)))*max(y(((j-1)*w+1):(j*w)));
        s1=s1+max(x(((j-1)*w+1):(j*w)));
        s2=s2+max(y(((j-1)*w+1):(j*w)));
    end;
    w_sim(i)=s12/sqrt(s1*s2);
end;