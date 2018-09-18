function [ ind ] = win2ind( m, n, win )
% Function receives m, n, and win, and return line indexes of window, if it
% were in (0, 0) coordinate of image/matrix of dimension [m, n].
% If need line indexes of window near other pixel ([u, v]), then ind =
% win2ind(m, n, win) + (u,v). 
% PS: need to warry about positive sign in ind, and ind < m*n.
% Indexing is indexed in column-major.

k = floor((win)/2);
s = win-k-1;

u = floor(m/2);
v = floor(n/2);

tmp = zeros(win^2,2);
t = 1;

for j = v-k:v+s
     for i = u-k:u+s      
        tmp(t,:) = [i,j];
        t = t+1;
    end
end

ind = sub2ind([m,n], tmp(:,1)', tmp(:,2)') - sub2ind([m,n], u,v);