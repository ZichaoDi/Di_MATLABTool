% FIGUREMAKER - Publication quality figures with matlab
% Version 2.1 July-22-2013
%
% Summary
%
%     Create publication quality graphics, allowing rgb color scaling, pdf
%     output and correct fontsizes.
% 
% Description
%
%     figuremaker helps users generate publication quality graphics from
%     matlab. This code was modified from the exportfig function, available
%     at http://www.mathworks.com/matlabcentral/fileexchange/727-exportfig
%     This function is nice in that the font sizes on the exported figure
%     will agree with the font size of the document the figure is placed
%     into. 
% 
%     Exportfig was modified to allow rgb color in the exported figure.
%     Also, export of pdf file format is implemented with help from Oliver
%     Woodford's export_fig package, available at
%     http://www.mathworks.com/matlabcentral/fileexchange/23629-exportfig
% 
%     The file format of the output is automatically chosen from the
%     filename, for example
% 
%       >> exportfig('filename.pdf') 
% 
%     exports the current figure into pdf format. 
%
% Tags
%
%   exportfig, export, figure, export to pdf, correct font size in matlab
%   figure, export_fig, rgb, pdf
% 
% Included Files
%
%   EXPORTFIG - Export a figure
%   EXAMPLEEXPORTFIG - example call of exportfig
%   EXPORT_FIG package
%   Install - installation instructions
% 
% Dependences
%
%   This package relies on the xpdf package available at
%   http://www.foolabs.com/xpdf/download.html. Please download it and
%   add to your matlab path.
%
% License and Acknowledgements
%
%   This package includes code from Matlab File Exchange ID numbers 727 and
%   23629
%
% Created By
%
%   Todd Karin