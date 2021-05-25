function out=prox_neg_log_det(X,alpha)
%PROX_NEG_LOG_DET computes the proximal operator of the function -alpha*log(det(X))
%
%  Usage: 
%  out = PROX_NEG_LOG_DET(X,alpha)
%  ===========================================
%  INPUT:
%  X - matrix to be projected
%  alpha - positive scalar
%  ===========================================
%  Assumptions:
%  X is symmetric
%  ===========================================
%  Output:
%  out - proximal operator at X

% This file is part of the FOM package - a collection of first order methods for solving convex optimization problems
% Copyright (C) 2017 Amir and Nili Beck
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

if (nargin < 2)
    error ('usage: prox_neg_log_det(X,alpha)') ;
end

if (alpha < 0)
    error('usage:  prox_neg_log_det(X,alpha) - alpha should be positive')
end

% defalut value for eps : 1e-10
eps = 1e-10 ;
if ((size(X,1) ~= size(X,2)) || (norm( X - X') > eps))
    error('usage:  prox_neg_log_det(X,alpha) - X should be a symmetric matrix') ;
end

X = 0.5 * (X + X');
[V,D] = eig(X) ;
D = (D + sqrt( D.^2 +  diag(ones(size(X,1),1))* 4*alpha)) / 2 ;
out = V * D' * V' ;
end

