function [ HrLPoints ] = harrislpls( img, TypeOfNBHOOD, NBHOOD, TypeOfCornerDetector, BorderDistance, ThreshType, HarrisThresh, k, Dilate, radius, sigma_nmbr, disp, SwitchWaitbars  )
% Function receives intensity image 'img', and returns matrix 'HLPoints'.
% HrLPoints(:,1) and HrLPoints(:,2) are rows and columns respectively of
% Harris-Laplace feature points, and HrLPoints(:,3) their characteristic
% scale. HrLPoints(:,4) and HrLPoints(:,5) are approximation
% of rows and columns respectively. 
% TypeOfNBHOOD - type of searching local maximum for multi-scale Harris
% corner detector. Can be 'const'/'dif'
% If 'const' - scalar or matrix with ones and zeros( see Findlclmxm.m ).
% BorderDistance - scalar that provide that FP woun't be closer to boder 
% then BorderDistance. It also can be amatrix with 1 and 0, of the same
% dimension as image. 1 - at places where can be FP, 0 - otherwise.
% ThreshType - type for taking thresh for Harris corner function/Harmonic Mean.
% ( 'percent'/'const' ). k - parameter for Harris function.
% ( 0.04 - 0.07 )
% Dilate - 'yes'/'no', parameter that turn on/off dilation of final
% results, i.e. if we will receive from all processes FP that they are near ( in disk with provided radius ) one
% of each other, then will be taken only one with higher Harris function value
% in this point ( for each FP with number of char. scales, 
% will be taken Harris function value for last/bigest char. scale  ).
% sigma_nmbr - number of scales to work with ( 4 - 17 )
% disp - 0/1

%------------------- Pre-processing -------------------%

%-------------------- Image params --------------------%
img = double(img);
[ m, n ] = size(img);

%-------------------- Scale params --------------------%
sigma_initial = 1.5; % 1 - 1.5;
sigma_step = 1.2;
% sigma_nmbr = 13;
sigmas_vector = ( sigma_step.^(0:(sigma_nmbr-1)) )*sigma_initial;
S_IandS_DFactor = 0.7;

%--------------------------------- Harris --------------------------------%
HrPoints = zeros(0,5);
HrValues =  zeros( m, n, sigma_nmbr );
if strcmp( SwitchWaitbars, 'on' )
hh = waitbar(0,'Finding Harris-corners: ');
end

for i = 1:sigma_nmbr
%--------------- Find integration scale ---------------%
    S_I = sigmas_vector(i);
    
%--------------- Find derivative scale ----------------%
    S_D = S_IandS_DFactor*S_I;
    
%------------------ Derivative mask -------------------%
    x  = -round(3*S_D):round(3*S_D);
    dx = -x .* exp(-x.*x/(2*S_D*S_D)) ./ (S_D*S_D*S_D*sqrt(2*pi));
    
%----------------- Image derivatives ------------------%
% 'normalized'
    Ix = S_D*(conv2(img, dx, 'same'));
    Iy = S_D*(conv2(img, dx', 'same'));
    
%------------ Window for Harris function --------------%
    g   = fspecial('gaussian',max(1,fix(6*S_I+1)), S_I);
    Ix2 = conv2(Ix.^2, g,  'same');
    Iy2 = conv2(Iy.^2, g,  'same');
    Ixy = conv2(Ix.*Iy, g, 'same'); 
    
%------------------ Harris function -------------------%
switch TypeOfCornerDetector
    case 'Harris'
         HrF = (Ix2.*Iy2 - Ixy.^2) - k*(Ix2 + Iy2).^2;
    case 'HarmonicMean'
         HrF = (Ix2.*Iy2 - Ixy.^2)./(Ix2 + Iy2 + eps); 
    % Threshold in case of Harm. mean, can be taken 10.
end
    
%----------- Find local maximum in window -------------%
switch TypeOfNBHOOD
    case 'const'
     [ row, clmn, rowSPA, clmnSPA, MxMtr ] = Findlclmxm(HrF, NBHOOD, BorderDistance, ThreshType, HarrisThresh );
    case 'dif'
     NBHOOD =  3*S_I; 
     [ row, clmn, rowSPA, clmnSPA, MxMtr ] = Findlclmxm(HrF, NBHOOD, BorderDistance, ThreshType, HarrisThresh ); % or 3/2*S_I
end

%----------- Upgrading values in HrValues -------------% 
if strcmp( Dilate, 'yes' )
    % usefull for later dilation
    if ~isempty(row)
    HrValues( :, :, i ) = MxMtr;
    end
end
%------------ Assign elements to HLPoints -------------% 
    N = length(row);
    if N
       HrPoints(end+1:end+N,:) = [ row, clmn, repmat(i,[N,1]), rowSPA, clmnSPA ];
    end
    if strcmp( SwitchWaitbars, 'on' )
    waitbar(i/sigma_nmbr) 
    end
end
if strcmp( SwitchWaitbars, 'on' )
close(hh)
end

%------------------------------- Laplace ---------------------------------%

%----------- Scale-nomralized lapl. oper. -------------% 
LaplaceScaleNorm = zeros( m, n, sigma_nmbr );
if strcmp( SwitchWaitbars, 'on' )
h = waitbar(0, 'Computation of Laplace-scale-norm. operator:');
end

for i = 1:sigma_nmbr
    Scale = sigmas_vector(i);
    LaplaceScaleNorm(:,:,i) = (Scale^2)*imfilter( img, ( fspecial( 'log', floor( 6*Scale + 1 ), Scale ) ), 'replicate' );
    if strcmp( SwitchWaitbars, 'on' )
    waitbar(i/sigma_nmbr)
    end
end
if strcmp( SwitchWaitbars, 'on' )
close(h)
end

%----------- Finding characteristic scale -------------%  
N = size( HrPoints, 1 );
cnt = 0;
HrLPoints = zeros( N, 5 );
if strcmp( SwitchWaitbars, 'on' )
h = waitbar(0,'Calculating charecteristic scale:');
end

for i = 1:N
    rw =  HrPoints(i,1);
    cl =  HrPoints(i,2);
    Nsc = HrPoints(i,3);
    
    t = LaplaceScaleNorm( rw, cl, Nsc );
    
    switch Nsc
        case 1
            if t  > LaplaceScaleNorm( rw, cl, Nsc + 1 )
            cnt = cnt + 1;
            HrLPoints(cnt,:) = HrPoints(i,:);
            end
        case sigma_nmbr
            if t >  LaplaceScaleNorm( rw, cl, Nsc - 1 )
            cnt = cnt + 1;
            HrLPoints(cnt,:) = HrPoints(i,:);
            end
        otherwise
            if t > LaplaceScaleNorm( rw, cl, Nsc - 1 ) && t > LaplaceScaleNorm( rw, cl, Nsc + 1 )
            cnt = cnt + 1;
            HrLPoints(cnt,:) = HrPoints(i,:);
            end
    end
    if strcmp( SwitchWaitbars, 'on' )
    waitbar(i/N)
    end
end
if strcmp( SwitchWaitbars, 'on' )
close(h)
end
HrLPoints(cnt+1:end,:) = [];

%--------------- Performing dilation ------------------% 
if strcmp( Dilate, 'yes' )
    % number of FP with character. scale
    N = size( HrLPoints, 1 );
    Ind4HrValues = sub2ind( size(HrValues), HrLPoints(:,1), HrLPoints(:,2), HrLPoints(:,3) );
    IndInImage = sub2ind( [ m , n ],  HrLPoints(:,1), HrLPoints(:,2) );
    % will be assigned value for last characteristic scale
    HrValuesInImage = zeros( m, n ); 
    HrValuesInImage( IndInImage ) = HrValues( Ind4HrValues );
    IndexMask = zeros( m, n );
    IndexMask( IndInImage ) = 1:N;
    % define disk of given radius
    NBHOOD = fspecial('disk', radius ) > 0;
    N = sum(NBHOOD(:));
    % find local maximum and second highest value
    local_mxm = ordfilt2( HrValuesInImage, N, NBHOOD );
    local_second_value = ordfilt2( HrValuesInImage, N-1, NBHOOD );
    
    IndLocalMxmFP =  find( (HrValuesInImage == local_mxm)  &  (local_second_value ~= local_mxm) );
    % indexes of rows of HrLPoints
    IndexLocalMxmFPConverted = IndexMask( IndLocalMxmFP );
    HrLPoints(:,3) = sigmas_vector(HrLPoints(:,3));
    HrLPoints = HrLPoints( IndexLocalMxmFPConverted, : );    

else 
   HrLPoints(:,3) = sigmas_vector(HrLPoints(:,3));
end

% displaying
if disp
%     figure,
    imshow(uint8(img)),hold on, plot(HrLPoints(:,2), HrLPoints(:,1),'+r');
    title('FPs of image:')
end
        
        