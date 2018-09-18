% Load CSV File
function [response] = csv_load(server,app,filename)
   % load model
   fid=fopen(filename,'r');
   tline = [];
   while 1
      aline = fgets(fid);
      if ~ischar(aline), break, end
      % remove any double quote marks
      aline = [strrep(aline,'"',' ')];
      tline = [tline aline];
   end
   fclose(fid);

   % send to server once for every 5000 characters
   ts = size(tline,2);
   block = 5000;
   cycles = ceil(ts/block);
   for i = 1:cycles,
      if i<cycles,
         csv_block = ['csva ' tline((i-1)*block+1:i*block)];
      else
         csv_block = ['csv ' tline((i-1)*block+1:end)];
      end       
      response = apm(server,app,csv_block);
   end
   response = 'Successfully loaded CSV file';
      
