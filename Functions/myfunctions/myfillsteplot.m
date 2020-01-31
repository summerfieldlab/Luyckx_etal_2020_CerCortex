function h = myfillsteplot(xdat,ydat,varargin)
% h = myfillsteplot(xdat,ydat,[colz],[lnwid],[linez],[shade])
%
% Function to plot time series data with continuous confidence interval.
% myfillsteplot will average over the FIRST dimension.
% If ydat has 3 dimension, it will plot the 3rd dimension separately on the same plot.
%
% Input:
%   - xdat: x-ticks data
%   - ydat: data to plot, will average over rows (var to average x time)
%   - [colz]: color in RGB matrix
%   - [lnwid]: linewidth [2]
%   - [linetype]: line type [-]
%   - [shade]: SEM or 95% ci ['sem'/'ci']
%
% Output:
%   - h: figure handle
%

if ndims(ydat) > 3
    error('Too many dimensions.');
end

%% DEFAULT VALUES

optargs = {lines(size(ydat,3)), 2.5, '-','sem'};

% Now put these defaults into the valuesToUse cell array, 
% and overwrite the ones specified in varargin.
specif = find(~cellfun(@isempty,varargin)); % find position of specified arguments
[optargs{specif}] = varargin{specif};

% Place optional args in memorable variable names
[colz, lnwid, linetype, shade] = optargs{:};

%% Plot average line and filled area

for i = 1:size(ydat,3)
    hold on
    m       = squeeze(mean(ydat(:,:,i),1));
    switch shade
        case 'sem'
            err = nansem(squeeze(ydat(:,:,i)));
        case 'ci'
            err = 1.96*nansem(squeeze(ydat(:,:,i)));
    end
    h(i)    = plot(xdat,m,'Color',colz(i,:),'LineWidth',lnwid,'Linestyle',linetype);
    
    % Plot fill
    if length(err) == 1
        err = repmat(err,length(m),1);
    end
    
    hh = [];
    
    for j = 1:length(err)-1
        hold on;
        yplus1 = m(j)+err(j);
        yplus2 = m(j+1)+err(j+1);
        yminus1 = m(j)-err(j);
        yminus2 = m(j+1)-err(j+1);
        hh(end+1) = fill([xdat(j) xdat(j) xdat(j+1) xdat(j+1)],[yminus1 yplus1 yplus2 yminus2],colz(i,:),'Edgecolor','none','FaceAlpha',.25);
    end
end
    
%%

function y = nansem(x,dim)
% FORMAT: Y = NANSEM(X,DIM)
%
%    Standard error of the mean ignoring NaNs
%
%    NANSTD(X,DIM) calculates the standard error of the mean along any
%    dimension of the N-D array X ignoring NaNs.
%
%    If DIM is omitted NANSTD calculates the standard deviation along first
%    non-singleton dimension of X.
%
%    Similar functions exist: NANMEAN, NANSTD, NANMEDIAN, NANMIN, NANMAX, and
%    NANSUM which are all part of the NaN-suite.

% -------------------------------------------------------------------------
%    author:      Jan Gläscher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%
%    $Revision: 1.1 $ $Date: 2004/07/22 09:02:27 $

if isempty(x)
    y = NaN;
    return
end

if nargin < 2
    dim = min(find(size(x)~=1));
    if isempty(dim)
        dim = 1;
    end
end


% Find NaNs in x and nanmean(x)
nans = isnan(x);

count = size(x,dim) - sum(nans,dim);


% Protect against a  all NaNs in one dimension
i = find(count==0);
count(i) = 1;

y = nanstd(x,dim)./sqrt(count);

y(i) = i + NaN;

% $Id: nansem.m,v 1.1 2004/07/22 09:02:27 glaescher Exp glaescher $
