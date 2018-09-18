function PlotMatches( img1, Data1, img2, Data2, TypeOfEdge, TypeOfFP )
% Function receives images ( img1, img2 ) and Data's.
% Data1( i, : ) - data of i-th FP in image 1 ( the same considertion applied to Data2 ).
% Data1( i, 1 ), Data1( i, 2 ) - row and column respectively of FP. Data1( i, 3 ) -
% information about length of square region ( can be of 2 Types, read below ).
% Data1( i, 4 ) - angle of square rotation ( main orientation ). Center of rotation is 
% [ Data1( i, 2 ), Data1( i, 1 ), 0 ] ( if we look at X, Y, Z coord. ). 
% TypeOfEdge - type of taking squares' length. If TypeOfEdge = 'sigma' -> square of size
% (12*Data1( i, 3 ) +1)x12*Data1( i, 3 ) +1). If TypeOfEdge = 'edge' -> ...
% Data1( i, 3 )xData1( i, 3 ).
% TypeOfFP - 'HL'/'Aff'. If 'HL' ( Harris-Laplace ) - will be ploted
% matched FP with according rectangles. 'Aff' - will be ploted corresp. FP,
% connected by line, without rectangles.
% Assumption - 1. angles are given in degrees.

%-------------------- Parameters -------------------%
LineWidth = 0.5;
EdgeColor = [ 200 20 20 ]/255;
LineColor = [ 30 100 100 ]/255;
FaceColor = 'none';
Linestyle = '-';

%------------------ Pre-processing -----------------%
% number of similar pairs
N = size( Data1, 1 );
[ m1, n1, tmp ] = size( img1 );
[ m2, n2, tmp ] = size( img2 );
rowY1 = Data1( :, 1 ); rowY1 = rowY1';
clmnX1 = Data1( :, 2 ); clmnX1 = clmnX1';
rowY2 = Data2( :, 1 ); rowY2 = rowY2';
clmnX2 = Data2( :, 2 ); clmnX2 = clmnX2';
% shifting column coordinates of second image, beause
% second image will be placed after first one
clmnX2 = clmnX2 + n1; 

%------------- Padding image if needed -------------%
if m1 > m2
    img2 = padarray( img2, [ m1 - m2 0 ], 'post' );
elseif m1 < m2
    img1 = padarray( img1, [ m2 - m1 0 ], 'post' );
end

if strcmp( TypeOfFP, 'HL' )

%------- Defining edge lengths of all squares  -----%
switch TypeOfEdge
    case 'sigma'
        EdgeLength1 = 8*Data1( :, 3 ) + 1; EdgeLength1 = EdgeLength1';
        EdgeLength2 = 8*Data2( :, 3 ) + 1; EdgeLength2 = EdgeLength2';
    case 'edge'
        EdgeLength1 = Data1( :, 3 ); EdgeLength1 = EdgeLength1';
        EdgeLength2 = Data2( :, 3 ); EdgeLength2 = EdgeLength2';
end

%----------- Defining angles of rotation  ----------%
% degrees!, not radians
Angles1 = Data1( :, 4 );
Angles2 = Data2( :, 4 );

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
V2 = floor(EdgeLength2/2);
S2 = EdgeLength2 - V2 - 1;
% now let's arrange them as mentiod before
% arranged X, Y coordinates of patches on first image
X1 = [ -V1; S1; S1; -V1 ]; Y1 = [ -V1; -V1; S1; S1 ];
X2 = [ -V2; S2; S2; -V2 ]; Y2 = [ -V2; -V2; S2; S2 ];

%----------- Difining coordinates shifts -----------%
% we arranged coordinates of squares near (0,0), but we have to plot
% patches near some points, which coordinates are given by Data, so need to
% shift all coordinates ( of patches near (0,0) ) to some according to it
% coordinate. ( coordinates of first column X and Y need to be shifted to first x, y coordiantes in according Data, and so on )
ShiftClmnX1 = repmat( clmnX1, 4, 1 );
ShiftRowY1 = repmat( rowY1, 4, 1 );
ShiftClmnX2 = repmat( clmnX2, 4, 1 );
ShiftRowY2 = repmat( rowY2, 4, 1 );

%---------- Difining centers of rotation  ----------%
% by center, I mean origin
Origin4Rotation1 = [ clmnX1(:), rowY1(:), repmat( 0, N, 1 ) ];
Origin4Rotation2 = [ clmnX2(:), rowY2(:), repmat( 0, N, 1 ) ];

%---- Defining coordinates of main orientation -----%
MainOrientX1 = [ repmat( 0, 1, N ); S1 ];
MainOrientY1 = [ repmat( 0, 2, N ) ];
MainOrientX2 = [ repmat( 0, 1, N ); S2 ];
MainOrientY2 = MainOrientY1;
% shifts are the same, but need to warry to match dimensions
ShiftMainOrientX1 = ShiftClmnX1( 1:2, : );
ShiftMainOrientY1 = ShiftRowY1( 1:2, : );
ShiftMainOrientX2 = ShiftClmnX2( 1:2, : );
ShiftMainOrientY2 = ShiftRowY2( 1:2, : );
end

%- Difining coordinates of line between according squares -%
LineCoordX = [ clmnX1; clmnX2 ];
LineCoordY = [ rowY1; rowY2 ];

%---------------- Finaly ploting results ------------------%
% show images
% figure;
hIm = montage( [ img1, img2 ] );
ax = gca;
axes(ax)
title('Corresponding FP between image1 and image2')

%--
hold on, plot( clmnX1, rowY1, 'g.' ), plot( clmnX2, rowY2, 'g.' );
%--

switch TypeOfFP
    case 'HL' 
    
% plot all patches with lines
h = waitbar(0, 'Ploting/rotating patches:');
for i = 1:N
    hPatch1 = patch( X1( :, i )+ ShiftClmnX1( :, i ), Y1( :, i ) + ShiftRowY1(:, i), EdgeColor, 'EdgeColor', EdgeColor, 'FaceColor', FaceColor, 'LineWidth', LineWidth );
    hPatch2 = patch( X2( :, i )+ ShiftClmnX2( :, i ), Y2( :, i ) + ShiftRowY2(:, i), EdgeColor, 'EdgeColor', EdgeColor, 'FaceColor', FaceColor, 'LineWidth', LineWidth );
    hOrient1 = line( MainOrientX1( :, i ) + ShiftMainOrientX1( :, i ), MainOrientY1( :, i ) + ShiftMainOrientY1( :, i ), 'Color', EdgeColor, 'LineWidth', LineWidth);
    hOrient2 = line( MainOrientX2( :, i ) + ShiftMainOrientX2( :, i ), MainOrientY2( :, i ) + ShiftMainOrientY2( :, i ), 'Color', EdgeColor, 'LineWidth', LineWidth);
    
    rotate( hPatch1, [ 0 0 1 ], Angles1(i), Origin4Rotation1( i,: ) );
    rotate( hOrient1, [ 0 0 1 ], Angles1(i), Origin4Rotation1( i,: ) );
    rotate( hPatch2, [ 0 0 1 ], Angles2(i), Origin4Rotation2( i,: ) );
    rotate( hOrient2, [ 0 0 1 ], Angles2(i), Origin4Rotation2( i,: ) );
    waitbar( i/N )
end
close(h)
    case 'Aff'
       hold on; plot( clmnX1, rowY1, 'r+' ); plot( clmnX2, rowY2, 'r+' ); 
end

% plot according lines
line( LineCoordX, LineCoordY, 'Color', LineColor, 'LineWidth', LineWidth, 'LineStyle', Linestyle );
