function [ MatchedPairs ] = matchFPoints( DescriptHrLPoints1, DescriptHrLPoints2, TypeOfSearch, HelpScalarOrVector, TypeOfThresh, Thresh, SwitchWaitbars  )
% Function receives two sets of feature points from two images, and returns indexes of matched points.
% Matrix MatchedPairs will be of dimension: size(MatchedPairs) =  size( DescriptHrLPoints1, 1 ).  
% It means that for point i ( DescriptHrLPoints1(i,:) ) if exist match in the second image then it's index will be 
% MatchedPairs(i), otherwise MatchedPairs(i) = 0.
% In case when TypeOfThresh = 'first/second' ( first math/second match ), Thresh can be taken 0.8.
% Helpscalar - is a scalar for TypeOfSearch.
% In case of 'determ', HelpScalarOrVector = 1 or 2. If 1 - 'regular' methods will be
% used in order to find matches. 2 - function pdist2, from Piotr's matlab
% toolbox will be used.
% I case 'kmeans', HelpScalarOrVector will be a vector of size [ 4, 1 ] or [ 1, 4 ]. HelpScalarOrVector(1) = k,
% HelpScalarOrVector(2) = number of iterations, HelpScalarOrVector(3) -
% number of trials. HelpScalarOrVector(4) - factor, in order to reduce
% density of vectors. It means that if distence between vectors was 1 =>
% after multiplication by factor, it'll be sqrt(factor).


%------------ Number of FP in image 1 -----------------%
N = size( DescriptHrLPoints1, 1 );
MatchedPairs = zeros( 1, N );

%------------ Number of FP in image 2 -----------------%
M = size( DescriptHrLPoints2, 1 );

switch TypeOfThresh
%----------------------------------------------------------------% 
    case 'first'
        
% 'determ', 'kmeans','kNN', 'ANN'
switch TypeOfSearch
%------------------ Strict solution -------------------%  
    case 'determ'
        switch HelpScalarOrVector
            case 1
                if strcmp( SwitchWaitbars, 'on' )
                h = waitbar(0 ,' Calculating nearest neighboor: ');
                end
                for i = 1:N
                    Dist = sqrt(sum(((DescriptHrLPoints2 - repmat(  DescriptHrLPoints1(i,:), M, 1 )).^2),2)); 
                    [ minValues, ind ] = min(Dist);
                    if minValues <= Thresh
                        MatchedPairs(i) = ind;
                    end
                    if strcmp( SwitchWaitbars, 'on' )
                    waitbar(i/N)
                    end
                end
                if strcmp( SwitchWaitbars, 'on' )
                close(h);
                end
            case 2
                Dist = pdist2( DescriptHrLPoints2, DescriptHrLPoints1, 'sqeuclidean' );
                [ minValues ind_first ] = min( Dist ); 
                MatchedPairs = (ind_first(:)).*( (minValues(:)) <= Thresh^2 );
                
        end
%---------------------- kmenas ------------------------% 
% kmeans are used for preclustering, and nearest descriptor is searched
% only in it's own class/cluster.
    case 'kmeans'
        DescriptHrLPoints1Factored = DescriptHrLPoints1*HelpScalarOrVector(4);
        DescriptHrLPoints2Factored = DescriptHrLPoints2*HelpScalarOrVector(4);
        DescriptorsUnited = [ DescriptHrLPoints1Factored', DescriptHrLPoints2Factored' ];
        [ ClusterdDescriptors, C ] = kmeans( DescriptorsUnited', HelpScalarOrVector(1), 'replicates', HelpScalarOrVector(3), 'maxiter', HelpScalarOrVector(2), 'emptyaction', 'drop');
        ClusterDesriptorsImage1 = ClusterdDescriptors(1:N)/HelpScalarOrVector(4);
        ClusterDesriptorsImage2 = ClusterdDescriptors(N+1:end)/HelpScalarOrVector(4);
        if strcmp( SwitchWaitbars, 'on' )
        h = waitbar( 0, ' Calculating nearest neighboor: ' );
        end
        for i = 1:HelpScalarOrVector(1)
            indCluster_iImage1 = find( ClusterDesriptorsImage1 == i );
            indCluster_iImage2 = find( ClusterDesriptorsImage2 == i );
            Dist = pdist2( DescriptHrLPoints2(indCluster_iImage2,:), DescriptHrLPoints1(indCluster_iImage1,:), 'sqeuclidean' );
            [ minValues ind_first ] = min( Dist );
            if ~(isempty(ind_first))
            MatchedPairs( indCluster_iImage1 ) = indCluster_iImage2( ind_first(:) ).*( minValues(:) <= Thresh^2 );
            end
            if strcmp( SwitchWaitbars, 'on' )
            waitbar(i/HelpScalarOrVector(1))
            end
        end
        if strcmp( SwitchWaitbars, 'on' )
        close(h);
        end
    case 'kNN'
     [ neighborIds neighborDistances ] = kNearestNeighbors(DescriptHrLPoints2, DescriptHrLPoints1, 1);
     ind = ( neighborDistances <= Thresh );
     MatchedPairs = (neighborIds.*ind); 
     MatchedPairs = MatchedPairs(:);
    case 'ANN'
        % need to compile ann_wrapper
    anno = ann(DescriptHrLPoints2');
    [idx dst] = ksearch(anno, DescriptHrLPoints1', 1, 0.2, 0) ;
    anno = close(anno);
    MatchedPairs = idx(:).*( dst(:) <= Thresh );
end

%----------------------------------------------------------------%  
    case 'first/second'
     
        
   % 'determ', 'kmeans','kNN', 'ANN'
switch TypeOfSearch
%------------------ Strict solution -------------------%  
    case 'determ'
        switch HelpScalarOrVector
            case 1
                if strcmp( SwitchWaitbars, 'on' )
                h = waitbar(0 ,' Calculating nearest neighboor: ');
                end
                for i = 1:N
                    Dist = sqrt(sum(((DescriptHrLPoints2 - repmat(  DescriptHrLPoints1(i,:), M, 1 )).^2),2)); 
                    [ minValues ind ] = sortrows( Dist, 1 );
                    if minValues(2) & ( (minValues(1)/minValues(2)) <= Thresh )
                        MatchedPairs(i) = ind(1);
                    end
                    if strcmp( SwitchWaitbars, 'on' )
                    waitbar(i/N)
                    end
                end
                if strcmp( SwitchWaitbars, 'on' )
                close(h);
                end
            case 2
                Dist = pdist2( DescriptHrLPoints2, DescriptHrLPoints1, 'sqeuclidean' );
%---------------- Finding min elements ----------------%  
                [  minValues ind_first ] = min( Dist );
                ind_first = ind_first(:);
                minValues = minValues(:);
%----------- Finding second min elements --------------%
                linear_ind_first = M*( 0:1:(N-1) ) + ind_first';
                Dist( linear_ind_first ) = 2;
                [  SecondMinValues ind_second ] = min( Dist );
                SecondMinValues = SecondMinValues(:);
                ind = ( SecondMinValues == 0 );
                SecondMinValues = SecondMinValues + ind(:);
                MatchedPairs =  ind_first.*( minValues./SecondMinValues <= Thresh^2 ).*( ~( ind(:) ) );
        end
%---------------------- kmenas ------------------------% 
% kmeans are used for preclustering, and nearest descriptor is searched
% only in it's own class/cluster.
    case 'kmeans'
        DescriptHrLPoints1Factored = DescriptHrLPoints1*HelpScalarOrVector(4);
        DescriptHrLPoints2Factored = DescriptHrLPoints2*HelpScalarOrVector(4);
        DescriptorsUnited = [ DescriptHrLPoints1Factored', DescriptHrLPoints2Factored' ];
        [ ClusterdDescriptors, C ] = kmeans( DescriptorsUnited', HelpScalarOrVector(1), 'replicates', HelpScalarOrVector(3), 'maxiter', HelpScalarOrVector(2), 'emptyaction', 'drop', 'display', 'iter');
        % it's importent to devide it back, and make them vectors ( each column ) with
        % norm = 1, need for Dist( linear_ind_first ) = 2. 2 - can be
        % minimum, due to triangular inequality ( difference of two vectors witch norm 1 ).
        ClusterDesriptorsImage1 = ClusterdDescriptors(1:N)/HelpScalarOrVector(4);
        ClusterDesriptorsImage2 = ClusterdDescriptors(N+1:end)/HelpScalarOrVector(4);
        if strcmp( SwitchWaitbars, 'on' )
        h = waitbar( 0, ' Calculating nearest neighboor: ' );
        end
        for i = 1:HelpScalarOrVector(1)
            indCluster_iImage1 = find( ClusterDesriptorsImage1 == i ); N1 = length( indCluster_iImage1 );
            indCluster_iImage2 = find( ClusterDesriptorsImage2 == i ); M1 = length( indCluster_iImage2 );
            Dist = pdist2( DescriptHrLPoints2(indCluster_iImage2,:), DescriptHrLPoints1(indCluster_iImage1,:), 'sqeuclidean' );
            [  minValues ind_first ] = min( Dist );
            if ~(isempty(ind_first))
            minValues = minValues(:);
            linear_ind_first = M1*( 0:1:(N1-1) ) + ind_first;
            Dist( linear_ind_first ) = 2;
            [  SecondMinValues ind_second ] = min( Dist );
            SecondMinValues = SecondMinValues(:);
            ind = ( SecondMinValues == 0 );
            SecondMinValues = SecondMinValues + ind;
            MatchedPairs(indCluster_iImage1) =  indCluster_iImage2(ind_first(:)).*( minValues./SecondMinValues <= Thresh ).*( ~( ind ) ); 
            if strcmp( SwitchWaitbars, 'on' )
                waitbar( i/HelpScalarOrVector(1) )
            end
            end
        end
        if strcmp( SwitchWaitbars, 'on' )
        close(h);
        end
        
    case 'kNN'
        [neighborIds neighborDistances] = kNearestNeighbors(DescriptHrLPoints2, DescriptHrLPoints1, 2);
        ind2 = ~( neighborDistances(:,2) == 0 );
        tmp = find( ind2 ~= 0 );
        % all distances, that are 0, I put there 1
        neighborDistances( N + tmp ) = 1;
        ind = (( neighborDistances(:,1)./neighborDistances(:,2) ) <= Thresh) ;
        MatchedPairs = (neighborIds( :, 1 ).*ind.*ind2); 
        
    case 'ANN'
    % need to compile ann_wrapper
    anno = ann(DescriptHrLPoints2');
    [idx dst] = ksearch(anno, DescriptHrLPoints1', 2, 0.08, 0);
    anno = close(anno);
    ind = ( dst( 2, : ) == 0 );
    dst( 2, : ) = dst( 2, : ) + ( ind );
    MatchedPairs = (idx( 1, : )).*( (dst( 1, :)./dst( 2, : )) <= Thresh ).*( ~( ind ) );   
end
     
end
MatchedPairs = MatchedPairs(:);
        