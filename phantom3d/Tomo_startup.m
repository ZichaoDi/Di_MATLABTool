disp('X-ray simulation startup file...');
more on;
format compact;
warning off;

mcsDir='/homes/wendydi/Documents/Research';
macDir='/Users/Wendydi/Documents/MATLAB';
if (ispc)
  slash = '\';
else
  slash = '/';
end
addpath([mcsDir,slash,'Di_MATLABtool']);

PWD = pwd;
addpath_recurse(['./result']);
% path(path,'../TN');
% path(path,'../MGOPT');
% addpath_recurse([mcsDir,slash,'APS']);
addpath_recurse([mcsDir,slash,'Di_MATLABtool']);
% addpath_recurse([mcsDir,slash,'multigrid']);
% ADiMat_startup;






