function im_rec = tomo_reconstruction_fbp(projmat_bp,angles,show_animation)
%  Tomographic reconstruction using Filtered Back Projection (FBP) 
%   algorithm.
%
%   05-Aug-2013 17:23:35
%   hanligong@gmail.com

if nargin < 3
    show_animation = false;
else
    figure('name','FBP')
end
[n_proj,D] = size(projmat_bp);
if length(angles) ~= n_proj
    fprintf('Size of proj_mat is incorrect.\r')
    im_rec = [];
    return
end
im_rec = zeros(D);
for k = 1:n_proj
    proj_vec = hpf(projmat_bp(k,:));
    im_rot = repmat(proj_vec/D,D,1);
    im_rot = imrotate(im_rot, angles(k), 'bilinear', 'crop');
    im_rec = im_rec+im_rot/n_proj;
    %DEBUG
    if show_animation
        imshow(uint8(imscale(im_rec)))
        pause(0.01)
    end
    % %
end
end
