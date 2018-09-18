function [ row, clmn, rowSPA, clmnSPA, MxMtr ] = Findlclmxm( Mtr, NBHOOD, BorderDistance, ThreshType, HarrisThresh )
% Function receives inputs 'Mtr' - matrix of scalar values, NBHOOD -
% information about how to define local region/neighborhood.
% In case if NBHOOD is scalar, then as neighborhood will be taken circle/disk 
% with radius = NBHOOD.
% Otherwise NBHOOD will be a matrix which define neighborhood for looking for
% maximum in this region ( with 0 and 1 ).
% 'row', 'clmn' - row and column vectors of local maximums, 'MxMtr' - 
% matrix of the same dimension as Mtr, but all elements 0, except elements
% [ row, clmn ], they have the same value in those positions as in Mtr.
% If finded maximums near border at distance less then BorderDistance, then
% it'll be illuminated, also maximums values will be threshed./ BorderDistance can be matrix with ones and zeros /
% Also it returns approximation of place (columns, row) of local maximums.


[ m, n ] = size( Mtr );

if isscalar(BorderDistance)
    Tmp = zeros(size(Mtr));
    Tmp( (BorderDistance + 1):(m - BorderDistance), (BorderDistance + 1):(n - BorderDistance) ) = 1;
else 
    Tmp = BorderDistance;
end

MtrTmp = Mtr;
Mtr = Mtr.*Tmp;
MxMtr = zeros(size(Mtr));

% calculate system of neighboors pixels
if isscalar(NBHOOD)
    NBHOOD = fspecial('disk', NBHOOD) > 0;
    N = sum(NBHOOD(:));
else
    N = sum(NBHOOD(:));
end

local_mxm = ordfilt2( Mtr, N, NBHOOD );
local_second_value = ordfilt2( Mtr, N-1, NBHOOD );

%------------------- Find thresh  ---------------------%
switch ThreshType
    case 'percent'
        T = HarrisThresh*max(local_mxm(:));
    case 'const'
        T = HarrisThresh;
end
  

% indexes of strict local maximums, threshed and filterd for distance from
% borders
ind =  find( (Mtr == local_mxm)  &  (local_second_value ~= local_mxm) & ( Mtr >= T ) );

% MxMtr(ind) = Mtr(ind);
ind = ind(:);
%[ row, clmn ] = ind2sub( [ m, n ], ind );

% defining sub-pixel accuracy
%----------------- Derivative masks  ------------------%
dFdx = [ 0 0 0; -1 0 1; 0 0 0];
dFdy = [ 0 -1 0; 0 0 0; 0 1 0 ];
d2Fdx2 = [ 0 0 0; 1 -2 1; 0 0 0 ];
d2Fdy2 = [ 0 1 0; 0 -2 0; 0 1 0 ];
d2Fdxdy = [ 1 0 -1; 0 0 0; 1 0 -1 ]/4;

%-------------------- Derivatives ---------------------%
Fx = imfilter( MtrTmp, dFdx, 'same' );
Fy = imfilter( MtrTmp, dFdy, 'same' );
Fxx = imfilter( MtrTmp, d2Fdx2, 'same' );
Fyy = imfilter( MtrTmp, d2Fdy2, 'same' );
Fxy = imfilter( MtrTmp, d2Fdxdy, 'same' );

%----------- Column sub-pixel accuracy (SPA) ----------%
% formula is taken from MOP paper ( multiscale oriented patches )
ind = ind(( Fxx(ind).*Fyy(ind)-(Fxy(ind)).^2 ) ~= 0);
ClmnDeltaX = (Fx(ind).*Fyy(ind)-Fxy(ind).*Fy(ind))./( Fxx(ind).*Fyy(ind)-(Fxy(ind)).^2 );

%-------------- Row sub-pixel accuracy ----------------%
RowDeltaY = (Fy(ind).*Fxx(ind)-Fxy(ind).*Fx(ind))./( Fxx(ind).*Fyy(ind)-(Fxy(ind)).^2 );

%---- Removing pixels, that can't be approximated -----%
ind2 = find( abs(RowDeltaY)<= 1 & abs(ClmnDeltaX)<= 1 );
ind = ind( ind2 ); [ row, clmn ] = ind2sub( [ m, n ], ind ); 
rowSPA = row - RowDeltaY( ind2 ); clmnSPA = clmn - ClmnDeltaX( ind2 ); MxMtr(ind) = Mtr(ind); 