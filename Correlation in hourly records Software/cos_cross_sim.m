function [k, d_lag, max_sim]=cos_cross_sim(data1, data2, t, maxlag, picture)

%data1, data2 - data
%t - threshold vector of probabilities. An example [0.5 0.9 0.95]
%maxlag - cross-similarity is calculated for lags from -maxlag to maxlag
%picture - if 1 cross-similarity and dominant lag are plotted
%k - cross-similarity vectors for each threshold
%d_lad - dominat lag for each threshold
%max_sim - maximum similarity for each threshold

for i=1:length(t)
    x=data1>quantile(data1(~isnan(data1)),t(i));
    y=data2>quantile(data2(~isnan(data2)),t(i));
    for j=1:maxlag 
        k(i,j)=sum(x((maxlag+2-j):end).*y(1:(end-maxlag+j-1)));
    end;
    k(i,maxlag+1)=sum(x.*y);
    for j=1:maxlag 
        k(i,maxlag+1+j)=sum(y((1+j):end).*x(1:(end-j)));
    end;
    k(i,:)=k(i,:)/sqrt(sum(x)*sum(y));
    d_all=((k(i,:)==max(k(i,:))).*(-maxlag:(maxlag)));
    if(sum(d_all)==0)
        d_lag(i)=0;
    else
        d_lag(i)=ceil(mean(d_all(d_all~=0)));
    end;
    max_sim(i)=max(k(i,:));
end;

if picture
    plot((ones(length(t),1)*(-maxlag:maxlag))',k');
    hold on;
    plot(d_lag, max_sim,'*k');
    xlabel('lag');
    ylabel('cosine similarity');
    legend(num2str(t'),'Location','NorthEast');
    title('Cosine cross-similarity')
end;