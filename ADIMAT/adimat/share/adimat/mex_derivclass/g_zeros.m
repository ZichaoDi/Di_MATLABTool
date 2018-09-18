function gz=g_zeros(varargin)
%G_ZEROS Create a gradient object containing all zeros.
%   G_ZEROS(N) creates a gradient object with number of directional derivatives
%              many N-by-N matrices of zeros.
%   G_ZEROS(M,N) or G_ZEROS([M,N]) creates a gradient with n.o.d.d.
%               many M-by-N matrices of zeros.
%   G_ZEROS(M,N,P,...) or G_ZEROS([M N P ...]) creates a gradient with n.o.d.d.
%               many M-by-N-by-P-by-... arrays of zeros.
%
% Copyright 2003, 2004 Andre Vehreschild, Institute for Scientific Computing
%           RWTH Aachen University.
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

switch nargin
  case 0, gz= mexadderiv([], 0, 'zeros');
  case 1, gz= mexadderiv([], varargin{1}, 'zeros');
  otherwise gz= mexadderiv([], [varargin{:}], 'zeros');
end

