%
% function adj = a_repmat(adj, varargin)
%   compute adjoint of repmat(val, varargin{:})
%
% see also a_zeros, a_mean
%
% This file is part of the ADiMat runtime environment
%
function r = a_repmat(adj, val, varargin)
  if nargin < 4
    dims = varargin{1};
  else
    dims = [ varargin{1} varargin{2} ];
  end
  if isstruct(val) 
    % FIXME: this only works when first arg to repmat was a scalar struct
    r = adj(1);
    for i=2:numel(adj)
      r = adimat_sumstruct(r, adj(i));
    end
  else
    r = repmat(eye(size(val, 1)), 1, dims(1)) ...
        * adj ...
        * repmat(eye(size(val, 2)), dims(2), 1);
  end

% $Id: a_repmat.m 2207 2010-09-02 15:02:42Z willkomm $
