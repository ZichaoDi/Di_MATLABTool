function h = qqplot(x,y,pvec)
%QQPLOT Display an empirical quantile-quantile plot.
%   QQPLOT(X) makes an empirical QQ-plot of the quantiles of the data in
%   the vector X versus the quantiles of a standard Normal distribution.
%
%   QQPLOT(X,PD) makes an empirical QQ-plot of the quantiles of the data in
%   the vector X versus the quantiles of the distribution specified by the
%   ProbabilityDistribution object PD.
%
%   QQPLOT(X,Y) makes an empirical QQ-plot of the quantiles of X versus
%   the quantiles of the data in the vector Y.
%
%   QQPLOT(X,Y,PVEC) allows you to specify the plotted quantiles in the
%   vector PVEC.  The default quantiles are those of the smaller of X and Y.
%
%   H = QVEC(...) returns a vector H containsing handles to the plotted lines. 
%
%   The purpose of the quantile-quantile plot is to determine whether
%   the sample in X is drawn from a specific distribution, or whether the
%   samples in X and Y come from the same distribution.  If the samples
%   do come from the same distribution (same shape), even if one distribution
%   is shifted and re-scaled from the other (different location and scale
%   parameters), the plot will be linear.  A reference line passing through
%   the first and third quartiles is helpful for judging whether the points
%   are linear.
%
%   Use the data cursor to read precise observation values and where 
%   they project to on the reference line.  The variable's observation 
%   numbers are displayed when they have have no missing values and are no 
%   longer than the other variable.
%
%   Example:
%        % Do gas prices follow a normal distribution?
%        load gas
%        qqplot(price1)
%
%        % Do prices at different times have the same distribution?
%        qqplot(price1,price2)
%
%   See also NORMPLOT, PROBPLOT.

%   Copyright 1993-2016 The MathWorks, Inc. 


if nargin == 1
    % plot sample data against standard normal
    if size(x,1)==1
        x = x';
    end
    [y,origindy]  =  sort(x);
    x = plotpos(y);
    origindx = [];
    x = norminv(x);
    xx = x;
    yy = y;
    xlab = getString(message('stats:qqplot:xaxisLabel_StandardNormal'));
    ylab = getString(message('stats:qqplot:yaxisLabel'));
    tlab = getString(message('stats:qqplot:title_StandardNormal'));
elseif nargin>=2 && (isa(y,'ProbDist') || isa(y,'prob.ProbabilityDistribution'))
   % plot sample data against input distribution
   pd = y;
   [y,origindy] = sort(x);
   origindx = [];
   x = plotpos(y);
   x = icdf(pd,x);
   xx = x;
   yy = y; 
   xlab = getString(message('stats:qqplot:xaxisLabel_Distribution', pd.DistributionName));
   ylab = getString(message('stats:qqplot:yaxisLabel'));
   tlab = getString(message('stats:qqplot:title_Distribution'));
else
    % plot one sample against another
    if size(x,1)==1
        x = x';
    end
    if size(y,1)==1
        y = y';
    end
    n = -1;
    xlab = getString(message('stats:qqplot:xaxisLabel_TwoSample'));
    ylab = getString(message('stats:qqplot:yaxisLabel_TwoSample'));
    tlab = '';
    
    if nargin < 3
        % find interpolation points using smaller sample, if none given
        nx = sum(~isnan(x));
        if (length(nx) > 1)
            nx = max(nx);
        end
        ny = sum(~isnan(y));
        if (length(ny) > 1)
            ny = max(ny);
        end
        n = min(nx, ny);
        pvec = 100*((1:n) - 0.5) ./ n;
    end
    if size(x,1)==n
        xx = zeros(size(x));
        origindx = zeros(size(x));
        nancols = find(any(isnan(x),1));
        fullcols = find(all(~isnan(x),1));
        [xx(:,fullcols),origindx(:,fullcols)] = sort(x(:,fullcols));
        xx(:,nancols) = prctile(x(:,nancols),pvec);
        if size(x,2)==1 && size(y,2)~=1
            origindx = repmat(origindx,1,size(y,2));
        end

    else
        xx = prctile(x,pvec);
        origindx = [];
    end
    if size(y,1)==n
        yy = zeros(size(y));
        origindy = zeros(size(y));
        nancols = find(any(isnan(y),1));
        fullcols = find(all(~isnan(y),1));
        [yy(:,fullcols),origindy(:,fullcols)] = sort(y(:,fullcols));
        yy(:,nancols) = prctile(y(:,nancols),pvec);
        if size(y,2)==1 && size(x,2)~=1
            origindy = repmat(origindy,1,size(x,2));
        end
    else
        yy = prctile(y,pvec);
        origindy = [];
    end
end

q1x = prctile(x,25);
q3x = prctile(x,75);
q1y = prctile(y,25);
q3y = prctile(y,75);
qx = [q1x; q3x];
qy = [q1y; q3y];


dx = q3x - q1x;
dy = q3y - q1y;
slope = dy./dx;
centerx = (q1x + q3x)/2;
centery = (q1y + q3y)/2;
maxx = max(x);
minx = min(x);
maxy = centery + slope.*(maxx - centerx);
miny = centery - slope.*(centerx - minx);

mx = [minx; maxx];
my = [miny; maxy];

newplot();
hrefends = line(mx,my,'LineStyle','-.','Marker','none');
hrefmid = line(qx,qy,'LineStyle','-','Marker','none');
hdat = line(xx,yy,'LineStyle','none','Marker','+');
if length(hdat)==1
    set(hdat,'MarkerEdgeColor','b');
    set([hrefends,hrefmid],'Color','r');
end

set(hrefends,'Tag','Reference Ends');
set(hrefmid,'Tag','Reference Mid');
set(hdat,'Tag','Data');

if nargout>0
    h = [hdat;hrefmid;hrefends];
end

for i=1:length(hdat)
    % Set custom data cursor on data
    hB = hggetbehavior(hdat(i),'datacursor');
    set(hB,'UpdateFcn',@qqplotDatatipCallback);
    % Disable datacursor on reference lines
    hB = hggetbehavior(hrefends(i),'datacursor');
    set(hB,'Enable',false);
    hB = hggetbehavior(hrefmid(i),'datacursor');
    set(hB,'Enable',false);
    if length(hdat)>1
        setappdata(hdat(i),'group',i);
    end
    if ~isempty(origindx)
        setappdata(hdat(i),'origindx',origindx(:,i));
    end
    if ~isempty(origindy)
        setappdata(hdat(i),'origindy',origindy(:,i));
    end
end


xlabel(xlab);
ylabel(ylab);
title (tlab);

%===================== helper function ====================
function pp = plotpos(sx)
%PLOTPOS Compute plotting positions for a probability plot
%   PP = PLOTPOS(SX) compute the plotting positions for a probability
%   plot of the columns of SX (or for SX itself if it is a vector).
%   SX must be sorted before being passed into PLOTPOS.  The ith
%   value of SX has plotting position (i-0.5)/n, where n is
%   the number of rows of SX.  NaN values are removed before
%   computing the plotting positions.

[n, m] = size(sx);
if n == 1
   sx = sx';
   n = m;
   m = 1;
end

nvec = sum(~isnan(sx));
pp = repmat((1:n)', 1, m);
pp = (pp-.5) ./ repmat(nvec, n, 1);
pp(isnan(sx)) = NaN;

%===================== callback ====================
function datatipTxt = qqplotDatatipCallback(obj,evt)

target = get(evt,'Target');
pos = get(evt,'Position');
ind = get(evt,'DataIndex');

group = getappdata(target,'group');
origindx = getappdata(target,'origindx');
origindy = getappdata(target,'origindy');


datatipTxt = {
    sprintf('%s', getString(message('stats:qqplot:dataTip_x',num2str(pos(1))))), ...
    sprintf('%s', getString(message('stats:qqplot:dataTip_y',num2str(pos(2)))))  ...
};

if ~isempty(group) || ~isempty(origindx) || ~isempty(origindy)
    datatipTxt{end+1} = '';
end

if ~isempty(group)
    datatipTxt{end+1} = getString(message('stats:qqplot:dataTip_Group',num2str(group)));
end
if ~isempty(origindx)
    dat = origindx(ind);
    if dat~=0
        datatipTxt{end+1} = getString(message('stats:qqplot:dataTip_XObservation',num2str(dat)));
    end
end
if ~isempty(origindy)
    dat = origindy(ind);
    if dat~=0
        datatipTxt{end+1} = getString(message('stats:qqplot:dataTip_YObservation',num2str(dat)));
    end
end

