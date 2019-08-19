clear; clc; close all;

% ----- Pixel Well Depth ----- %
quantum_well_depth = 150; % in photoelectrons
% ---------------------------- %

% ----- Image ----- %
camera_man_digital = double(imread('cameraman.tif'));
camera_man_photoelectrons = round(camera_man_digital*quantum_well_depth/2^8);
% ----------------- %

% ----- Shot Noise ----- %
camera_man_shot_noise = poissrnd(camera_man_photoelectrons);
% ---------------------- %

% ----- Read Noise ----- %
sigma_read = 15; % photoelectrons RMS
camera_man_shot_noise_read_noise = camera_man_shot_noise ...
    + sigma_read*randn(size(camera_man_shot_noise));
% ---------------------- %

figure; 
subplot(2,2,[1 2]);
imagesc(camera_man_digital); colormap(gray); axis image; colorbar;
title('Original Image');
subplot(223);
imagesc(camera_man_shot_noise); colormap(gray); axis image; colorbar;
title('Shot Noise');
subplot(224);
imagesc(camera_man_shot_noise_read_noise); colormap(gray); axis image; colorbar;
title('Shot Noise + Read Noise');
