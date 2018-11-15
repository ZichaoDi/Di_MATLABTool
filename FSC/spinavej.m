function output=spinavej(f)
% function output=spinave(f)
% Puts spin (angular) average of square array (about center) into output
% Note: index is true index +1 (so zero radius is 1)
% For small arrays computes by-pixel way
% For large arrays computes by-index way,
%    uses precomputed indices for by-index way for 256x256 to 1024x1024
% J.R. Fienup 9/14/01

if ndims(f)==2,
    [nr,nc]=size(f);
    nrdc=fix(nr/2)+1; ncdc=fix(nc/2)+1;
    r=[1:nr]-nrdc; c=[1:nc]-ncdc;
    [R,C]=ndgrid(r,c);
    index=round(sqrt(R.^2 + C.^2))+1;
elseif ndims(f)==3,
    [nr,nc,nz]=size(f);
    nrdc=fix(nr/2)+1; ncdc=fix(nc/2)+1; nzdc=fix(nz/2)+1;
    r=[1:nr]-nrdc; c=[1:nc]-ncdc; z=[1:nz]-nzdc;
    [R,C,Z]=ndgrid(r,c,z);
    index=round(sqrt(R.^2 + C.^2 + Z.^2))+1;
else,
    error('need 2D or 3D data for spinave');
end
maxindex=max(max(index));

if nr>=512 & (nr~=512 & nc~=512) & (nr~=1024 & nc~=1024)
    % do the original (by-pixel) way which is faster for the very large cases
    % other wise do the faster by-index way
    sumf=zeros(1,maxindex);
    count=zeros(1,maxindex);
    for ri=1:nr, for ci=1:nc,
        sumf(index(ri,ci))=sumf(index(ri,ci))+f(ri,ci);
        count(index(ri,ci))=count(index(ri,ci))+1;
    end;end

    for ni=1:maxindex,
        if count(ni)~=0., output(ni)=sumf(ni)/count(ni);
        else output(ni)=0.
        end
    end
    disp('performed by-pixel way');
else,
    % by-index way:
    output=zeros(1,maxindex);


    %       if nr==256 & nc==256,
    %           load('spinaveINDS256')
    %       elseif nr==512 & nc==512,
    %           load('spinaveINDS512')
    %       elseif nr==1024 & nc==1022,
    %           load('spinaveINDS1024')
    %       else
    for indi=1:maxindex,
        spinaveINDS(indi)={find(index==indi)};
    end
    %   end
    % to create and save an index for a given size, uncomment the following
    % keyboard; % here type in save spinaveINDSxxxx spinaveINDS
    % end of creation section

    for indi=1:maxindex,
        ind=spinaveINDS{indi};
        output(indi)=sum(f(ind))/length(ind);
    end
    disp('performed by-index way')

end; % of if nr>=512...



