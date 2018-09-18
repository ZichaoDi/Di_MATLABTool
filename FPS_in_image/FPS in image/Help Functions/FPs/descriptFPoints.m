function [ DescriptFPVector ] = descriptFPoints( HrLOrntPoints, img, type, NOfWindows, StepSampleFunction, AngleBin, Thresh, Factor, SwitchWaitbars  )
% Fuction receives HrLOrntPoints, and returns matrix DescriptFPVector,
% which descripts those points.
% Factor - smoothing param. for norm of grad. 
% Thresh ( 0.2  )- giving more importance to directions of gradients,
% and not to their magnitude.
% StepSampleFunction - handle of function, that depends on sigma (
% characteristic scale ). Step = StepSampleFunction( sigma ); values for
% descriptor will be sampled in neighborhood of FP, with pace = Step, in direction of MO ( main orientation ).
% Will be taken number of samples enough in order to create description vector of size - NOfBins*(NOfWindows^2).
% In order to take regular neighborhood, StepSampleFunction = @(x) 1 ( will be constant function = 1 ).
% Assumption that StepSampleFunction - is non-decreasing function / the bigger sigma - the bigger step /.

img = double( img );
% imgOrig = img;
%------------------- Padding image --------------------%
Paddvalue = max( HrLOrntPoints( :, 3 ) ); % maximal sigma
% will be taken patch of size 4*NOfWindows*StepSampleFunction( sigma ), so
% need to be sure for possibility to take such patch even for biggest
% sigma.
% scalar 3, is good becuase I'm taking patch of size 3*scale to each
% direction from FP / for derivatives / 
Paddvalue = max( 2*ceil( 3*Paddvalue ), ceil(sqrt(2)*(2*NOfWindows*StepSampleFunction( Paddvalue )+1)) );
img = padarray( img, [ Paddvalue Paddvalue ], 'symmetric' );

%------------------- Shifting coordinates --------------------%
HrLOrntPoints( :, [ 1 2 4 5 ] ) = HrLOrntPoints( :, [ 1 2 4 5 ] ) + Paddvalue;

%---------------------- Parameters --------------------%
N = size(HrLOrntPoints,1);
[ Nrow, Nclmn ] = size(img);
DescriptFPVector = [];

%---------- Parameters and Pre-Proc. for SIFT ---------%
if strcmp(type,'SIFT')
%     NOfWindows = 4; % 1, ..
    % in descriptor will be NOfWindows^2 blocks of size 4x4
    % each angle-bin will be of size AngleBin degrees, edges for histogram will be though 0:AngleBin:360
    NOfBins = ceil( 360/AngleBin );
    Edges4Hist = 0:AngleBin:360;
    % check if all range of angles is covered by edges, if not, then fill
    % it 
    if Edges4Hist( end ) ~= 360
        Edges4Hist( end + 1 ) = 360;
    end
    DescriptFPVector = zeros( N, NOfBins*(NOfWindows^2) );
    
%- Finding indexes of blocks, and arrange them in column -% 
% Counting of blocks will be in column-major order. For each block there
% are 4*4 = 16 pixels. There are NOfWindows^2 ( #blocks ) of blocks, so number of
% elements in IndexMaskOfBlocks will be as number of pixels: 16*#blocks.
% First 16 elements will be linear indexes of 1-st block, and so on.
% Elements 16*(i-1) + 1 till 16*i - are linear indeces in column-major of block i. 
    IndexMaskOfBlocks = reshape( 1:(16*(NOfWindows^2)), 4*NOfWindows, 4*NOfWindows );
    Cell = mat2cell( IndexMaskOfBlocks, repmat( 4, 1, NOfWindows ), repmat( 4, 1, NOfWindows )  );
    for i = 1:NOfWindows^2
        IndexMaskOfBlocks( ((1:16) + 16*(i-1)) ) = Cell{i}(:);
    end
    IndexMaskOfBlocks = IndexMaskOfBlocks(:);
    clear Cell;
    
%------------- Finding index-shift 4 histc ------------%    
% In order to apply accumarray, we have that 16 values from each block will
% be assigned to defferent part of descriptor vector ( each part of size
% NOfBins ).
% So let's say, that we devided angles of each block to NOfBins angle bins.
% We apply IndexMaskOfBlocks on patch with blocks ( output - vector binTotal ), and receive arranged
% bins of blocks ( first 16 elements - bins of 1 block and so on.. )
% now we take bin = binTotal + IndexShiftAccumBins; so we received new
% bin-vector, number of bins is NOfBins*NOfWindows^2. So for each block
% there is part of NOfBins elements in bin-vector, which ( bin-vector ) after will be
% normalized and used as discriptor.
    IndexShiftBins4Accum = NOfBins*(0:1:(NOfWindows^2-1));
    IndexShiftBins4Accum = repmat( IndexShiftBins4Accum, 16, 1 );
    IndexShiftBins4Accum = IndexShiftBins4Accum(:);
end



    switch type
        case 'SIFT'
if strcmp( SwitchWaitbars, 'on' )
h = waitbar(0,'Calculating descriptors:'); 
end
for i = 1:N
       
%---------------- Data of feature point ---------------%        
    Scale = HrLOrntPoints(i,3);
    MainOrient = deg2rad(HrLOrntPoints(i,6));
    row0 = HrLOrntPoints(i,4); 
    clmn0 = HrLOrntPoints(i,5);
    Step = StepSampleFunction( Scale );
    
%-------------- Neighborhood in new coord -------------% 
% new coordinates received from old ones by rotation, and shift by [ row0, clmn0 ]
    mx  = max( ceil(2*NOfWindows*Step), round(3*Scale) + 1 );
    ind = -mx:mx;
    % pay attention, that coordinates are taken in column-major order, so
    % assignments below of Patch is consistent
    [ Clmn, Row ] = meshgrid( ind, ind );
    % tmp2 need to be >= 4*NOfWindows, in order to descript point after
    % mx, that was choosen before, provide this
    tmp2 = 2*mx + 1; tmp = tmp2^2;
    Coord_new = zeros( tmp, 2 );
    Coord_new( :, 2 ) = Row(:);
    Coord_new( :, 1 ) = Clmn(:);
    Coord_new = Coord_new';
    
%------ Converting coordinates to original form -------%
    Rotation = [ cos(MainOrient) -sin(MainOrient); sin(MainOrient) cos(MainOrient) ];
    % Coord_orig(1,:) - column coord, that correspond to Coord_new( 1, : ).
    % Coord_orig(2,:) - rows ...
    Coord_orig = round( (Rotation)*Coord_new + repmat( [ clmn0 row0 ]', 1, tmp ) );
    
%---------- Converting to linear indexes  -------------%
    IndOfRotatedPatch = sub2ind( [ Nrow, Nclmn ], Coord_orig( 2,: )', Coord_orig( 1,: )' ); 

%---------- Assigning values to the patch  -------------%
    Patch = zeros( tmp2 );
    Patch(:) = img( IndOfRotatedPatch );
    
%------------------ Derivative mask -------------------%
    ind = -round(3*Scale):round(3*Scale);
    [ X, Y ] = meshgrid( ind, ind );
    dGdx = -X .* exp(-( X.*X + Y.*Y )/(2*Scale*Scale)) ./ ((Scale^4)*(2*pi));
    dGdy = -Y .* exp(-( X.*X + Y.*Y )/(2*Scale*Scale)) ./ ((Scale^4)*(2*pi));
    
%----------------- Window derivatives -----------------%
    % also possible to do convolution, cause gaussian symmetric
    Patchx = imfilter(Patch, dGdx, 'same');
    Patchy = imfilter(Patch, dGdy, 'same');

%----------------- Norm of gradients ------------------% 
    gradient_norm = sqrt(Patchx.^2 + Patchy.^2);
    
 %------------- Avaraging norm gradients --------------% 
    g   = fspecial('gaussian',max(1,fix( 6*Scale*Factor )), Scale*Factor);
    gradient_norm = imfilter(gradient_norm, g,  'same');  
    
%----------------- Angles of gradients ----------------% 
    gradient_angles = rad2deg( atan2( Patchy, Patchx ) + pi );
    
%--------- Taking sub-window for description ----------%   
    % I'm taking 'center pixel'( Feature point, with coordinates [ row0, clmn0 ] in image ) to be in
    % new/sub-patch coordinates at [ p, p ]
    % p = round(tmp2/2)
    p = mx + 1;
    % so I'll have patches of size 4*NOfWindows x 4*NOfWindows
    SubPatch_norm  = gradient_norm( max(round( (p  - ( 2*NOfWindows )*Step):Step:(p  + ( 2*NOfWindows -1  )*Step) ), 1), max(round( (p  - ( 2*NOfWindows )*Step):Step:(p + ( 2*NOfWindows -1  )*Step)), 1) );
    SubPatch_angles  = gradient_angles( max(round( (p  - ( 2*NOfWindows )*Step):Step:(p  + ( 2*NOfWindows -1  )*Step) ), 1), max(round( (p - ( 2*NOfWindows )*Step):Step:(p + ( 2*NOfWindows -1  )*Step)), 1) );

%-------------- Assigning angles 2 bins ---------------% 
    [ tmp, AngleBins ] = histc( SubPatch_angles(IndexMaskOfBlocks), Edges4Hist );
    
%---------------- Shifting angle bins -----------------% 
    AngleBinsShifted = AngleBins + IndexShiftBins4Accum;
    
%-------- Accumulating norms 2 according bins ---------%
    DescriptVector = accumarray( AngleBinsShifted, SubPatch_norm(IndexMaskOfBlocks), [ NOfBins*NOfWindows^2, 1 ] );
    DescriptVector = min( DescriptVector/norm(DescriptVector), Thresh );
    DescriptVector = DescriptVector/norm(DescriptVector);
    
%---------------- Assign values 2 matrix --------------%
    DescriptFPVector( i, : ) = (DescriptVector)';
    if strcmp( SwitchWaitbars, 'on' )
    waitbar(i/N)
    end
end
    if strcmp( SwitchWaitbars, 'on' )
    close(h)
    end
        case 'MOP' 
            % left it blank for future /maybe/ filling
            
        case 'N-jets'
            
    end
      
    
