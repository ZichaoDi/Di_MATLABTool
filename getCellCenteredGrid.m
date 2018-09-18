%==============================================================================
% (c) Jan Modersitzki 2011/01/04, see FAIR.2011 and FAIRcopyright.m.
% http://www.mic.uni-luebeck.de/people/jan-modersitzki.html
%
% function x = getCellCenteredGrid(omega,m)
%
% creates a cell-center discretization of [0,omega(1)] x ... x[0,omega(end)] of m points
%
%          x1                     x2
% +-----+-----+-----+    +-----+-----+-----+
% |     |     |     |    |     |     |     |
% |  x  |  x  |  x  |    |  x  |  x  |  x  |
% |     |     |     |    |     |     |     |
% +-----+-----+-----+    +-----+-----+-----+
% |     |     |     |    |     |     |     |
% |  x  |  x  |  x  |    |  x  |  x  |  x  |
% |     |     |     |    |     |     |     |
% +-----+-----+-----+    +-----+-----+-----+
%                   
% Input:
%   omega    describing the domain
%   m        number of discretization points
%
% Output:
%   x        collection of grid points, x is length(omega)*prod(m)-by-1
% See also getStaggeredGrid, getNodalGrid, E3_getCellCenteredGrid

%==============================================================================
% changes 
% 2008-12-04: modified code to fit new omega definition 
% 2011-01-03: change name to getCellCenteredGrid (more consistent)
%==============================================================================

function x = getCellCenteredGrid(omega,m)

if nargin == 0,  % help and minimal example
  help(mfilename); 
  omega = [0 2 0 1]; m = [6,3];
  xN = getNodalGrid(omega,m);
  xC = reshape(getCellCenteredGrid(omega,m),[],2)';
  figure(1); clf; 
  plotGrid(xN,omega,m); hold on; title(mfilename); 
  plot(xC(1,:),xC(2,:),'rx'); axis image
  return; 
end;

x  = []; x1 = []; x2 = []; x3 = [];
h  = (omega(2:2:end)-omega(1:2:end))./m;                 % voxel dimensions
xi = @(i) (omega(2*i-1)+h(i)/2:h(i):omega(2*i)-h(i)/2)'; % cell centers
switch length(omega)/2;,
  case 1, x1 = xi(1);
  case 2, [x1,x2] = ndgrid(xi(1),xi(2));
  case 3, [x1,x2,x3] = ndgrid(xi(1),xi(2),xi(3));
end;
x = [reshape(x1,[],1);reshape(x2,[],1);reshape(x3,[],1)];

%{ 
  =======================================================================================
  FAIR: Flexible Algorithms for Image Registration, Version 2011
  Copyright (c): Jan Modersitzki
  Maria-Goeppert-Str. 1a, D-23562 Luebeck, Germany
  Email: jan.modersitzki@mic.uni-luebeck.de
  URL:   http://www.mic.uni-luebeck.de/people/jan-modersitzki.html
  =======================================================================================
  No part of this code may be reproduced, stored in a retrieval system,
  translated, transcribed, transmitted, or distributed in any form
  or by any means, means, manual, electric, electronic, electro-magnetic,
  mechanical, chemical, optical, photocopying, recording, or otherwise,
  without the prior explicit written permission of the authors or their
  designated proxies. In no event shall the above copyright notice be
  removed or altered in any way.

  This code is provided "as is", without any warranty of any kind, either
  expressed or implied, including but not limited to, any implied warranty
  of merchantibility or fitness for any purpose. In no event will any party
  who distributed the code be liable for damages or for any claim(s) by
  any other party, including but not limited to, any lost profits, lost
  monies, lost data or data rendered inaccurate, losses sustained by
  third parties, or any other special, incidental or consequential damages
  arrising out of the use or inability to use the program, even if the
  possibility of such damages has been advised against. The entire risk
  as to the quality, the performace, and the fitness of the program for any
  particular purpose lies with the party using the code.
  =======================================================================================
  Any use of this code constitutes acceptance of the terms of the above statements
  =======================================================================================
%}
