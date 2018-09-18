% APM Web-Interface Commands     
function response = apm_meas(server,app,name,value)

    % Web-server URL base
    name = strcat(name,'.meas');
    params = {'p',app,'n',name,'v',num2str(value)};
    url = [deblank(server) '/online/meas.php'];
    
    % Send request to web-server
    response = urlread(url,'get',params);
