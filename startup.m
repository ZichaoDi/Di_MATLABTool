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
if(ismac)
addpath([macDir,slash,'Di_MATLABtool']);
else
addpath([mcsDir,slash,'Di_MATLABtool']);
end

PWD = pwd;
if(ismac)
addpath_recurse([macDir,slash,'Di_MATLABtool']);
else
addpath_recurse([mcsDir,slash,'Di_MATLABtool']);
end

