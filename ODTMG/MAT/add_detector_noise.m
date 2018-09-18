function [meas, snr]=add_detector_noise(S, alpha, meas_noiseless)

for s=1:S,
  mag=abs(meas_noiseless(s,1)+i*meas_noiseless(s,2));
  meas(s,1) = meas_noiseless(s,1) + sqrt(0.5*alpha*mag)*randn;
  meas(s,2) = meas_noiseless(s,2) + sqrt(0.5*alpha*mag)*randn;
  snr(s)=1./alpha*mag;
end

