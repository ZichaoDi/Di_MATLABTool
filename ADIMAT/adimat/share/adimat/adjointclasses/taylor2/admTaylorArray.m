% function T = admTaylorArray(varargin)
%   concatenate a number of derivative objects to a Jacobian matrix
%
% This file is part of the ADiMat runtime environment, and belongs
% to the tseries derivative class.
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function TA = admTaylorArray(varargin)
  nCompInResult = sum(cellfun('prodofsize', varargin));
  maxOrder = get(varargin{1}, 'maxorder');
  if maxOrder > 0
    ndd = admGetNDD(varargin{1}{2});
  else
    ndd = 1;
  end
  TA = zeros(nCompInResult, ndd, maxOrder);
  resStart = 0;
  resEnd = 0;
  for argi=1:nargin
    arg = varargin{argi};
    resStart = resEnd + 1;
    resEnd = resEnd + prod(size(arg));
    for o=1:maxOrder
      derivs = admJacFor(arg{o+1});
      TA(resStart:resEnd, :, o) = derivs;
    end
  end

% $Id: admTaylorArray.m 4260 2014-05-19 18:45:15Z willkomm $
