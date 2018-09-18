% function Z = admMatMultV1MT(A, B)
%
% see also admMatMultV1
%
% Copyright (C) 2014 Johannes Willkomm
%
function Z = admMatMultV1MT(A, B)

  % A is (m x n) matrix
  % B is (k x n x p) tensor
  
  szA = size(A);
  szB = size(B);

  At = A.';
  
  Z = zeros([szB(1), szA(1), szB(3)]);
  for k=1:szB(3)
    Z(:,:,k) = B(:,:,k) * At;
  end

% $Id: admMatMultV1MTb.m 4474 2014-06-12 08:31:02Z willkomm $
