function uv=generateRandomInConvexHull(xy,M)
%%==========Generate M random points in the converx hull made by xy;
%%==========xy: mx2 points
%%==========M: number of random points needed to be generated
%%==========uv: Mx2 generated points
CH = convhulln(xy);
ntri=size(CH,1);
xycent = mean(xy,1);
nxy = size(xy,1);
ncent = nxy+1;
xy(ncent,:) = xycent;
tri = [CH,repmat(ncent,ntri,1)];
V = zeros(1,ntri);
for ii = 1:ntri
    V(ii) = abs(det(xy(tri(ii,1:2),:) - xycent));
end
V = V/sum(V);
[~,~,simpind] = histcounts(rand(M,1),cumsum([0,V]));
r1 = rand(M,1);
uv = xy(tri(simpind,1),:).*r1 + xy(tri(simpind,2),:).*(1-r1);
r2 = sqrt(rand(M,1));
uv = uv.*r2 + xy(tri(simpind,3),:).*(1-r2);
% figure,
% plot(xy(:,1),xy(:,2),'bo');
% hold on
% plot([xy(tri(:,1),1),xy(tri(:,2),1),xy(tri(:,3),1)]',[xy(tri(:,1),2),xy(tri(:,2),2),xy(tri(:,3),2)]','g-');
% plot(uv(:,1),uv(:,2),'m.');
