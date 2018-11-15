% [FSC T] = fourier_shell_corr(img1,img2,dispfsc,SNRt,fig,hold_on)
% Computes the Fourier shell correlation between img1 and img2. It can also
% compute the threshold function T. Images can be complex-valued.
% dispfsc = 1;  % Display results
% SNRt          % Power SNR for threshold, popular options:
                % SNRt = 0.5; 1 bit threshold for average
                % SNRt = 0.2071; 1/2 bit threshold for average
%M. van Heela, and M. Schatzb, "Fourier shell correlation threshold
%criteria," Journal of Structural Biology 151, 250-262 (2005)
% Manuel Guizar 19-Apr-2011
function [FSC T] = fourier_shell_corr(img1,img2,dispfsc,SNRt,fig,hold_on)

if any(size(img1) ~= size(img2))
    error('Images must be the same size')
end

if size(img1,1) ~= size(img1,2)
    error('Images must be square')
end

if ~exist('dispfsc')
    dispfsc = 0;
end

if ~exist('fig')
    fig = 1;
end

if ~exist('hold_on')
    hold_on = 0;
end

F1 = fftshift(fft2(img1));
F2 = fftshift(fft2(img2));

C = spinavej(F1.*conj(F2));
C1 = spinavej(F1.*conj(F1));
C2 = spinavej(F2.*conj(F2));
FSC = abs(C)./(sqrt(C1.*C2));

if exist('SNRt')
    r = [0:size(F1,1)/2];
    n = 2*pi*r;
    n(1) = 1;
    T = (  SNRt + 2*sqrt(SNRt)./sqrt(n+eps) + 1./sqrt(n)  )./...
        (  SNRt + 2*sqrt(SNRt)./sqrt(n+eps) + 1  );
end

if dispfsc
    figure(fig);
    if (hold_on == 1) hold on; end        
    plot([0:size(C,2)-1]/(size(F1,2)/2),FSC,'Linewidth',1);
    if exist('SNRt')
        hold on,
        plot(r/(size(F1,2)/2),T,'--r','Linewidth',1);
        hold off,
        if SNRt == 0.2071,
            legend('FSC','1/2 bit threshold')
        elseif SNRt == 0.5,
            legend('FSC','1 bit threshold')
        else
            legend('FSC',['Threshold SNR = ' num2str(SNRt)]);
        end
    else
        legend('FSC')
    end
    % xlim([0 1])
    ylim([0 1.1])
    xlabel('Spatial frequency/Nyquist')
    
end
