disp('Doga Reconstruction startup file...');
more on;
format compact;
warning off;
if (ispc)
  slash = '\';
else
  slash = '/';
end

PWD = pwd;
path(path,[pwd, slash, 'libs',slash,'spektr_v2_1']);
path(path,[pwd, slash, 'atomProperties']);
path(path,[pwd, slash, 'spectrums']);





