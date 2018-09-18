% APM Web-Interface Commands     
function response = apm_t0(server,app,mode)
   % imode = model
   % 1 = ss
   % 2 = mpu
   % 3 = rto
   % 4 = sim
   % 5 = mhe
   % 6 = nlc
   % get ip address for web-address lookup
   ip = deblank(urlread([deblank(server) '/ip.php']));    
   url = [deblank(server) '/online/' ip '_' app '/' deblank(mode) '.t0'];
   response = urlread(url);
