function [tval] = ttransform(xdat,varargin)
% function [tval] = ttransform(xdat,compval)
%
% Transform data to t-values.
%
% Input:
%   - xdat: sub (x time x ...)
%   - [compval]: value to compare in ttest
%
% Output:
%   - tval: matrix of t-values
%
% Fabrice Luyckx, 22/9/2018

%% DEFAULT VALUES

optargs = {0};

% Now put these defaults into the valuesToUse cell array, 
% and overwrite the ones specified in varargin.
specif = find(~cellfun(@isempty,varargin)); % find position of specified arguments
[optargs{specif}] = varargin{specif};

% Place optional args in memorable variable names
[compval] = optargs{:};

%% Calculate t-values

% Get size of input
sz          = size(xdat);
nsub        = sz(1);
allLoops    = fullfact(sz(2:end));
nloops      = size(allLoops,1);

newX        = reshape(xdat,[nsub,nloops]);
tval        = nan(nloops,1);

for f = 1:nloops
    [~,~,~,stats]   = ttest(newX(:,f),compval);
    tval(f)         = stats.tstat;
end

if length(sz) > 2
    tval = reshape(tval,sz(2:end));
end

end

