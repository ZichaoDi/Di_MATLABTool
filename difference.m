function [psnr_, psnrSparse, snr, angle] = difference(X, REF, relativeThreshold)
%Compare the difference between a matrix/vector X and its reference REF
% [psnr_, psnrSparse, snr, angle] = difference(X, REF, relativeThreshold)
%
% Let =a, b=b and c=a-b.
% Then a, b, c are three edges that form a triangle in high dimension space
% Denote the length of the three edges by |a|, |b| and |c|, and N as the dimension of the vector a/b/c.
%
% Inputs:
%   X:           nD array to check
%   REF:         nD reference array
%   relativeThreshold:   only used in computing psnrSparse, set the relative relativeThreshold to count the real meansing fully elements
% Outputs:
%   psnr_:       Similar to conventional PSNR, the (actual) peak signal power divide by MSE in dB, i.e., 10*log10(max(REF(:).^2) / mean((X(:)-REF(:)).^2);
%   psnrSparse:  Similar to psnr_, but MSE is the total squared error normalized by number of non-zeros (>relativeThreshold*max(REF(:))) 
%                in REF, rather than the total number of elements in REF.
%   snr:        signal to noise ratio in dB, the mean signal power divided by MSE in dB, i.e.,  10*log10(mean(REF(:).^2) / mean((X(:)-REF(:)).^2);
%               NOTE:  there is no snrSpare, or snrSpare is same as snr, as it doesn't matter whether the total signal power 
%               and total squared error are BOTH normalized by the total number of elements, or the total number of non-zeros.
%   angle:      the angle between edge a and b in triangle abc, range from [0, 180]
%         It only compares to the directional similarity of a and b, and doesn't depend on their length/energy.
%


%   2010.10.25 generated
%   2013.05.06_modified to compute root-mean-square error (rmse) and relative root-mean-square deviation or error
%   2016.01.28_extended for complex matrix
%   2016.04.13_added the angle between two normalized vector.
%   2016.04.14_added the geometric meaning, the trianglular explaination
%   2016.11.13_added psnr_ and psnrSparse
%  2010-2016 Copyright Xiang Huang xianghuang@gmail.com
% http://en.wikipedia.org/wiki/Root-mean-square_deviation
% see also normxcorr2() Normalized 2-D cross-correlation


% echo off

if ~exist('relativeThreshold', 'var') || isempty(relativeThreshold)
    relativeThreshold = eps;
end

if isreal(X) && isreal(REF)
    % (I). Convert to double precision if original input is not floating point (interger, logic etc)
    if ~isfloat(X)
        X = double(X);
    end
    if ~isfloat(REF)
        REF = double(REF);
    end
    N = numel(X);   
    % (II). Compute the length of the two edges
    xL = sqrt(sum(X(:).^2));
    refL = sqrt(sum(REF(:).^2));
    if refL < eps*numel(X)*1e2
        if xL < eps*numel(X)*1e2
            fprintf('X and REF are both close to 0, with length ||X(:)||=%.2e, and ||REF(:)||= %.2e.\n', xL, refL);
        else
            fprintf('Cannot compare X(:) of length %.2e with a reference(:) of almost zero length: %.2e.\n', xL, refL);
        end
        psnr_=NaN; psnrSparse=NaN; snr=NaN; angle = NaN;
        return
    end
    % (II). Compute psnr snr for original and sparse
    mse_ = sum((X(:)-REF(:)).^2)/N;    
    maxAB = max(REF(:)); %maxAB = max(max(X(:)), max(REF(:)));
    psnr_ = 10*log10(maxAB^2/mse_);
    Ns = nnz(REF>relativeThreshold*max(REF(:))); % only include non-zero elements of reference object
    %Ns = nnz(abs(REF)>relativeThreshold*max(abs(REF(:)))); % only include non-zero elements of reference object % 2017.08.02_change to abs
    %idx = abs(X)>relativeThreshold | abs(REF)>relativeThreshold; % only include non-zero elements of both objects
    psnrSparse = 10*log10(maxAB^2/(mse_*N/Ns));
    snr = 10*log10((refL^2/N) / mse_); % This is the same as snrSparse = 10*log10(sum(REF(:))^2 / sum((X(:)-REF(:)).^2) = 10*log10((refL^2/Ns)  / (mse_*N/Ns))
    % (III) Compute angle with gemoetric meanings
    angle = acosd(X(:)'*REF(:) / (xL*refL)); % angle = acosd(sum(x/xLen .* ref/refLen));     
    
    if nargout == 0
        fprintf('The psnr is : %.2fdB.\n', psnr_);     
        fprintf('The psnrSparse (total error normalized by number of elements > %.2e*maximum in reference) is : %.2fdB.\n', relativeThreshold, psnrSparse);
        fprintf('The snr is : %.2fdB.\n', snr);
        fprintf('The angle: (range [0, 180] in degree) between two vectorized inputs a and b is : %.2f.\n', angle);                       
    end
else
    if nargout == 0
        disp('------------Real part------------');
        difference(real(X), real(REF));
        disp('------------Image part------------');
        difference(imag(X), imag(REF));
    else
         [psnr_real, psnrSparse_real, angle_real, snr_real] = difference(real(X), real(REF), relativeThreshold);
         [psnr_imag, psnrSparse_imag, angle_imag, snr_imag] = difference(imag(X), imag(REF), relativeThreshold);         
         psnr_ = psnr_real + 1i*psnr_imag;
         psnrSparse = psnrSparse_real + 1i*psnrSparse_imag;
         angle = angle_real + 1i*angle_imag;
         snr = snr_real + 1i*snr_imag;
         
    end
end
    
% echo on


% Trash code: Won't use any more
%   nrmse: the normalized root-mean-square error, range from [0, 1],  0 when a = b and 1 when a= -b
%         rmse is |c|/(|a|+|b}), i.e., the ratio between error length and data length.
%         nrmse is also |c|/sqrt(N) / (|a|/sqrt(N) + |b|/sqrt(N)), i.e., the ratio between error length and data length
%   rmse: the root mean squared error, i.e., root of average of squares of the difference/error c.
%         rmse is |c|/sqrt(N), i.e., the normalized length of error vector. ( normalized by the square of dimension).
%         rmse makes most of sense when all elements of X/REF are measurement of same random varialbe, so that 
%         MSE is the variance of the difference, and also incopertates the bias: MSE = Var + Bias^2
%         rmse has the same units as the quantity being estimated; For an unbiased estimator, it is the standard deviation (square root of the variance)
%         2016.11.13_replaced by psnr_ = 20*log10(peak/rmse)
 
