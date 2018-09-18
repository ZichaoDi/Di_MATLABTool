function im = imscale(im,scl,cut)
% Scale matrix im to a given range (default: 0~255)

if nargin < 3
    cut = [-inf inf];
    if nargin < 2
        scl = 255;
    end
end
im((im < cut(1)) | (im > cut(2))) = nan;
m_max = max(im(:));
m_min = min(im(:));
im = (im-m_min)/(m_max-m_min)*scl;
end
