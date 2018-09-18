clear
clc

% This routine uses MS Word COM server to check spelling in comments.
% It searches each file in the current folder and looks for spelling errors


% User Dictionary
MyDictionary = {'nrow','ncol','nobs','ndraws','niter','nreg','nstate','nseries',...
    'hangqian','qian','matlabist','gmail',...
    'logL','param','config','Mdl','betta','Innov',...
    'Lyapunov','Schur','fixcoeff','fixdata','triangularize','triangularization',...
    'reparameterization','noninformative','nonspherical',...
    'params','reparameterize','reparameterizing',...
    'dist','getts','Geweke','ssest','identifiability','coeff','iter',...
    'cumulant','Aineq','bineq','Abig','xlsx','Nelder','ssdirect',...
    'const','orthogonalize','doest','didn','exponentiated',...
    'isinfo','centraldiff','href','varT','covariances','MLEs',...
    'preallocate','Hausman','frequentist','poisson',...
    'equicorrelated','cointegrated'};
MyDictionary = lower(MyDictionary);

% Skip checking these folders and their subfolders
SkipFolders = {'mex Backup'};

% Explore three-level subfolders, including the current folder itself
subfolder = cell(100,1);
subfolder{1} = '.';
count = 1;
folderL1 = dir;
for L1 = 1:length(folderL1)
    % Enter the first level folder
    if folderL1(L1).isdir && ~strcmp(folderL1(L1).name,'.') && ~strcmp(folderL1(L1).name,'..')        
        count = count + 1;
        subfolder{count} = folderL1(L1).name;
        folderL2 = dir(subfolder{count});
        for L2 = 1:length(folderL2)
            % Enter the second level folder
            if folderL2(L2).isdir && ~strcmp(folderL2(L2).name,'.') && ~strcmp(folderL2(L2).name,'..')
                count = count + 1;
                subfolder{count} = fullfile(folderL1(L1).name,folderL2(L2).name);
                folderL3 = dir(subfolder{count});
                for L3 = 1:length(folderL3)
                    % Enter the third level folder
                    if folderL3(L3).isdir && ~strcmp(folderL3(L3).name,'.') && ~strcmp(folderL3(L3).name,'..')
                        count = count + 1;
                        subfolder{count} = fullfile(folderL1(L1).name,folderL2(L2).name,folderL3(L3).name);                        
                    end
                end                    
            end
        end        
    end
end
nfolder = count;
subfolder = subfolder(1:nfolder);           
  

% Config MS Word COM server
H = actxserver('word.application');
H.Document.Add;

% Check each m file in the subfolder (and the current folder itself)
for s = 1:nfolder
    
    % Skip folders
    skipFlag = false;
    for ss = 1:length(SkipFolders)
        if strcmp(SkipFolders{ss},subfolder{s}) ...
                || strncmp([SkipFolders{ss},'\'],subfolder{s},length([SkipFolders{ss},'\']))
            skipFlag = true;
            break
        end
    end
    if skipFlag
        continue
    end
    
    fileAIO1 = dir(fullfile(subfolder{s},'*.m'));
    fileAIO2 = dir(fullfile(subfolder{s},'*.c'));
    fileAIO3 = dir(fullfile(subfolder{s},'*.xml'));
    fileAIO4 = dir(fullfile(subfolder{s},'*.txt'));
    fileAIO5 = dir(fullfile(subfolder{s},'*.tex'));
    fileAIO = [fileAIO1;fileAIO2;fileAIO3;fileAIO4;fileAIO5];
    nfile = length(fileAIO);
    for r = 1:nfile
        passFlag = 1;
        filename = fullfile(subfolder{s},fileAIO(r).name);
        fid = fopen(filename,'r');
        if fid == -1
            fprintf('\nUnable to Open the File %s:\n',filename);
            continue
        end
        vecASCII = [13;10; fread(fid,Inf,'*uint8') ; 13;10];
        ENTER_KEY = find(vecASCII==13);
        nline = length(ENTER_KEY) - 1;
        
        if strcmp(subfolder{s},'.')
            fprintf('\nChecking File %s:\n',filename(3:end));
        else
            fprintf('\nChecking File %s:\n',filename);
        end
        
        % Find out file extension
        if ~isempty(strfind(filename,'.m'))
            fileExt = 'MATLAB';
        elseif ~isempty(strfind(filename,'.c'))
            fileExt = 'C';
        elseif ~isempty(strfind(filename,'.xml'))
            fileExt = 'XML';
        elseif ~isempty(strfind(filename,'.txt'))
            fileExt = 'TXT';
        elseif ~isempty(strfind(filename,'.tex'))
            fileExt = 'TEX';     
        else
            fileExt = 'Unknown';
        end            
        
        % Find out variable names in the file (imprecise searching)
        varlist = cell(100,1);
        count = 1;
        for m = 1:nline
            val = vecASCII(ENTER_KEY(m)+2:ENTER_KEY(m+1)-1)';
            txt = native2unicode(val);
            loc = strfind(txt,'=');
            if isempty(loc)
                continue
            end
            variable = strtrim(txt(1:loc-1));
            if isempty(strfind(variable,char(32))) && isempty(strfind(variable,'('))                    
                varlist{count} = variable;
                count = count + 1;
            end
            
            if strfind(txt,'function ')
                loc1 = strfind(txt,'(');
                loc2 = strfind(txt,')');
                if isempty(loc1)
                    continue
                end
                txtUse = [',' txt(loc1+1:loc2-1) ','];
                locComma = strfind(txtUse,',');
                for n = 2:length(locComma)
                    variable = strtrim(txtUse(locComma(n-1)+1:locComma(n)-1));
                    varlist{count} = variable;
                    count = count + 1;
                end
            end
        end        
        varlist = varlist(1:count-1);
        
        % Check each line in the file
        for m = 1:nline
            
            printLine = 1;
            val = vecASCII(ENTER_KEY(m)+2:ENTER_KEY(m+1)-1)';
            txt = native2unicode(val);
            
            if isempty(txt)
                continue
            end
            
            % Looking for comments symbols
            switch fileExt
                case 'MATLAB'
                    loc = [strfind(txt,'%') + 1,...
                        strfind(txt,'disp(') + 5,...
                        strfind(txt,'error(') + 6,...
                        strfind(txt,'warning(') + 8,...
                        strfind(txt,'fprintf(') + 8,...
                        strfind(txt,'sprintf(') + 8];
                case 'C'
                    loc = [strfind(txt,'/*') + 2, strfind(txt,'//') + 2];                    
                case 'XML'
                    loc = strfind(txt,'">') + 1;
                case 'TXT'
                    loc = 1;
                case 'TEX'
                    loc = 1;
                otherwise
                    continue
            end
            
            if isempty(loc)
                continue
            end
            loc = sort(loc);
            loc = loc(1);
            
            % Extract the text
            txt = txt(loc:end);            
            txt = strtrim(txt);
            txtPrint = txt;
            
            % Separate punctuation by a white space
            txt = strrep(txt,'.',' . ');
            txt = strrep(txt,',',' , ');
            txt = strrep(txt,';',' ; ');
            txt = strrep(txt,':',' : ');
            txt = strrep(txt,'?',' ? ');
            txt = strrep(txt,'!',' ! ');
            txt = strrep(txt,'''',' '' ');
            txt = strrep(txt,'"',' " ');
            txt = strrep(txt,'<',' < ');
            txt = strrep(txt,'>',' > ');
            txt = strrep(txt,'(',' ( ');
            txt = strrep(txt,')',' ) ');
            txt = strrep(txt,'[',' [ ');
            txt = strrep(txt,']',' ] ');
            txt = strrep(txt,'{',' { ');
            txt = strrep(txt,'}',' } ');
            txt = strrep(txt,'@',' @ ');
            txt = strrep(txt,'%',' % ');
            txt = strrep(txt,'#',' # ');
            txt = strrep(txt,'+',' + ');
            txt = strrep(txt,'-',' - ');
            txt = strrep(txt,'=',' = ');
            txt = strrep(txt,'*',' * ');
            txt = strrep(txt,'/',' / ');
            txt = strrep(txt,'^',' ^ ');
            txt = strrep(txt,'~',' ~ ');
            txt = strrep(txt,'|',' | ');            
            txt = [' ',txt,' ']; %#ok<AGROW>
                      
            % Check spelling errors in the comment line
            lastWord = 'MostRecentNeighborWord';
            WhiteSpace = strfind(txt,char(32));
            for n = 2:length(WhiteSpace)
                
                % Locate each word in the comment line
                word = txt(WhiteSpace(n-1)+1:WhiteSpace(n)-1);
                word = strtrim(word);
                
                if ~isempty(word) && all(isletter(word)) && strcmp(word,lastWord)
                    if printLine
                        fprintf('Line %d: %s\n',m,txtPrint);
                        printLine = 0;
                    end
                    fprintf('         %s:  Duplicate word ''%s''\n',word,word);
                    passFlag = 0;
                end
                lastWord = word;
                
                % Skip words shorter than 3 letters
                if length(word) <= 3
                    continue
                end
                
                % Skip variable names
                if any(ismember(word,varlist))
                    continue
                end
                
                % Skip file names
                if exist(word) > 0 %#ok<EXIST>
                    continue
                end
                
                % Look for A-Z (a-z) characters only, skip words containing symbols
                wordASCII = int8(word);
                if ~all((wordASCII>=65 & wordASCII<=90) | (wordASCII>=97 & wordASCII<=122))
                    continue
                end
                
                % Skip words that contain two or more capitalized letter
                wordCapital = wordASCII>=65 & wordASCII<=90;
                if sum(wordCapital) >= 2
                    continue
                end
                
                % Skip camel-style capital words such as numObs and logLike
                if length(wordCapital) > 2 && any(wordCapital(2:end-1))
                    continue
                end                
                
                % Skip words in user dictionary                
                if any(ismember(lower(word),MyDictionary))
                    continue
                end
                
                % Skip capitalized words in C file
                if ~isempty(strfind(filename,'.c')) && any(wordASCII>=65 & wordASCII<=90)
                    continue
                end
                
                % If there is no spelling error, continue
                OK = H.CheckSpelling(word);
                if OK
                    continue
                end
                
                % Indicate misspelled word
                passFlag = 0;
                if printLine
                    fprintf('Line %d: %s\n',m,txtPrint);
                    printLine = 0;
                end
                fprintf('         %s',word);
                
                % Spelling suggestions
                nSuggest = H.GetSpellingSuggestions(word).count;
                if nSuggest == 0
                    fprintf(': No spelling suggestion.\n');
                else
                    fprintf(' -> ');
                    for k = 1:min(5,nSuggest)                        
                        fprintf('%s ',H.GetSpellingSuggestions(word).Item(k).get('name'));                        
                    end
                    fprintf('\n');
                end
            end
        end
        
        if passFlag
            fprintf('Pass!\n')
        end
        fclose(fid);
    end
end
    