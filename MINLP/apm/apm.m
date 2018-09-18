% APM Web-Interface Commands     
function response = apm(server,app,aline)

    % Web-server URL base
    url_base = [deblank(server) '/online/apm_line.php'];

    % Send request to web-server
    params = {'p',app,'a',aline};
    response = urlread(url_base,'get',params);

    % remove newline characters from response
    newline = sprintf('\r');
    response = strrep(response,newline,'');
