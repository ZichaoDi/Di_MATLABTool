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

[ m1, n1 ] = size( img1gr );
[ m2, n2 ] = size( img2gr );

%-------------------- Parameters -------------------%
SwitchWaitbars = 'off'; % 'off'/'on'
%--------------- Descriptors 4 FP ------------------%
TypeOfFP = 'Aff'; % 'Aff'/'HL'
TypeOfDescriptor = 'SIFT'; % there is possibility to add diferent type of descr., however I've implemented only SIFT.
NOfWindows = 4; % near each FP will be taken NOfWindows^2 of windows of size 4x4
AngleBinDescript = 45; % degrees
ThreshDescript = 0.2;
FactorDescript = 1.5;
StepSampleFunction = @(x) sqrt(1+x^2);
%-------------------- 'ASIFT' ----------------------%
TiltVectorRange = sqrt(2).^([ 0 1 2 3 4 ]); % also can be taken (0, 3 - 5)
StepAngleFunction = @(x) 72/x; % 72/x
TypeOfViewSimulation = 'both'; % 'first'/'second'/'both'
% which image views need to simulate
BlureTilt = 'no'; % 'yes'/'no'
BlureSigmaFunction = @(x) sqrt( x^2 - 1 ); % depends on tilt value

%--------------------- Harris ----------------------%
TypeOfCornerDetector = 'HarmonicMean'; % 'Harris'/'HarmonicMean'
TypeOfNBHOOD = 'const'; % 'const'/'dif'. 'dif' - depends on scale
NBHOOD = ones(3); % scalar or binar matrix, specifying neighberhood
BorderDistance = 3*NOfWindows;
ThreshType = 'const'; % 'const'/'percent'
HarrisThresh = 10; % in case of 'HarmonicMean', thresh ~ 10, Harris ~ 1000
k = 0.055; % parameter for Harris function
Dilate = 'no'; % 'yes'/'no'
radius = 2;
sigma_nmbr = 3;
dispMatches = 0; % 0/1

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
TypeOfMatchThresh = 'first/second&first'; % 'first'  / 'first/second'  / 'first/second&first'
ThreshFS = 0.78; % thresh for first/second ( 0.5 - ~0.8 )
% need to worry that, if there is a big difference in viewpoints between
% images, then take ~0.55 - 0.61, else can be taken ~0.75 - 0.8
ThreshF = 0.5; % thresh for first ( 0.33 - 0.55 )

%--------------------------------------------------------------------%
%----------- Simulating views for ASIFT --------------%
if strcmp( TypeOfViewSimulation, 'first' ) || strcmp( TypeOfViewSimulation, 'both' )
    cnt1 = 1;
 DescriptHrLPoints1 = {};
 HrLOrntPoints1 = {};
 
        img1Orig = img1gr;
        for t = TiltVectorRange
            DeltaPhi = StepAngleFunction( t );
            for phi = 0:DeltaPhi:(180-eps)
                phiAngle = deg2rad( phi );
                % defining tilt and longitude affin simulation matrix
                T = zeros( 3 );
                T(3,3)=1;
                Tilt = eye(2);
                Tilt(1) = t;
                R = [ cos(phiAngle) -sin(phiAngle); sin(phiAngle) cos(phiAngle) ];
                Aff = Tilt*R;
                T( 1:2, 1:2 ) =  Aff';
                Tf = maketform('affine',T); % affine transformation for view-simulation 
                
                if strcmp(BlureTilt, 'yes')
                   sigma = BlureSigmaFunction( t );
                    if sigma > 0
                   g = fspecial( 'gaussian', [ 1, round( 6*sigma ) + 1 ], sigma );
                   img1gr = imfilter( img1Orig, g, 'same' );
                    else
                   img1gr = img1Orig;    
                    end
                else
                   img1gr = img1Orig;
                end
                BorderDistanceMatrix = zeros( m1, n1 ); 
                BorderDistanceMatrix( (BorderDistance + 1):(m1 - BorderDistance), (BorderDistance + 1):(n1 - BorderDistance) ) = 1;
                [ imgSimulated, xdata, ydata ] = imtransform( img1gr, Tf );
                BorderDistanceMatrix = imtransform( BorderDistanceMatrix, Tf, 'xdata', xdata, 'ydata', ydata );
%- Finding FP and they char. scale (Harris-Laplace)  -% 
                [ HrLPointsTmp1 ] = harrislpls( imgSimulated, TypeOfNBHOOD, NBHOOD, TypeOfCornerDetector, BorderDistanceMatrix, ThreshType, HarrisThresh, k, Dilate, radius, sigma_nmbr, disp, SwitchWaitbars );
                
%----------- Finding Main Orientation -------------%
                [ HrLOrntPointsTmp1 ] = mainOrient( HrLPointsTmp1, imgSimulated, ThreshMainOrient, FactorMainOrient, AngleBinMainOrient, TypeOfMainOrient, SwitchWaitbars );
                
%------------------ Descripting -------------------%
                [ DescriptHrLPointsTmp1 ] = descriptFPoints( HrLOrntPointsTmp1, imgSimulated, TypeOfDescriptor, NOfWindows, StepSampleFunction, AngleBinDescript, ThreshDescript, FactorDescript, SwitchWaitbars );
                
%----- Converting FP coordinates to original ------%
% back to coordinates, before shift for image coord. ( xdata(1) -> 1, ydata(1) -> 1 )
                HrLOrntPointsTmp1( :, [ 2 5  ] ) = HrLOrntPointsTmp1( :, [ 2 5 ] ) - 1 + xdata(1);
                HrLOrntPointsTmp1( :, [ 1 4  ] ) = HrLOrntPointsTmp1( :, [ 1 4 ] ) - 1 + ydata(1);
% back to original image coordinates
                tmp = tforminv( Tf, HrLOrntPointsTmp1( :, 5 ), HrLOrntPointsTmp1( :, 4 ));
                HrLOrntPointsTmp1( :, 2 ) = round(tmp(:,1)); HrLOrntPointsTmp1( :, 1 ) = round(tmp(:,2)); 
                HrLOrntPointsTmp1( :, 1 ) = max( HrLOrntPointsTmp1( :, 1 ), 1 ); HrLOrntPointsTmp1( :, 1 ) = min( HrLOrntPointsTmp1( :, 1 ), m1 );
                HrLOrntPointsTmp1( :, 2 ) = max( HrLOrntPointsTmp1( :, 2 ), 1 ); HrLOrntPointsTmp1( :, 2 ) = min( HrLOrntPointsTmp1( :, 2 ), n1 );
                HrLOrntPointsTmp1( :, 5 ) = tmp(:,1); HrLOrntPointsTmp1( :, 4 ) = tmp(:,2);
% adding FP to all FP, that were founded before
                DescriptHrLPoints1{cnt1} = DescriptHrLPointsTmp1;
                HrLOrntPoints1{cnt1} = HrLOrntPointsTmp1;
                cnt1 = cnt1 + 1;
            end
        end
else
    
[ HrLPoints1 ] = harrislpls( img1gr, TypeOfNBHOOD, NBHOOD, TypeOfCornerDetector, BorderDistance, ThreshType, HarrisThresh, k, Dilate, radius, sigma_nmbr, disp, SwitchWaitbars );
    
%----------- Finding Main Orientation -------------%
[ HrLOrntPoints1 ] = mainOrient( HrLPoints1, img1gr, ThreshMainOrient, FactorMainOrient, AngleBinMainOrient, TypeOfMainOrient, SwitchWaitbars );

%------------------ Descripting -------------------%
[ DescriptHrLPoints1 ] = descriptFPoints( HrLOrntPoints1, img1gr, TypeOfDescriptor, NOfWindows, StepSampleFunction, AngleBinDescript, ThreshDescript, FactorDescript, SwitchWaitbars );
end

% save('test.mat');

if strcmp( TypeOfViewSimulation, 'second' ) || strcmp( TypeOfViewSimulation, 'both' )
 cnt2 = 1;
 DescriptHrLPoints2 = {};
 HrLOrntPoints2 = {};
 
        img2Orig = img2gr;
        for t = TiltVectorRange
            DeltaPhi = StepAngleFunction( t );
            for phi = 0:DeltaPhi:(180-eps)
                phiAngle = deg2rad( phi );
                % defining tilt and longitude affin simulation matrix
                T = zeros( 3 );
                T(3,3)=1;
                Tilt = eye(2);
                Tilt(1) = t;
                R = [ cos(phiAngle) -sin(phiAngle); sin(phiAngle) cos(phiAngle) ];
                Aff = Tilt*R;
                T( 1:2, 1:2 ) =  Aff';
                Tf = maketform('affine',T); % affine transformation for view-simulation 
                
                if strcmp(BlureTilt, 'yes')
                   sigma = BlureSigmaFunction( t );
                    if sigma > 0
                   g = fspecial( 'gaussian', [ 1, round( 6*sigma ) + 1 ], sigma );
                   img2gr = imfilter( img2Orig, g, 'same' );
                    else
                   img2gr = img2Orig;    
                    end
                else
                   img2gr = img2Orig;
                end 
                BorderDistanceMatrix = zeros( m2, n2 ); 
                BorderDistanceMatrix( (BorderDistance + 1):(m2 - BorderDistance), (BorderDistance + 1):(n2 - BorderDistance) ) = 1;
                [ imgSimulated, xdata, ydata ] = imtransform( img2gr, Tf );
                BorderDistanceMatrix = imtransform( BorderDistanceMatrix, Tf, 'xdata', xdata, 'ydata', ydata );
%- Finding FP and they char. scale (Harris-Laplace)  -% 
                [ HrLPointsTmp2 ] = harrislpls( imgSimulated, TypeOfNBHOOD, NBHOOD, TypeOfCornerDetector, BorderDistanceMatrix, ThreshType, HarrisThresh, k, Dilate, radius, sigma_nmbr, disp, SwitchWaitbars );
                
%----------- Finding Main Orientation -------------%
                [ HrLOrntPointsTmp2 ] = mainOrient( HrLPointsTmp2, imgSimulated, ThreshMainOrient, FactorMainOrient, AngleBinMainOrient, TypeOfMainOrient, SwitchWaitbars );
                
%------------------ Descripting -------------------%
                [ DescriptHrLPointsTmp2 ] = descriptFPoints( HrLOrntPointsTmp2, imgSimulated, TypeOfDescriptor, NOfWindows, StepSampleFunction, AngleBinDescript, ThreshDescript, FactorDescript, SwitchWaitbars );
                
%----- Converting FP coordinates to original ------%
% back to coordinates, before shift for image coord. ( xdata(1) -> 1, ydata(1) -> 1 )
                HrLOrntPointsTmp2( :, [ 2 5  ] ) = HrLOrntPointsTmp2( :, [ 2 5 ] ) - 1 + xdata(1);
                HrLOrntPointsTmp2( :, [ 1 4  ] ) = HrLOrntPointsTmp2( :, [ 1 4 ] ) - 1 + ydata(1);
% back to original image coordinates
                tmp = tforminv( Tf, HrLOrntPointsTmp2( :, 5 ), HrLOrntPointsTmp2( :, 4 ));
                HrLOrntPointsTmp2( :, 2 ) = round(tmp(:,1)); HrLOrntPointsTmp2( :, 1 ) = round(tmp(:,2)); 
                HrLOrntPointsTmp2( :, 1 ) = max( HrLOrntPointsTmp2( :, 1 ), 1 ); HrLOrntPointsTmp2( :, 1 ) = min( HrLOrntPointsTmp2( :, 1 ), m2 );
                HrLOrntPointsTmp2( :, 2 ) = max( HrLOrntPointsTmp2( :, 2 ), 1 ); HrLOrntPointsTmp2( :, 2 ) = min( HrLOrntPointsTmp2( :, 2 ), n2 );
                HrLOrntPointsTmp2( :, 5 ) = tmp(:,1); HrLOrntPointsTmp2( :, 4 ) = tmp(:,2);
% adding FP to all FP, that were founded before
                DescriptHrLPoints2{cnt2} = DescriptHrLPointsTmp2;
                HrLOrntPoints2{cnt2} = HrLOrntPointsTmp2;
                cnt2 = cnt2 + 1;
            end
        end
else
    
[ HrLPoints2 ] = harrislpls( img2gr, TypeOfNBHOOD, NBHOOD, TypeOfCornerDetector, BorderDistance, ThreshType, HarrisThresh, k, Dilate, radius, sigma_nmbr, disp, SwitchWaitbars );
    
%----------- Finding Main Orientation -------------%
[ HrLOrntPoints2 ] = mainOrient( HrLPoints2, img2gr, ThreshMainOrient, FactorMainOrient, AngleBinMainOrient, TypeOfMainOrient, SwitchWaitbars );

%------------------ Descripting -------------------%
[ DescriptHrLPoints2 ] = descriptFPoints( HrLOrntPoints2, img2gr, TypeOfDescriptor, NOfWindows, StepSampleFunction, AngleBinDescript, ThreshDescript, FactorDescript, SwitchWaitbars );
end

% save('test.mat');

switch TypeOfViewSimulation
    case 'first'
    Match1 = []; Match2 = [];
for i = 1:(cnt1-1) 
switch TypeOfMatchThresh
    case 'first'
Thresh = ThreshF;        
[ MatchedPairs ] = matchFPoints( DescriptHrLPoints1{i}, DescriptHrLPoints2, TypeOfSearch, HelpScalarOrVector, TypeOfMatchThresh, Thresh, SwitchWaitbars ); 
ind = find( MatchedPairs );
Match1Tmp = HrLOrntPoints1{i}( ind, [ 1 2 3 end ] );
ind = MatchedPairs( ind );
Match2Tmp = HrLOrntPoints2( ind, [ 1 2 3 end ] );
    case 'first/second'
Thresh = ThreshFS;        
[ MatchedPairs ] = matchFPoints( DescriptHrLPoints1{i}, DescriptHrLPoints2, TypeOfSearch, HelpScalarOrVector, TypeOfMatchThresh, Thresh, SwitchWaitbars ); 
ind = find( MatchedPairs );
Match1Tmp = HrLOrntPoints1{i}( ind, [ 1 2 3 end ] );
ind = MatchedPairs( ind );
Match2Tmp = HrLOrntPoints2( ind, [ 1 2 3 end ] );     
    case 'first/second&first'
Thresh = ThreshFS;        
[ MatchedPairs ] = matchFPoints( DescriptHrLPoints1{i}, DescriptHrLPoints2, TypeOfSearch, HelpScalarOrVector, 'first/second', Thresh, SwitchWaitbars  );
ind1 = find( MatchedPairs );
ind2 = MatchedPairs( ind1 );
% take only those pairs, that are at distance each from other less then ThreshF
ind = find( sqrt(sum( ((DescriptHrLPoints1{i}( ind1, : ) - DescriptHrLPoints2( ind2, : )).^2), 2 )) <= ThreshF );
ind1 = ind1( ind );
ind2 = ind2( ind );
Match1Tmp = HrLOrntPoints1{i}( ind1, [ 1 2 3 end ] );
Match2Tmp = HrLOrntPoints2( ind2, [ 1 2 3 end ] );
end
Match1 = [ Match1; Match1Tmp ]; Match2 = [ Match2; Match2Tmp ]; 
end    
    case 'second'
    Match1 = []; Match2 = [];
for i = 1:(cnt2-1) 
switch TypeOfMatchThresh
    case 'first'
Thresh = ThreshF;        
[ MatchedPairs ] = matchFPoints( DescriptHrLPoints1, DescriptHrLPoints2{i}, TypeOfSearch, HelpScalarOrVector, TypeOfMatchThresh, Thresh, SwitchWaitbars ); 
ind = find( MatchedPairs );
Match1Tmp = HrLOrntPoints1( ind, [ 1 2 3 end ] );
ind = MatchedPairs( ind );
Match2Tmp = HrLOrntPoints2{i}( ind, [ 1 2 3 end ] );
    case 'first/second'
Thresh = ThreshFS;        
[ MatchedPairs ] = matchFPoints( DescriptHrLPoints1, DescriptHrLPoints2{i}, TypeOfSearch, HelpScalarOrVector, TypeOfMatchThresh, Thresh, SwitchWaitbars ); 
ind = find( MatchedPairs );
Match1Tmp = HrLOrntPoints1( ind, [ 1 2 3 end ] );
ind = MatchedPairs( ind );
Match2Tmp = HrLOrntPoints2{i}( ind, [ 1 2 3 end ] );     
    case 'first/second&first'
Thresh = ThreshFS;        
[ MatchedPairs ] = matchFPoints( DescriptHrLPoints1, DescriptHrLPoints2{i}, TypeOfSearch, HelpScalarOrVector, 'first/second', Thresh, SwitchWaitbars  );
ind1 = find( MatchedPairs );
ind2 = MatchedPairs( ind1 );
% take only those pairs, that are at distance each from other less then ThreshF
ind = find( sqrt(sum( ((DescriptHrLPoints1( ind1, : ) - DescriptHrLPoints2{i}( ind2, : )).^2), 2 )) <= ThreshF );
ind1 = ind1( ind );
ind2 = ind2( ind );
Match1Tmp = HrLOrntPoints1( ind1, [ 1 2 3 end ] );
Match2Tmp = HrLOrntPoints2{i}( ind2, [ 1 2 3 end ] );
end
Match1 = [ Match1; Match1Tmp ]; Match2 = [ Match2; Match2Tmp ]; 
end 
    case 'both'
    Match1 = []; Match2 = []; 
       for i = 1:(cnt1 - 1)
           for j = 1:(cnt2 -1)
switch TypeOfMatchThresh
    case 'first'
Thresh = ThreshF;        
[ MatchedPairs ] = matchFPoints( DescriptHrLPoints1{i}, DescriptHrLPoints2{j}, TypeOfSearch, HelpScalarOrVector, TypeOfMatchThresh, Thresh, SwitchWaitbars ); 
ind = find( MatchedPairs );
Match1Tmp = HrLOrntPoints1{i}( ind, [ 1 2 3 end ] );
ind = MatchedPairs( ind );
Match2Tmp = HrLOrntPoints2{j}( ind, [ 1 2 3 end ] );
    case 'first/second'
Thresh = ThreshFS;        
[ MatchedPairs ] = matchFPoints( DescriptHrLPoints1{i}, DescriptHrLPoints2{j}, TypeOfSearch, HelpScalarOrVector, TypeOfMatchThresh, Thresh, SwitchWaitbars ); 
ind = find( MatchedPairs );
Match1Tmp = HrLOrntPoints1{i}( ind, [ 1 2 3 end ] );
ind = MatchedPairs( ind );
Match2Tmp = HrLOrntPoints2{j}( ind, [ 1 2 3 end ] );   
    case 'first/second&first'
Thresh = ThreshFS;        
[ MatchedPairs ] = matchFPoints( DescriptHrLPoints1{i}, DescriptHrLPoints2{j}, TypeOfSearch, HelpScalarOrVector, 'first/second', Thresh, SwitchWaitbars  );
ind1 = find( MatchedPairs );
ind2 = MatchedPairs( ind1 );
% take only those pairs, that are at distance each from other less then ThreshF
ind = find( sqrt(sum( ((DescriptHrLPoints1{i}( ind1, : ) - DescriptHrLPoints2{j}( ind2, : )).^2), 2 )) <= ThreshF );
ind1 = ind1( ind );
ind2 = ind2( ind );
Match1Tmp = HrLOrntPoints1{i}( ind1, [ 1 2 3 end ] );
Match2Tmp = HrLOrntPoints2{j}( ind2, [ 1 2 3 end ] );
end
Match1 = [ Match1; Match1Tmp ]; Match2 = [ Match2; Match2Tmp ]; 
% PlotMatches( img1, Match1Tmp, img2, Match2Tmp, 'sigma', TypeOfFP );
           end
       end
end

%--------------------- Ploting --------------------%
PlotMatches( img1, Match1, img2, Match2, 'sigma', TypeOfFP );