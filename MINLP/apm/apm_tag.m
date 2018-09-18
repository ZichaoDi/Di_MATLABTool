% APM Web-Interface Commands     
function response = apm_tag(server,app,name)

    % Web-server URL base
    url_base = [deblank(server) '/online/get_tag.php'];

    % Send request to web-server
    params = {'p',app,'n',name};
    response = str2num(urlread(url_base,'get',params));
