%%%%%%%%%%
%% Fig 2A
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
do.save_fit     = true; % save beta estimates

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

%% Regression sum DV

clear Betas

% Create independent variables
Iwin                    = sign(data.diffDV);
Iwin(Iwin < 0)          = 0;
Ilose                   = 1-Iwin;

winLeft 	= zeros(params.ttrials,1);
loseLeft  	= zeros(params.ttrials,1);
winRight 	= zeros(params.ttrials,1);
loseRight	= zeros(params.ttrials,1);

for t = 1:params.ttrials
    winLeft(t,1)  	= sum(data.leftDV(t,Ilose(t,:)==1));
    loseLeft(t,1)  	= sum(data.leftDV(t,Iwin(t,:)==1));
    winRight(t,1) 	= sum(data.rightDV(t,Iwin(t,:)==1));
    loseRight(t,1)	= sum(data.rightDV(t,Ilose(t,:)==1));
end

xdat        = [winLeft loseLeft winRight loseRight];
regdistr    = 'Binomial';
reglink     = 'logit';

% Model gives continuous output, while participant is binomial
for c = 1:2
    for s = 1:params.nsubj
        
        fprintf('\nRegression sub %d\n',params.submat(s));
        idx = data.sub == params.submat(s) & data.cor >= 0;
        
        normX       = zscore(xdat(idx,:));
        if c == 1
            mdl         = fitglm(normX,estY(idx),'Distribution',regdistr,'Link',reglink); % model
        elseif c == 2
            mdl         = fitglm(normX,Y(idx),'Distribution',regdistr,'Link',reglink); % human
        end
        
        Betas(s,:,c)  = mdl.Coefficients.Estimate;
    end
end

% Beta estimates
moddat(:,1)  	= mean([-Betas(:,2,1),Betas(:,4,1)],2); % win
moddat(:,2) 	= mean([-Betas(:,3,1),Betas(:,5,1)],2); % lose
humdat(:,1)  	= mean([-Betas(:,2,2),Betas(:,4,2)],2); % win
humdat(:,2) 	= mean([-Betas(:,3,2),Betas(:,5,2)],2); % lose
[humdiff,I]     = sort(humdat(:,1) - humdat(:,2),'descend');
moddiff         = moddat(:,1) - moddat(:,2);

if do.save_fit
    betas_behav(:,1) = mean([-Betas(:,2,2),Betas(:,4,2)],2);
    betas_behav(:,2) = mean([-Betas(:,3,2),Betas(:,5,2)],2);    
    save(fullfile(paths.data.behav,'Behav_winlose'),'betas_behav');
    fprintf('\nBetas saved.\n');
end

%% Test significance

if do.signif
    [p,h,stats] = signrank(humdat(:,1),humdat(:,2),'method','approximate');   
end

%% Plotting

if do.plotting
    
    plotdat = [humdat moddat];
    coldat  = [colz(1:2,:); modcol(1,:); modcol(1,:)];
    ylims   = [.8 6];
    
    figB = figure; hold on;
    
    % Individual points
    for s = 1:params.nsubj
        plot(1:2,humdat(s,:),'o-','Color',[1 1 1].*.7,'MarkerFaceColor',[1 1 1].*.7,'LineWidth',1.25,'MarkerSize',7); % human
        plot(3:4,moddat(s,:),'o-','Color',[1 1 1].*.7,'MarkerFaceColor',[1 1 1].*.7,'LineWidth',1.25,'MarkerSize',7); % model
    end
    
    hB = boxplot(plotdat,'Color',coldat,'Widths',.3);
    set(hB,{'linew'},{3});
    
    ax = gca;
    set(ax,'XTick',1:4,'XTickLabel',{'\Sigma X_{win}','\Sigma X_{lose}','\Sigma X_{win}','\Sigma X_{lose}'},...
        'FontSize',axfntsz,'LineWidth',1.5,'TickLabelInterpreter','tex');
    set(ax,'Ytick',1:6);
    ax.XAxis.FontSize = 20;
    ylabel('Parameter estimate (z)','FontSize',20);
    box off
    
    ylim(ylims);
    
    if do.save_plot
        save2eps(figB,paths.figures.current,'Resp-DVw+DVl_boxplot',[.1 .1 350 300]);
    end
    
end