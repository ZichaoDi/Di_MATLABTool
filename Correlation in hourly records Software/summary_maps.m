function [d_lag, max_sim, w_sim]=summary_maps(x, long, lat, z, t, maxlag, w)

%x - data. Rows - variables (record sites), columns - observations
%long, lat - coordinates of record sites
%z - indice of selected site
%t - threshold vector of probabilities. An example [0.5 0.9 0.95]
%maxlag - cross-similarity is calculated for lags from -maxlag to maxlag
%w - window size
%d_lad - dominat lag for each threshold
%max_sim - maximum similarity for each threshold
%w_sim - window cross-similarity for each threshold

[n,m]=size(x);
n_t=length(t);

for i=1:n
    [k, d_lag(i,:), max_sim(i,:)]=cos_cross_sim(x(z,:), x(i,:), t, maxlag, 0);
    w_sim(i,:)=window_cross_sim(x(z,:), x(i,:), t, w);
end;

for j=1:n_t
    subplot(n_t,3,(j-1)*3+1);
    parameter_map(d_lag(:,j), long, lat, ['dominant lag, p=' num2str(t(j))], -maxlag, maxlag);
    subplot(n_t,3,(j-1)*3+2);
    parameter_map(max_sim(:,j), long, lat, ['max-sim., p=' num2str(t(j))], 0, 1);
    subplot(n_t,3,(j-1)*3+3);
    parameter_map(w_sim(:,j), long, lat, ['window cross-sim., p=' num2str(t(j))], 0, 1);
end;