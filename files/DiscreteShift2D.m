function y = DiscreteShift2D(x, delta)
[N, M] = size(x);
y=zeros(N,M);
    if(delta(1)>=0)
        y(delta(1)+1:end,:)=x(1:end-delta(1),:);
        % y(1:delta(1),:)=x(end-delta(1)+1:end,:);
    else
        y(1:end+delta(1),:)=x(-delta(1)+1:end,:);
        % y(end+delta(1)+1:end,:)=x(1:-delta(1),:);
    end
    % figure, subplot(1,2,1),imagesc(x);subplot(1,2,2),imagesc(y)
    x=y;
    y=zeros(N,M);
    if(delta(2)>=0)
        y(:,delta(2)+1:end)=x(:,1:end-delta(2));
        % y(:,1:delta(2))=x(:,end-delta(2)+1:end);
    else
        y(:,1:end+delta(2))=x(:,-delta(2)+1:end);
        % y(:,end+delta(2)+1:end)=x(:,1:-delta(2));
    end
    % figure, subplot(1,2,1),imagesc(x);subplot(1,2,2),imagesc(y)
