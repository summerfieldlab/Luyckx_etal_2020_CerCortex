function [h,c] = fEEG_timetopoplot(plotdat,timepoints,chanlocs,windowsz,varargin)
%function fEEG_timetopoplot(plotdat,timepoints,chanlocs,windowsz,[maplims])
%
% Function to plot topoplot over time windows (containing 'windowsz' frames
% per window). If 3D, separate figures are plotted for the 3rd dimension.
%
% Input:
%   - plotdat: data to plot (electrodes x timepoints [x extra])
%   - timepoints: timepoints (in ms)
%   - chanlocs: structure from eeglab with channel info
%   - windowsz: length of each window
%   - maplims: limits of the colormap (['absmax']), can change to matrix e.g. [-5 4];
%
% Output:
%   - h: figure handle(s)
%
% Fabrice Luyckx, 17/11/2016

%% DEFAULT VALUES

optargs = {'absmax'};

% Now put these defaults into the valuesToUse cell array, 
% and overwrite the ones specified in varargin.
specif = find(~cellfun(@isempty,varargin)); % find position of specified arguments
[optargs{specif}] = varargin{specif};

% Place optional args in memorable variable names
[maplims] = optargs{:};

%% Get dimensions
sz      = size(plotdat);
ndim    = ndims(plotdat);

%% Load
eeglab
close

% Load plot variables
Config_plot;

%% Extra variables
npoints         = median(unique(diff(timepoints)));
stepz           = round(windowsz/npoints);
ntimepoints     = length(timepoints); % number of time points in epoch
timeranges      = 1:stepz:ntimepoints;
nwindows        = length(timeranges);
[nrows, ncols]  = getSize_subplot(nwindows-1); % get subplot dimensions

if ndim == 3
    extra = sz(3);
else
    extra = 1;
end

%% Plot data

for e = 1:extra
    h(e) = figure;
    hold on;
    
    k=0;
    for i = 1:length(timeranges)-1
        
        k=k+1;
        m = squeeze(nanmean(plotdat(:,timeranges(i):timeranges(i+1),e),2));
        
        if all(isnan(m))
            m = zeros(length(m),1);
        end
        
        subplot(nrows,ncols,k);
        
        if min(maplims) == 0
            topoplot(m,chanlocs,'maplimits',maplims,'colormap',cool);
        else
            topoplot(m,chanlocs,'maplimits',maplims);
        end
        title([num2str(timepoints(timeranges(i))) '-' num2str(timepoints(timeranges(i+1))) 'ms'],'FontSize',axfntsz);
    end
    c(e) = colorbar;
end

end

