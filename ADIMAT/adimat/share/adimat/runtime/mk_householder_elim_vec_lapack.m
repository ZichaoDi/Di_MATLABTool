% function [Pk u] = mk_householder_elim_vec_lapack(a, n)
%
% input: column vector a
% result: Householder matrix H = I - sigma u u' 
%
% This computes H in LAPACK style [1], and thus also as Matlab and
% Octave do.
%
% [1] Lehoucq, Richard B, "The computation of elementary unitary matrices", 1996
%
% Copyright (C) 2013 Johannes Willkomm
%
function [Pk u] = mk_householder_elim_vec_lapack(a, n)
  tolZ = eps;
  
  assert(iscolumn(a));
  
  Pk = eye(n);

  k = length(a);
  
  if ~(k == 1 && isreal(a)) && sum(abs(a)) ~= 0
    u = a;
    
    na = norm(a);

    if na > tolZ
      sa1 = sign(real(a(1)));
      if sa1 == 0, sa1 = 1; end
       
      nu = sa1 .* na;
      
      u(1) = u(1) + nu;
      u = u ./ (a(1) + nu);
    
      sigma = (a(1) + nu) ./ nu;
      
      Pksub = eye(k) - sigma .* u * u';

      Pk((n-k+1):end,(n-k+1):end) = Pksub;
    
    end
  end

end
% $Id: mk_householder_elim_vec_lapack.m 3963 2013-10-31 09:48:04Z willkomm $
