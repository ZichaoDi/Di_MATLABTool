function [d_lag, max_sim, w_sim]=summary_with_distance(x, long, lat, t, maxlag, w)

%x - data. Rows - variables (record sites), columns - observations
%long, lat - coordinates of record sites
%t - threshold vector of probabilities. An example [0.5 0.9 0.95]
%maxlag - cross-similarity is calculated for lags from -maxlag to maxlag
%w - window size
%d_lad - dominat lag for each threshold
%max_sim - maximum similarity for each threshold
%w_sim - window cross-similarity for each threshold

[n,m]=size(x);
n_t=length(t);

for i=1:n
    for j=1:n
        [k, d_lag(i,j,:), max_sim(i,j,:)]=cos_cross_sim(x(j,:), x(i,:), t, maxlag, 0);
        w_sim(i,j,:)=window_cross_sim(x(j,:), x(i,:), t, w);
    end;
end;

distance=[];
for i=1:n
    for j=1:n
        distance=[distance m_lldist([long(i) long(j)] , [lat(i) lat(j)])];
    end;
end;

for z=1:n_t
    subplot(n_t,3,(z-1)*3+1);
    plot(distance,abs(reshape(d_lag(:,:,z),n*n,1)),'*k');
    title(['dominant lag, p=' num2str(t(z))]);
    xlabel('km');
    ylabel('lag');
    subplot(n_t,3,(z-1)*3+2);
    plot(distance,reshape(squeeze(max_sim(:,:,z)),n*n,1),'*k');
    title(['max-sim., p=' num2str(t(z))]);
    xlabel('km');
    ylabel('similarity');
    subplot(n_t,3,(z-1)*3+3);
    plot(distance,reshape(squeeze(w_sim(:,:,z)),n*n,1),'*k');
    title(['window cross-sim., p=' num2str(t(z))]);
    xlabel('km');
    ylabel('similarity');
end;