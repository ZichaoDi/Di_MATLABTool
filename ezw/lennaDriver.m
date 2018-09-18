clear;clf

N = 256;
I = readbin('lenna.256',N,N);

h = daubcqf(8,'min');
LEVEL = 6;
tol = 0.1;
% [I,y,L] = bitStreamGenerator('bitLenna','lenna.256',N,h,LEVEL,tol);
% return

i = 1;
PSNR = [];
for Lr = 600:400:5400

  srcByteStream = readbin('bitLenna',Lr,1);

  name = strcat('lennaFiles/lennaPart',num2str(Lr/100));
  writebin(srcByteStream,name,1,Lr);

  srcBitStream = reshape(de2bi(srcByteStream,8),8*Lr,1);

  header = srcBitStream(1:40);
  LEVEL = bi2de(header(1:4)');
  N = bi2de(header(5:14)');
  T = bi2de(header(15:40));

  h = daubcqf(8,'min');
  [K,yr] = reconstruction(srcBitStream(41:8*Lr),T,N,h,LEVEL);

  figure(i)
  imshow(K,gray(256))

  PSNR = [PSNR;psnr(K,I)];
  i = i+1;
end

return
