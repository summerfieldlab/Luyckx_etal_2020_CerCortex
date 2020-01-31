function [h,sigp] = fEEG_steplot(xdat,timepoints,ylims,signif,varargin)
%function fEEG_steplot(xdat,timepoints,ylims,signif,[masstest],[colz],[p_crit],[sigside])
%
% Requires (adjusted) myfillsteplot. Function will average over first 
% dimension and calculate SEM using first dimension.
%
% Input:
%   - xdat: sub x time (x lines)
%   - timepoints: time points (in ms)
%   - ylims: y-limits of plot
%   - signif: do significance testing?
%   - [masstest]: which multiple testing correction ('bonfer','FDR','cluster')? ['none']
%   - [colz]: colors for lines
%   - [p_crit]: critical p-value for mass t-tests
%   - [sigside]: significance lines above ('top') or below ('bottom') ['top']
%
% Output:
%   - h: signal handle
%   - sigp: significance handle
%
% Fabrice Luyckx, 3/2/2017

%% DEFAULT VALUES

optargs = {'none',[],.05,'top'};

% Now put these defaults into the valuesToUse cell array, 
% and overwrite the ones specified in varargin.
specif = find(~cellfun(@isempty,varargin)); % find position of specified arguments
[optargs{specif}] = varargin{specif};

% Place optional args in memorable variable names
[masstest,linecolors,p_crit,sigside] = optargs{:};

%% Get plot variables

Config_plot;

if ~isempty(linecolors)
    colz = linecolors;
end

nregr   = size(xdat,3);

%% Plot data

hold on;
minX    = min(timepoints);
maxX    = max(timepoints);
minY    = ylims(1);
maxY    = ylims(2);

% Plot axes
plot([minX maxX],[0 0],'k--','LineWidth',1.5);
plot([0 0],[minY*1.1 maxY*1.1],'k-','LineWidth',1.5);

% Plot shaded lines
h = myfillsteplot(timepoints,xdat,colz);

xlim([minX maxX]);
ylim([minY maxY]);

%% Signifance

if signif
    
    for i = 1:nregr
        
        switch masstest
            case 'cluster'
                [p,praw]        = ClusterCorrection2(xdat(:,:,i),5000,p_crit);
                stats.h(i,:)    = double(p <= p_crit);
            otherwise
                [stats.h(i,:), stats.p(i,:), stats.t(i,:)] = masst(xdat(:,:,i),masstest);
        end
        
        stats.h(stats.h == 0) = nan;
        stats.h(stats.h == 1) = 0;
        
        switch sigside
            case 'top'
                sigpos  = maxY.*.9;
                sigp(i) = plot(timepoints,stats.h(i,:)+sigpos-0.01*(i-1),'s','MarkerFaceColor',colz(i,:),'MarkerEdgeColor',colz(i,:),'MarkerSize',6);
            case 'bottom'
                sigpos  = minY.*.9;
                sigp(i) = plot(timepoints,stats.h(i,:)+sigpos+0.015*(i-1),'s','MarkerFaceColor',colz(i,:),'MarkerEdgeColor',colz(i,:),'MarkerSize',6);
        end
    end
end

end

