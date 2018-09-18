function PlotFP( img, HrLPoints )
% Function plots finded FPs. For each FP taken rectangle ( FP - it's center ) with edge length 
% proportional to it's characteristic scale, and rotated in direction of
% MO.
%-------------------- Parameters -------------------%
LineWidth = 0.5;
EdgeColor = [ 200 20 20 ]/255;
FaceColor = 'none';

%------------------ Pre-processing -----------------%
% number of similar pairs
N = size( HrLPoints, 1 );
% [ m, n, tmp ] = size( img );
rowY1 = HrLPoints( :, 1 ); rowY1 = rowY1';
clmnX1 = HrLPoints( :, 2 ); clmnX1 = clmnX1';

EdgeLength1 = 8*HrLPoints( :, 3 ) + 1; EdgeLength1 = EdgeLength1';
 
%----------- Defining angles of rotation  ----------%
% degrees!, not radians
Angles1 = HrLPoints( :, 6 );

%------- Coordinates of squares near (0,0) ---------%
% now let's find X, Y coordinates of all squares.
% arrange them in such manner: column X(:, i) and column Y(:, i)
% are X, Y coordinates of patch/square near (0,0) with edge length - EdgeLength(i) 
% square coordinates are symmetric toward (0,0), so enough find distance
% from (0,0) to left edge and to right.
% if DistLeft = v, DistRight = s -> s+v+1 = edge, and coordinates are
% [-v,-v],[s,-v],[s,s],[-v,s] ( first oordinate is x, in image it's column..second y - row )
V1 = floor(EdgeLength1/2);
S1 = EdgeLength1 - V1 - 1;

% now let's arrange them as mentiod before
% arranged X, Y coordinates of patches on first image
X1 = [ -V1; S1; S1; -V1 ]; Y1 = [ -V1; -V1; S1; S1 ];

%----------- Difining coordinates shifts -----------%
% we arranged coordinates of squares near (0,0), but we have to plot
% patches near some points, which coordinates are given by Data, so need to
% shift all coordinates ( of patches near (0,0) ) to some according to it
% coordinate. ( coordinates of first column X and Y need to be shifted to first x, y coordiantes in according Data, and so on )
ShiftClmnX1 = repmat( clmnX1, 4, 1 );
ShiftRowY1 = repmat( rowY1, 4, 1 );

%---------- Difining centers of rotation  ----------%
% by center, I mean origin
Origin4Rotation = [ clmnX1(:), rowY1(:), repmat( 0, N, 1 ) ];

%---- Defining coordinates of main orientation -----%
MainOrientX1 = [ repmat( 0, 1, N ); S1 ];
MainOrientY1 = [ repmat( 0, 2, N ) ];

% shifts are the same, but need to warry to match dimensions
ShiftMainOrientX1 = ShiftClmnX1( 1:2, : );
ShiftMainOrientY1 = ShiftRowY1( 1:2, : );

%---------------- Finaly ploting results ------------------%
% show images
% figure;
imshow(img), hold on, plot( HrLPoints( :, 2 ), HrLPoints( :, 1 ), 'g.' )
ax = gca;
axes(ax)
title('FP in image:')
  
% plot all patches with lines
h = waitbar(0, 'Ploting/rotating patches:');
for i = 1:N
    hPatch1 = patch( X1( :, i )+ ShiftClmnX1( :, i ), Y1( :, i ) + ShiftRowY1(:, i), EdgeColor, 'EdgeColor', EdgeColor, 'FaceColor', FaceColor, 'LineWidth', LineWidth );
    hOrient1 = line( MainOrientX1( :, i ) + ShiftMainOrientX1( :, i ), MainOrientY1( :, i ) + ShiftMainOrientY1( :, i ), 'Color', EdgeColor, 'LineWidth', LineWidth);
   
    rotate( hPatch1, [ 0 0 1 ], Angles1(i), Origin4Rotation( i,: ) );
    rotate( hOrient1, [ 0 0 1 ], Angles1(i), Origin4Rotation( i,: ) );
    waitbar( i/N )
end
close(h)
