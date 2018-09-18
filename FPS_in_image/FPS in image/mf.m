function mf( varargin )
% M(main) F(function)
% Receives 2 paths of images, calculates FPs in them, and match them. Aslo
% shows such results: 1. show where FPs of 1-st image were finded 
% 2. show where FPs of 2-nd image were finded 3. show matched FP's.

% It's possible to show FPs in images with patches/rectangles with length of edges
% proportional to charact. scale, and direction of their rotation as main
% orientation of given FP /which localized in center of rectangle/. - 
% this option takes a lot of time /if there are a lot of FPs/, so by
% default will be showed only places of FP's, but it can be changed in
% immatch.m

% Example of run: mf( 'D:\My pics\img1.jpg', 'D:\My pics\img2.jpg' )

% Also it's possible to enter images, and not their paths /if they were
% already uploaded to matlab/.

immatch( varargin{1}, varargin{2} )