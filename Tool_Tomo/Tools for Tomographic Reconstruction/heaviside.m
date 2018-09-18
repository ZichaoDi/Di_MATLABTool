function h = heaviside(f)
% HEAVISIDE delta function
%
% H = HEAVISIDE(F) returns a chebfun H which is -1 when the chebfun F < 0, 
% +1 when F > 0, and .5 when F == 0.
%  
% See also chebfun/dirac

% Copyright 2011 by The University of Oxford and The Chebfun Developers. 
% See http://www.maths.ox.ac.uk/chebfun/ for Chebfun information.

h = .5*(sign(f)+1);
