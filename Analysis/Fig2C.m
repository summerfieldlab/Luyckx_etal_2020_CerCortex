%%%%%%%%%%
%% Fig 2C
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

do.fixed_model  = false; % fix gating parameter?

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

% Model data
if do.fixed_model
    modname = 'Model_SI_noW'; % fixed model
else
    modname = 'Model_SI_full'; % full model
end

% Get model choices
load(fullfile(paths.data.model,modname));

estY    = 0.*Y;
for s = 1:params.nsubj
    
    modparam = [model.w(s) model.leak(s) model.noise(s) model.lapse(s)];
    
    idx = data.sub == params.submat(s) & Y >= 0;
    estY(idx) = Model_SelectiveIntegration(modparam,X(idx,:,:));
end

%%

clear Betas

xdat        = data.diffDV;
nregr       = size(xdat,2);
regdistr    = 'Binomial';
reglink     = 'logit';

for c = 1:2 % 1 = model, 2 = human
    for s = 1:params.nsubj
        fprintf('\nRegression sub %d\n',params.submat(s));
        idx         = data.sub == params.submat(s) & data.RT > 0;
        
        normX       = zscore(xdat(idx,:));
        if c == 1
            mdl         = fitglm(normX,estY(idx),'Distribution',regdistr,'Link',reglink);
        elseif c == 2
            mdl         = fitglm(normX,Y(idx),'Distribution',regdistr,'Link',reglink);
        end
        Betas(s,:,c) 	= mdl.Coefficients.Estimate;
    end
end

%% Significance

if do.signif
    for s = 1:params.nsubj
        coeffs(s,:)  = polyfit(1:params.nsamp,squeeze(Betas(s,2:end,2)),1);
    end
    
    [pval,hval,stats] = signrank(coeffs(:,1),0,'method','approximate')
end

%% Plotting

if do.plotting
    
    M_mod       = mean(Betas(:,2:end,1));
    M_hum       = mean(Betas(:,2:end,2));
    CI_mod      = 1.96.*std(Betas(:,2:end,1))./sqrt(params.nsubj);
    CI_hum      = 1.96.*std(Betas(:,2:end,2))./sqrt(params.nsubj);
    
    figR = figure; hold on;
    h(1) = myfillsteplot(1:nregr,Betas(:,2:end,1),modcol,[],[],'ci');
    h(2) = errorbar(1:nregr,M_hum,CI_hum,'ko','LineWidth',1.5,'MarkerFaceColor','k','MarkerSize',10);
    h(2).CapSize = 0;
    
    xlim([0 nregr+1]);
    ylim([0 1.5]);
    
    ax = gca;
    whichSamp = [1,3,5,7,9];
    set(ax,'XTick',whichSamp,'XTickLabel',samplenamez(whichSamp),'FontSize',20);
    ax.XAxis.FontWeight = 'bold';
    ylabel('Parameter estimate (z)','FontSize',axlabelfntsz);
    set(ax,'LineWidth',1.5);
    
    legend(h,{'Model','Human'},'FontSize',24,'Location','NorthWest');
    legend boxoff
    
    if do.save_plot
        save2svg(figR,paths.figures.current,'Recency',[.1 .1 350 300]);
    end
    
end