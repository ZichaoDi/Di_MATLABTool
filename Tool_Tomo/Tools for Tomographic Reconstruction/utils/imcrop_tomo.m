function im_crop = imcrop_tomo(im,sz)
% Here im is a reconstructed image which is a D-by-D matrix, and sz is the
% size of the original image.

D = size(im,1);
m = sz(1);
n = sz(2);
m_pad = floor((D-m)/2);
n_pad = floor((D-n)/2);
im_crop = im(m_pad+1:m_pad+m,n_pad+1:n_pad+n);
end
