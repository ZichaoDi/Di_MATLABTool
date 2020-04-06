% Title: Poisson 9-Stencil
% Summary:
% Equivalent function to gallery('poisson'), but for the compact
% 9-Point-Stencil.
% File name: poisson9.m
% Description: This function creates a sparse matrix for the
% discretization of the laplace operator with the
% 9-Point-Stencil. Similar to the gallery('poisson') function of
% Matlab, the matrix is computed using the Kronecker tensor
% product.
%
% Date: November 2001
% Author: Florian Schmid
% Version: 1.0
%

function A = poisson9(n)
  e = ones(n,1);
  S = spdiags([e 10*e e], [-1 0 1], n, n);
  I = spdiags([-1/2*e e -1/2*e], [-1 0 1], n, n);
  A = kron(I,S)+kron(S,I);
