% APM Web-Interface Commands     
function solution = apm_sol(server,app)
   filename = 'solution.csv';
   % get ip address for web-address lookup
   ip = deblank(urlread([deblank(server) '/ip.php']));    
   url = [deblank(server) '/online/' ip '_' app '/results.csv'];
   response = urlread(url);
   % write solution.csv file
   fid = fopen(filename,'w');
   fwrite(fid,response);
   fclose(fid);
   % tranfer solution to local array
   % load data from csv file with header on the right column
   fid = fopen(filename, 'r');
   % Parse and read rest of file
   ctr = 0;
   while(~feof(fid))
      aline = fgetl(fid); 
      if ischar(aline) 
         ctr = ctr + 1;
         A(ctr,:) = parse(aline, ','); 
      else
         break; 
      end
   end
   fclose(fid);
   [n,m] = size(A);
   for i = 1:n,
     for j = 2:m,
        A{i,j} = str2num(A{i,j});
     end
   end
   solution = A';