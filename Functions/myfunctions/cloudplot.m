function h = cloudplot(xdat,ydat,barwd,varargin)
% function h = cloudplot(xdat,ydat,barwd,[markersz,facecolz,edgecolz,lnwd])

%% DEFAULT VALUES

optargs = {36,'k','k',.5};

% Now put these defaults into the valuesToUse cell array, 
% and overwrite the ones specified in varargin.
specif = find(~cellfun(@isempty,varargin)); % find position of specified arguments
[optargs{specif}] = varargin{specif};

% Place optional args in memorable variable names
[markersz,facecolz,edgecolz,lnwd] = optargs{:};

if size(facecolz,1) == 1
    facecolz = repmat(facecolz,size(ydat,2),1);
end

if size(edgecolz,1) == 1
    edgecolz = repmat(edgecolz,size(ydat,2),1);
end

%%

barwd = 2/3*barwd;

for i = 1:size(xdat,2)
    
    X   = (xdat(i)-barwd/2) + barwd*rand(size(ydat,1),1); % deviation from X
    
    h(i) = scatter(X,ydat(:,i),markersz,'MarkerFaceColor',facecolz(i,:),'MarkerEdgeColor',edgecolz(i,:),'LineWidth',lnwd);
end

end

