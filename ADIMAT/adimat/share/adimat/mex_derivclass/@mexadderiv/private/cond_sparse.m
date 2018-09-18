function g= cond_sparse(g)
% MADDERIV/PRIVATE/COND_SPARSE -- Convert the matrix to a sparse one, if
%   the number of nonzeros in the matrix is less then 1/3 of the matrix
%   size.
%
% Copyright 2003, 2005 Andre Vehreschild, Inst. f. Scientific Computing
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

%if ~ issparse(g)
%  tmp= sparse(g);
%  if nnz(tmp)< numel(g)/3
%    g= tmp;
%  end
%end

