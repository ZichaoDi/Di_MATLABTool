% assumption, that we have img1 and img2.

if isrgb(img1)
    img1gr = rgb2gray( img1 );
else
    img1gr = img1;
end
if isrgb(img2)
    img2gr = rgb2gray( img2 );
else 
    img2gr = img2;
end

%-------------------- Parameters -------------------%
SwitchWaitbars = 'on'; % 'off'/'on'
%--------------- Descriptors 4 FP ------------------%
TypeOfFP = 'HL'; % 'Aff'/'HL' - type of ploting results. 'HL' - plots rectangle.
TypeOfDescriptor = 'SIFT'; % there is possibility to add diferent type of descr., however I've implemented only SIFT.
NOfWindows = 4; % near each FP will be taken NOfWindows^2 of windows of size 4x4
AngleBinDescript = 45; % degrees
ThreshDescript = 0.2;
FactorDescript = 1.5;
StepSampleFunction = @(x) sqrt(1+x^2);

%--------------------- Harris ----------------------%
TypeOfCornerDetector = 'HarmonicMean'; % 'Harris'/'HarmonicMean'
TypeOfNBHOOD = 'const'; % 'const'/'dif'. 'dif' - depends on scale
NBHOOD = ones(3); % scalar or binar matrix, specifying neighberhood
BorderDistance = 4*NOfWindows;
ThreshType = 'const'; % 'const'/'percent'
HarrisThresh = 10; % in case of 'HarmonicMean', thresh ~ 10
k = 0.055; % parameter for Harris function
Dilate = 'no'; % 'yes'/'no'
radius = 2;
sigma_nmbr = 9; % 5 - 17

dispPlaces = 1; % 1/0 - shows only places of FP's, without scale, orientation.
dispMOCS = 0; % 1/0 - displays rectangles with edges proport. to charac. scale, and rotated as main orientation - takes a lot of time 
dispMatches = 1; % 0/1

%--------------- Main Orientation -----------------%
ThreshMainOrient = 0.8;
FactorMainOrient = 1.5;
AngleBinMainOrient = 10; 
TypeOfMainOrient = 'some'; % 'one'/'some'. 'one' - for each FP take only one Main Orientation 
% ( take it, if this orient. is the only one bigger then ThreshMainOrient % of it's value )
% 'some' - take all orientations, that bigger then thresh, described above.

%----------------- Matching FPs -------------------%
TypeOfSearch = 'determ'; %'determ' 1/2, 'kmeans','kNN', 'ANN', for not big data preferable 'determ' 2,
% 'kmeans' - just for experiment.
HelpScalarOrVector = 2;
TypeOfMatchThresh = 'first/second'; % 'first'  / 'first/second'  / 'first/second&first'
ThreshFS = 0.78; % thresh for first/second ( 0.7 - ~0.85 )
ThreshF = 0.5; % thresh for first ( 0.2 - 0.5 )

%--------------------------------------------------------------------%
%- Finding FP and they char. scale (Harris-Laplace)  -% 
[ HrLPoints1 ] = harrislpls( img1gr, TypeOfNBHOOD, NBHOOD, TypeOfCornerDetector, BorderDistance, ThreshType, HarrisThresh, k, Dilate, radius, sigma_nmbr, dispPlaces, SwitchWaitbars );
[ HrLPoints2 ] = harrislpls( img2gr, TypeOfNBHOOD, NBHOOD, TypeOfCornerDetector, BorderDistance, ThreshType, HarrisThresh, k, Dilate, radius, sigma_nmbr, dispPlaces, SwitchWaitbars );

%----------- Finding Main Orientation -------------%
[ HrLOrntPoints1 ] = mainOrient( HrLPoints1, img1gr, ThreshMainOrient, FactorMainOrient, AngleBinMainOrient, TypeOfMainOrient, SwitchWaitbars );
[ HrLOrntPoints2 ] = mainOrient( HrLPoints2, img2gr, ThreshMainOrient, FactorMainOrient, AngleBinMainOrient, TypeOfMainOrient, SwitchWaitbars );

%------------------ Descripting -------------------%
[ DescriptHrLPoints1 ] = descriptFPoints( HrLOrntPoints1, img1gr, TypeOfDescriptor, NOfWindows, StepSampleFunction, AngleBinDescript, ThreshDescript, FactorDescript, SwitchWaitbars );
[ DescriptHrLPoints2 ] = descriptFPoints( HrLOrntPoints2, img2gr, TypeOfDescriptor, NOfWindows, StepSampleFunction, AngleBinDescript, ThreshDescript, FactorDescript, SwitchWaitbars );

%-------------------- Matching --------------------%
switch TypeOfMatchThresh
    case 'first'
Thresh = ThreshF;
[ MatchedPairs ] = matchFPoints( DescriptHrLPoints1, DescriptHrLPoints2, TypeOfSearch, HelpScalarOrVector, TypeOfMatchThresh, Thresh, SwitchWaitbars );
    case 'first/second'
Thresh = ThreshFS;
[ MatchedPairs ] = matchFPoints( DescriptHrLPoints1, DescriptHrLPoints2, TypeOfSearch, HelpScalarOrVector, TypeOfMatchThresh, Thresh, SwitchWaitbars );
    case 'first/second&first'
Thresh = ThreshFS;
[ MatchedPairs ] = matchFPoints( DescriptHrLPoints1, DescriptHrLPoints2, TypeOfSearch, HelpScalarOrVector, 'first/second', Thresh, SwitchWaitbars );
ind1 = find( MatchedPairs );
ind2 = MatchedPairs( ind1 );
% take only those pairs, that are at distance each from other less then ThreshF
ind = find( sqrt(sum( ((DescriptHrLPoints1( ind1, : ) - DescriptHrLPoints2( ind2, : )).^2), 2 )) <= ThreshF );
ind1 = ind1( ind );
ind2 = ind2( ind );
end

%--------------------- 4 Ploting ------------------%
switch TypeOfMatchThresh
    case 'first/second&first'
Match1 = HrLOrntPoints1( ind1, [ 1 2 3 end ] );
Match2 = HrLOrntPoints2( ind2, [ 1 2 3 end ] );
    otherwise
ind1 = find( MatchedPairs );
ind2 = MatchedPairs( ind1 );
Match1 = HrLOrntPoints1( ind1, [ 1 2 3 end ] );
Match2 = HrLOrntPoints2( ind2, [ 1 2 3 end ] );
end

%------------- Removing the same pairs ------------%
[ b, ind, ind2 ] = unique( [ Match1(:, [1 2]), Match2(:, [1 2]) ], 'rows' ); clear b ind2
Match1 = Match1( ind, : );
Match2 = Match2( ind, : );

if dispMOCS
    PlotFP( img1, HrLOrntPoints1 );
    PlotFP( img2, HrLOrntPoints2 );
end

if dispMatches
    PlotMatches( img1, Match1, img2, Match2, 'sigma', TypeOfFP );
end