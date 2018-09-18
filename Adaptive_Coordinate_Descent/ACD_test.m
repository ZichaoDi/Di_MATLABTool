
% ---------------------------------------------------------------
% Adaptive Coordinate Descent. To be used under the terms of the BSD license
% Author : Ilya Loshchilov, Marc Schoenauer, Michele Sebag, 2012.  
% e-mail: ilya.loshchilov@gmail.com marc.schoenauer@inria.fr michele.sebag@lri.fr 
% URL:http://www.lri.fr/~ilya
% REFERENCE: Loshchilov, I., Schoenauer, M. , Sebag, M. (2011). Adaptive Coordinate Descent. 
%    N. Krasnogor et al. (eds.)
%    Genetic and Evolutionary Computation Conference (GECCO) 2012,
%    Proceedings, ACM.  http://hal.inria.fr/docs/00/58/75/34/PDF/AdaptiveCoordinateDescent.pdf
% This source code includes the Adaptive Encoding procedure by Nikolaus Hansen, 2008
% ---------------------------------------------------------------


dim = 2; % try 2,40,100,1000
ffunc = 'frosenbrock';
%ffunc = 'fsphere';
%ffunc = 'felli';
%ffunc = 'ftablet';
%ffunc = 'fdiffpow';
%ffunc = 'fschwefel';
%ffunc = 'fcigar';
MAX_EVAL = 1000000*dim;
x_a = -5.0; x_b = 5.0;
ftarget = 1e-10;
fcurrent = 1e+30; 

prof = 0;

howOftenUpdateRotation = 1; % at each iteration -> quadratic time complexity of the algorithm, but need less function evaluations to reach the optimum
if (0) % try to use (1), if the problem dimension>>100
    howOftenUpdateRotation = floor(dim/10); % every N/10 iterations -> linear time complexity of the algorithm, but need more function evaluations to reach the optimum
    % or 
    %howOftenUpdateRotation = dim;    
end;

nevaltotal = 0;
tic
if (prof)
    profile on -history
end;
while (nevaltotal < MAX_EVAL) && (fcurrent > ftarget)
    maxeval_available = MAX_EVAL - nevaltotal;
    [xmean, fcurrent, neval] = ACD(ffunc,dim,x_a,x_b,maxeval_available,ftarget,howOftenUpdateRotation);
    nevaltotal = nevaltotal + neval;
end;
if (prof)
    profile viewer
end;

fintime = toc
functime=0;
fintime = (fintime - functime)  / nevaltotal
disp([num2str(nevaltotal) ' ' num2str(fcurrent)]);



