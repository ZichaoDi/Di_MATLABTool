function [A,sino]=radon(img,thetan)
Tol=1e-2;
omega=[-2     2    -2     2].*Tol;
m=size(img); %Numerical Resolution
dz=[(omega(2)-omega(1))/m(2) (omega(4)-omega(3))/m(1)];
%%% +++set up experimental configuration+++++++++++++
alpha=atan((omega(4)-omega(3))/(omega(2)-omega(1)));
Tau= omega(2)-omega(1);
nTau=m(1);% % number of discrete beam%nTau;%
tol1=1/2*m(1);
numThetan=length(thetan);
%=============initiate transmission detector location
detS0=[Tau/2*tan(alpha)+tol1*dz(1),-Tau/2-tol1*dz(1)];
detE0=[Tau/2*tan(alpha)+tol1*dz(1),Tau/2+tol1*dz(1)];
% dTau=abs(-Tau-2*tol1*dz(1))/(nTau);%%% width of each discrete beam
knot=linspace(detS0(2),detE0(2),nTau)';
DetKnot0=[repmat(detS0(1),size(knot)),knot];%% transmission detectorlet knot points
SourceS0=[-Tau/2*tan(alpha)-tol1*dz(1),-Tau/2-tol1*dz(1)];%initiate beam source
SourceE0=[-Tau/2*tan(alpha)-tol1*dz(1),Tau/2+tol1*dz(1)];

knot=linspace(SourceS0(2),SourceE0(2),nTau)';
SourceKnot0=[repmat(SourceS0(1),size(knot)),knot];%% source knot points
%%%+++++++++++++++++++++++++++++++++++++++++++++++++++++
%%%++++++++ Set up sample +++++++++++++++++++++++++++
x=linspace(omega(1),omega(2),m(1)+1);
y=linspace(omega(3),omega(4),m(2)+1);

%%%=========== assign weight matrix for each element in each pixel
%% +++++++++++++++++++++++++++++++++++++++++++++++++++++++
eX=ones(m(1),1);
eY=ones(m(2),1);
sino=zeros(numThetan,nTau);
A=sparse(numThetan*(nTau),prod(m));
for n=1:numThetan
    %% =============== No Probe Drift
    theta = thetan(n)/180*pi;
    TransMatrix=[cos(theta) sin(theta);-sin(theta) cos(theta)];
    DetKnot=DetKnot0*TransMatrix;
    SourceKnot=SourceKnot0*TransMatrix;
    %% =========================================
    Rdis=zeros(1,nTau);
    xbox=[omega(1) omega(1) omega(2) omega(2) omega(1)];
    ybox=[omega(3) omega(4) omega(4) omega(3) omega(3)];
    for i=1:nTau %%%%%%%%%========================================================
        %=================================================================
        [index,Lvec,linearInd]=IntersectionSet(SourceKnot(i,:),DetKnot(i,:),xbox,ybox,theta, x, y, omega, m, dz, Tol);
        %%%%%%%%================================================================
        if(~isempty(index)& norm(Lvec)>0)
            currentInd=sub2ind(m,index(:,2),index(:,1));
            A(sub2ind([numThetan,nTau],n,i),currentInd)=Lvec;
            Rdis(i)=eX'*(img.*reshape(A(sub2ind([numThetan,nTau],n,i),:),m))*eY;
        end

    end
   sino(n,:)=Rdis;
end
%%==============================================================
function [index,Lvec,linearInd]=IntersectionSet(Source,Detector,xbox,ybox,theta, x, y, omega, m, dz, Tol)
[intersects] = intersectLinePolygon([Source(1) Source(2) Detector(1)-Source(1) Detector(2)-Source(2)], [xbox',ybox']);
Ax=intersects(:,1);Ay=intersects(:,2);
if(isempty(Ax) | length(unique(Ax))==1 & length(unique(Ay))==1)
    % fprintf('no intersection \n')
    index=[];
    Lvec=[];
    linearInd=[];
else
    A=unique([Ax,Ay],'rows');Ax=A(:,1);Ay=A(:,2);
    if(theta==pi/2)
        Q=[repmat(Ax(1),size(y')),y'];
    elseif(theta==0 | theta==2*pi)
        Q=[x',repmat(Ay(1),size(x'))];
    elseif(theta==pi)
        Q=[x(end:-1:1)',repmat(Ay(1),size(x'))];

    elseif(theta==3*pi/2)
        Q=[repmat(Ax(1),size(y')),y(end:-1:1)'];
    else
        Q=[[x', (Ay(2)-Ay(1))/(Ax(2)-Ax(1)).*x'+(Ay(1)*Ax(2)-Ay(2)*Ax(1))/(Ax(2)-Ax(1))];...
            [(y'-(Ay(1)*Ax(2)-Ay(2)*Ax(1))/(Ax(2)-Ax(1)))./((Ay(2)-Ay(1))/(Ax(2)-Ax(1))),y']];
    end
    indx=find(Q(:,1)-xbox(1)<-1e-6*Tol |Q(:,1)-xbox(3)>1e-6*Tol); 
    indy=find(Q(:,2)-ybox(1)<-1e-6*Tol |Q(:,2)-ybox(2)>1e-6*Tol);
    Q=setdiff(Q,Q([indx;indy],:),'rows');
    Q=unique(Q,'rows');
    Lvec=sqrt((Q(2:end,1)-Q(1:end-1,1)).^2+(Q(2:end,2)-Q(1:end-1,2)).^2);
    %%%%%%%%%================================================================
    QC=(Q(1:end-1,:)+Q(2:end,:))/2;
    index=floor([(QC(:,1)-omega(1))/dz(1)+1, (QC(:,2)-omega(3))/dz(2)+1]);
    indInside=find(index(:,1)>0 & index(:,1)<=m(2)& index(:,2)<=m(1) & index(:,2)>0);
    index=index(indInside,:);
    % [index,subInd]=unique(index,'rows');
    Lvec=Lvec(indInside);
    % Lvec=Lvec(subInd);
    linearInd=sub2ind(m,index(:,2),index(:,1));
end
