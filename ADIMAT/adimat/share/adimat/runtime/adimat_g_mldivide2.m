% function [g_z z] = adimat_g_mldivide2(a, g_b, b)
%
% Compute derivative of z = a \ b, matrix left division. Also return
% the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2013,2014 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [g_z z] = adimat_g_mldivide2(a, g_b, b)

  [m n] = size(a);
  
  z = a \ b;
  g_z = a \ g_b;

% $Id: adimat_g_mldivide2.m 4115 2014-05-06 16:40:17Z willkomm $
