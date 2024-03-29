% function [partial r] = partial_roots(c)
%   Compute partial derivative of r = roots(c). Also return the
%   function result r.
%
% Computation according to ansatz from Martin Bücker using implicit
% function theorom.
%
% see also g_roots, a_roots
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2012 H.Martin Bücker, Institute for Scientific Computing
% Copyright 2011-2012 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [partial x] = partial_roots(c)
  deg = length(c) - 1;
  x = roots(c);
  dc = polyder(c);
  evDer = polyval(dc, x);
  rhs = [x .^ deg vander(x)];
  partial = rhs ./ repmat(-evDer, 1, deg+1);

% $Id: partial_roots.m 3176 2012-03-06 21:05:39Z willkomm $
% Local Variables:
% coding: utf-8
% End:
