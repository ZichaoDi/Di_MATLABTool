% function [dpartial y] = dpartial_acos(x)
%
% Compute partial derivative diagonal of y = acos(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_acos(x)
  dpartial = -1 ./ sqrt(1 - x.^2);
  if nargout > 1
    y = acos(x);
  end

% $Id: dpartial_acos.m 3246 2012-03-23 14:38:47Z willkomm $
