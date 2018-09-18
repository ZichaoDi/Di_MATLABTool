%EXAMPLEEXPORTFIG
%
% Notice how the exported figure's width and fontsize are correct for
% placing in a document.


% Generate an example figure.
clf
x=linspace(0,2*pi,200);
plot(x,sin(x),'r',x,cos(x),'b',x,-cos(x),'g')
legend('Super','Cool','Plot')
xlabel('x axis')
ylabel('y axis')

% Export the figure.
exportfig('exampleExportfig.pdf',...
    'width',3.7,...
    'color','rgb')