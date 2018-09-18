function parameter_map(data, lons, lats, t, cmin, cmax);

%data - data to be plotted
%lons - longitude coordinates
%lats - latitude coordinates
%cmin, cmax - scale

m_proj('Stereographic', 'lon', 13,'lat',51.1,'rad', [-5., 28], 'rec','on','rot',-3); % Should be adjusted according to own data set 
[X,Y]=m_ll2xy(lons,lats,'clip','patch');
set(gca,'XTickLabelMode','manual', 'XTick', [],'YTickLabelMode','manual', 'YTick', [] )
hold on
scatter(X, Y, ones(length(X),1)*50, data','filled');
m_coast('linewidth',1,'color','k');
set(findobj('tag','m_grid_color'),'facecolor','none');
set(gca,'DataAspectRatioMode','auto');
colorbar;
title(t); 
if max(max(data))>0
    AXIS([ min(min(X)) max(max(X)) min(min(Y)) max(max(Y)) min(min(data)) max(max(data)) cmin cmax ]);
end;
AXIS([ min(min(X)) max(max(X)) min(min(Y)) max(max(Y))]);