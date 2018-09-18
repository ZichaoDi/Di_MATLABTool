function projDelta = calcPhase(I,I0,R2,detLen,detN,type)

% initiate grid size
detSize = detLen/(detN-1);

% number of projections
numberOfViews = size(I0,2);

switch lower(type)
    
    case 'regularized'
        
        % dimension
        Ndim = numberOfViews*detN;
        
        % calculate source
        D = reshape(I-I0,Ndim,1);
        
        % assemble the Laplacian operator
        Q = sparse(1:Ndim,1:Ndim,2*ones(1,Ndim),Ndim,Ndim);
        E = sparse(2:Ndim,1:Ndim-1,-ones(1,Ndim-1),Ndim,Ndim);
        L = (E+Q+E')/detSize^2;
%         L(1,Ndim) = -1/detSize^2;
%         L(1,Ndim) = -1/detSize^2;
        for m = 1:numberOfViews-1
            L(m*detN,m*detN+1) = 0;
            L(m*detN+1,m*detN) = 0;
        end
        
        %         Q = sparse(1:detN,1:detN,2*ones(1,detN),detN,detN);
        %         E = sparse(2:detN,1:detN-1,-ones(1,detN-1),detN,detN);
        %         T = E+Q+E';
%                 R = sparse(1:numberOfViews,1:numberOfViews,ones(1,numberOfViews),numberOfViews,numberOfViews);
        %         tau = kron(T,R);
        
        R = sparse(1:numberOfViews,1:numberOfViews,ones(1,numberOfViews),numberOfViews,numberOfViews);
        T = zeros(detN,detN);
        lambda = 0.9;
        for m = 1:detN
            
            tmp = abs((1:detN)-m);
            T(m,:) = lambda.^tmp';
            
        end
        tau = kron(T,R);
%         itau = 1e-10*tau^-1;
%         
%         I = sparse(1:Ndim,1:Ndim,ones(1,Ndim),Ndim,Ndim);
        
        % calcualte inverse
        G = pcg(L'*L+0*tau,L'*D,1e-12,2000);
        
        % calculate augmenting function
        tmp = 1/R2.*G;
        projDelta = reshape(tmp,detN,numberOfViews);
        
    case 'nugent'
        
        % calculate source
        D = (I-I0);
        
        % assemble the Laplacian operator
        L = (diag(2*ones(1,detN))+diag(-ones(1,detN-1),1)+diag(-ones(1,detN-1),1)')/detSize^2;
        
        % calcualte inverse
        G = pinv(L'*L)*L';
        
        % calculate augmenting function
        psi = 1/R2.*G*D;
        
        % gradient
        delPsi = zeros(detN,numberOfViews);
        for m = 1:numberOfViews
            delPsi(:,m) = gradient(gradient(psi(:,m),detSize)./I0(:,m),detSize);
        end
        
        % calculate delta projections
        projDelta = -G*delPsi;
        
    case 'psi'
        
        % calculate source
        D = (I-I0);
        
        % assemble the Laplacian operator
        L = (diag(2*ones(1,detN))+diag(-ones(1,detN-1),1)+diag(-ones(1,detN-1),1)')/detSize^2;
        
        % calcualte inverse
        G = pinv(L'*L)*L';
        
        % calculate augmenting function
        projDelta = 1/R2.*G*D;
        
    case 'approx'
        
        % calculate source
        D = -(I./I0-1);
        
        % assemble the Laplacian operator
        L = (diag(2*ones(1,detN))+diag(-ones(1,detN-1),1)+diag(-ones(1,detN-1),1)')/detSize^2;
        
        % calcualte inverse
        G = pinv(L'*L)*L';
        
        % calculate delta projections
        projDelta = -1/R2.*G*D;
        
    case 'freqnugent'
        
        % calculate source
        D = (I./I0-1);
        
        % take inverse Fourier transform of data
        fftD = fftshift(fft(D,[],1));
        
        % frequency sampling
        u = 2*pi./detLen*(-(detN-1)/2:(detN-1)/2);
        
        % filter
        w2 = 1000;
        H = 1./(R2.*((u.^2+w2).^2./u.^2));
        
        % calc proj
        projDelta = real(ifft(fftshift(repmat(H',1,numberOfViews).*fftD),[],1));
        
    case 'freq'
        
        % calculate source
        D = (I./I0-1);
        
        % take inverse Fourier transform of data
        fftD = fftshift(fft(D,[],1));
        
        % frequency sampling
        u = 2*pi./detLen*(-(detN-1)/2:(detN-1)/2);
        
        % filter
        H = 1./(R2.*u.^2);
        
        % calc proj
        projDelta = real(ifft(fftshift(repmat(H',1,numberOfViews).*fftD),[],1));
        %         projDelta = projDelta-repmat(projDelta(1,:),detN,1);
        
end
end









