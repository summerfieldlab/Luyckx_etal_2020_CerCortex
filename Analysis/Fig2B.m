%%%%%%%%%%
%% Fig 2B
%%%%%%%%%%

%% LOAD DATA

clc
clear

% Paths
saveEEGfolder   = []; % unused here
eegfolder       = []; % unused here
figfolder       = 'Model';

% Load stuff
Load_vars; % load data and path
Config_plot; % load plot variables

% Logicals
do.parpooling   = false; % parallel processing?
do.signif       = true; % do significance test?
do.plotting     = true; % plot results?
do.save_plot    = false; % save plot?

%% Extra variables

lowindx                 = data.frame == 0; % low frame

% PV and DV
data.leftPV             = data.sample(:,:,1);
data.rightPV            = data.sample(:,:,2);
data.leftDV             = data.leftPV;
data.rightDV            = data.rightPV;
data.leftDV(lowindx,:)  = 200-data.leftPV(lowindx,:); % flip for low frame
data.rightDV(lowindx,:) = 200-data.rightPV(lowindx,:); % flip for low frame
data.diffDV             = data.rightDV - data.leftDV;
data.cumdiffDV          = cumsum(data.diffDV,2);

% Subject data
X   = cat(3,data.leftDV,data.rightDV);
Y   = data.respside - 1;

% Load model with no w
modname = 'Model_SI_noW';
load(fullfile(paths.data.model,modname));

% Get model choices
estY_red    = 0.*Y;
for s = 1:params.nsubj
    
    modparam = [model.w(s) model.leak(s) model.noise(s) model.lapse(s)];
    
    idx = data.sub == params.submat(s) & Y >= 0;
    estY_red(idx) = Model_SelectiveIntegration(modparam,X(idx,:,:));
end

% Load full model
modname = 'Model_SI_full';
load(fullfile(paths.data.model,modname));

% Get model choices
estY    = 0.*Y;
for s = 1:params.nsubj
    
    modparam = [model.w(s) model.leak(s) model.noise(s) model.lapse(s)];
    
    idx = data.sub == params.submat(s) & Y >= 0;
    estY(idx) = Model_SelectiveIntegration(modparam,X(idx,:,:));
end

%% Accuracy per condition

winside = data.winSide - 1;
corr_full = estY;
corr_full(winside == 0) = 1-estY(winside == 0);
corr_red = estY_red;
corr_red(winside == 0) = 1-estY_red(winside == 0);

for s = 1:params.nsubj
    for c = 1:params.ncond
        idx = data.sub == params.submat(s) & data.RT > 0 & data.type == c;
        acc_hum(s,c) = mean(data.cor(idx));
        acc_full(s,c) = mean(corr_full(idx));
        acc_red(s,c) = mean(corr_red(idx));
    end
end

ci_hum = 1.96.*(nanstd(acc_hum)./sqrt(params.nsubj));
ci_full = 1.96.*(nanstd(acc_full)./sqrt(params.nsubj));
ci_red = 1.96.*(nanstd(acc_red)./sqrt(params.nsubj));

%% Test differences between conditions

if do.signif
    % Friedman test (non-param rmANOVA)
    [p_omn,tbl,stats_omn] = friedman(acc_hum,1,'off')
    
    % Pairwise tests
    allpairs = nchoosek(1:4,2);
    for i = 1:size(allpairs,1)
        [p(i),h(i),stats(i)] = signrank(acc_hum(:,allpairs(i,1)),acc_hum(:,allpairs(i,2)),'method','approximate');
    end
    
    [p_fdr, p_masked] = fdr(p,.05);
    
    fprintf('Significant pairs:\n');
    allpairs(p_masked,:)
end

%%

if do.plotting
        
    xlims       = [.35 1];
    ylims       = [0 .035];
    bxpos       = [.4*ylims(2) .6*ylims(2) .8.*ylims(2)];
    boxwidth    = .004;
    
    for c = 1:params.ncond
        
        figH = figure; hold on;
        figsize = [.1 .1 400 200];
        figH.Position = figsize;
        
        ax(c) = gca;
        
        % Plot distribution
        fd      = fitdist(acc_hum(:,c),'Kernel','BandWidth',.03);
        xvals   = linspace(.5,1,100);
        pdfY    = pdf(fd,xvals);
        hA = area(xvals,pdfY/sum(pdfY),'FaceColor',[1 1 1].*.9,'EdgeColor',[1 1 1].*.9);
        
        % Plot boxplot
        boxplot(acc_hum(:,c),'Colors','k','Orientation','horizontal','Position',bxpos(1),'Width',.004);
        
        % Plot model boxplots
        boxplot(acc_full(:,c),'Colors',modcol(1,:),'BoxStyle','filled','Orientation','horizontal','Position',bxpos(2),'Width',.004);
        boxplot(acc_red(:,c),'Colors',modcol(2,:),'BoxStyle','filled','Orientation','horizontal','Position',bxpos(3),'Width',.004);
        set(findobj(gca,'type','line'),'linew',2);
        
        % Plot human distribution
        for s = 1:params.nsubj
            plot([acc_hum(s,c) acc_hum(s,c)],[0 .005],'k','LineWidth',1.5);
        end
        
        set(ax(c),'FontSize',axlabelfntsz);
        set(ax(c),'box','off');
        
        set(ax(c),'YTick',[]);
        
        title(conditionz{c},'FontSize',titlefntsz);
        xlim(xlims);
        ylim(ylims);
        
        % Legend
        if c == 1
            hL = legend(findall(ax(1),'Tag','Box'), {'Fixed model','Full model','Human'},...
                'Box','off','Location','NorthWest','FontSize',axlabelfntsz,'Location',[0.2 0.65 0.2509 0.1298]);
        end
        
        if do.save_plot
            save2svg(figH,paths.figures.current,sprintf('Acc_cond_modelfits_%s',conditionnamez{c}),figsize);
        end
        
    end
    
end

%% Forest plot with PNAS 2016

