% Open APM Web Viewer
function [stat] = apm_web(server,app)
   % get ip address for web-address lookup
   ip = deblank(urlread([deblank(server) '/ip.php']));
   app = deblank(app);
   url = [deblank(server) '/online/' ip '_' app '/' ip '_' app '_oper.htm'];

   % load web-interface in default browser
   stat = web(url,'-browser');  % doesn't work in some older MATLAB versions

   % display web address and allow the user to click to open
   %%disp(['<a href = "' url '">--- Launch APM Web Interface ---</a>'])
   %%disp([' ' url])