function [ HrLOrntPoints ] = mainOrient( HrLPoints, img, Thresh, Factor, AngleBin, TypeOfMainOrient, SwitchWaitbars  )
% Function receives 'HrLPoints', and intensity image 'img', and returns 
% matrix 'HrLOrntPoints' - with the same elements as HrLPoints, but with
% additional column, with values = main orientaion.
% Main orient. will be maximum value in h ( mx = max(h) ) ( weighted histogram of gradient angles ),
% with condition that there is no other peak grater then Thresh*max(h) - if TypeOfMainOrient = 'one'.
% If TypeOfMainOrient = 'some', then will be taken all orienations, that
% are biger then mx*Thresh ( for example, that are bigger then 80% of maximum-supported value ).
% Factor - scalar for smoothing gradients norm, see harrislpls.m
% AngleBin - interval's length for calc. angle weighted-histogram.
% TypeOfMainOrient - 'one'/'some'. Specifies how many characteristic
% orientations can be for FP.

img = double(img);
%----------- Defining edges for histogram -------------%
Edges4Hist = 0:AngleBin:360;
if Edges4Hist( end ) ~= 360
    Edges4Hist( end + 1 ) = 360;
end
% defining number of bins
NOfBins = ceil( 360/AngleBin );

    
% finding range of scales
Scales = unique( HrLPoints( :, 3 ) );
NOfScales = length( Scales );

%------------------- Padding image --------------------%
% scalar 3, is good becuase I'm taking patch of size 3*scale to each direction from FP 
Paddvalue = max( Scales ); Paddvalue = ceil( 3*Paddvalue );
img = padarray( img, [ Paddvalue Paddvalue ], 'symmetric' );

%------------------- Shifting coordinates --------------------%
HrLPoints( :, [ 1 2 4 5 ] ) = HrLPoints( :, [ 1 2 4 5 ] ) + Paddvalue;

[ Nrow, Nclmn ] = size(img);

% N = size(HrLPoints,1);
HrLOrntPoints = zeros(0,6);

if strcmp( SwitchWaitbars, 'on' )
h = waitbar(0,'Calculating main orientations:');
end
for i = 1:NOfScales
    
    scale = Scales(i);
    % defining linear indexes of elements in patch of size according to
    % given sigma/Scales(i), near coord ( 0, 0 ).
    win0ind = win2ind( Nrow, Nclmn, ceil( 3*scale ) );
    % number of elements in each patch
    sz = length( win0ind );
    IndOfFP = find( HrLPoints( :, 3 ) == scale );
    if ~isempty( IndOfFP )
    row = round(HrLPoints( :, 4 )); clmn = round(HrLPoints( :, 5 ));
    row = row( IndOfFP ); clmn = clmn( IndOfFP );
    LinearIndOfFPScale_i = sub2ind( [ Nrow, Nclmn ], row, clmn );
    NofFPScale_i = length( LinearIndOfFPScale_i );
    
    % indexes shift for histc.m, in order that each patch/region of FP
    % will be count separately
    IndexShiftBins4Accum = NOfBins*(0:1:(NofFPScale_i-1));
    IndexShiftBins4Accum = repmat( IndexShiftBins4Accum, sz, 1 );
    IndexShiftBins4Accum = IndexShiftBins4Accum(:);
    
    
%------------------ Derivative mask -------------------%
    x  = -ceil(3*scale):ceil(3*scale);
    [ X, Y ] = meshgrid(x,x);
    dGdx = -X .* exp(-( X.*X + Y.*Y )/(2*scale*scale)) ./ ((scale^4)*(2*pi));
    
%-------------------- Derivatives ---------------------%  
% 'normalized'
%     Ix = scale*(imfilter(img, dGdx, 'same'));
%     Iy = scale*(imfilter(img, dGdx', 'same'));
% not normalized - no point in normalization, won't influence the
% accumulation support of directions.
    Ix = imfilter(img, dGdx,  'same');
    Iy = imfilter(img, dGdx', 'same');
    
%----------------- Norm of gradients ------------------% 
    gradient_norm = sqrt(Ix.^2 + Iy.^2);
    
 %------------- Avaraging norm gradients --------------% 
    g   = fspecial('gaussian',max(1,fix(6*scale*Factor +1)), scale*Factor);
    gradient_norm = imfilter(gradient_norm, g,  'same');  

%----------------- Angles of gradients ----------------% 
    gradient_angles = rad2deg( atan2( Iy, Ix ) + pi );
    
%---------------- Combining all indexes ---------------% 
    % for FP IndOfFP(i), indexes of elements in patch near it are accomulated in 
    % column AllIndexes()
    AllIndexes = repmat( win0ind(:), 1, NofFPScale_i ) + repmat( (LinearIndOfFPScale_i(:))', sz, 1 );
      
%------------------ Combining all data ----------------%    
    AllNorms = gradient_norm( AllIndexes );
    AllAngles = gradient_angles( AllIndexes );
    
%-------------- Assigning angles 2 bins ---------------% 
    [ n, AngleBins ] = histc( AllAngles(:), Edges4Hist );
    
%---------------- Shifting angle bins -----------------% 
    AngleBinsShifted = AngleBins + IndexShiftBins4Accum;
    
%-------- Accumulating norms 2 according bins ---------%
    AssignedNorms = accumarray( AngleBinsShifted, AllNorms(:), [ NOfBins*NofFPScale_i, 1 ] );
    % reshaping it back, so each column corresponds to different FP
    AssignedNorms = reshape( AssignedNorms, NOfBins, NofFPScale_i );
    
%------------------ Finding maximums ------------------%  
    [ mx IndOfBinOfMainOrient ] = max( AssignedNorms );
    
%--------------- Thresholding maximums ----------------%    
    MxMtr = repmat( mx*Thresh, NOfBins, 1 );
    % taking maximum value ony if it the only one that bigger then Thrsh*( it's value )
    switch TypeOfMainOrient
        case 'some'
             [ IndOfAngleBin IndexFP ] = find( MxMtr <= AssignedNorms );
              
        case 'one'
             IndexFP = find( sum(MxMtr <= AssignedNorms) == 1 );
             IndOfAngleBin = IndOfBinOfMainOrient( IndexFP );
    end
    % indexes in HrLPoints of FP with MO
    IndOfFP = IndOfFP( IndexFP );
    
%---------------- Assigning values /'max' -------------% 
    MainOrientations = AngleBin*IndOfAngleBin;
    len = length(MainOrientations);
    if len
       HrLOrntPoints( (end + 1):(end + len), : ) = [ HrLPoints(IndOfFP, :), MainOrientations(:) ];
    end
    end
   if strcmp( SwitchWaitbars, 'on' )
    waitbar(i/NOfScales)
   end
end
   if strcmp( SwitchWaitbars, 'on' )
   close(h); 
   end
   
HrLOrntPoints( :, [ 1 2 4 5 ] ) = HrLOrntPoints( :, [ 1 2 4 5 ] ) - Paddvalue;