%%%%%%%%%%%%%%%%%%%%%
%% Parameter recovery
%%%%%%%%%%%%%%%%%%%%%

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
do.plotting     = true; % plot recovered paramters
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

%% Model inputs

% Load full model parameter fits to get bounds
modname = 'Model_SI_full';
load(fullfile(paths.data.model,modname));

% Subject data
X   = cat(3,data.leftDV,data.rightDV);
Y   = data.respside - 1;

% Parameter bounds
lb              = min([model.w' model.leak' model.noise' model.lapse']);
ub              = max([model.w' model.leak' model.noise' model.lapse']);
param_bounds    = [lb;ub];

% Generate combinations
nsteps          = 25;
nsim            = 500;
allit           = nsim*nsteps; % total N of iterations

%% Plot recovered parameters

if do.plotting
    
    filenamez   = {'m','s'};
    paramnamez  = {'\it{m}','\lambda','\it{s}','\kappa'};
    paramloc    = [1,3];
    plotnamez   = {'fixed','other'};

    for p = 1:2
        
        % Load appropriate data
        load(fullfile(paths.data.model,sprintf('Modelfit_SI_paramrecov_%s',filenamez{p})));
        
        pidx    = paramloc(p);
        stepval = unique(paramrecov.orig(:,pidx));
        nsteps  = length(stepval);
        nparam  = size(paramrecov.orig,2);
        nsim    = size(paramrecov.orig,1)/nsteps;
        
        for m = 1:2
            
            figA = figure; hold on;
            
            if m == 1
                
                %plot([lb ub],[lb ub],'k--','LineWidth',1);
                plot(paramrecov.orig(:,pidx),paramrecov.recov(:,pidx),'ko','MarkerFaceColor','k','MarkerEdgeColor','k','MarkerSize',8);
                
                ax = gca;
                axis square
                box on
                set(ax,'FontSize',20,'LineWidth',1.5);
                
                xlim([lb(pidx) ub(pidx)]);
                ylim([lb(pidx) ub(pidx)]); 
                
                xlabel(sprintf('Original %s',paramnamez{pidx}),'FontSize',24);
                ylabel(sprintf('Recovered %s',paramnamez{pidx}),'FontSize',24);
                                
            elseif m == 2
                
                % Get error for each parameter
                err         = paramrecov.orig - paramrecov.recov;                
                err_reshape = reshape(err,[nsim,nsteps,nparam]);
                err_mean    = squeeze(mean(err_reshape,1));
                
                pidx    = setdiff(1:4,paramloc(p));                
                ci      = 1.96.*std(err_mean)./sqrt(size(err_mean,1));

                plot([0 4],[0 0],'k--','LineWidth',1.5);
                errorbar(1:3,mean(err_mean(:,pidx)),ci(pidx),'ko','LineWidth',1.5,'MarkerFaceColor','k','MarkerSize',8);
                ax = gca;
                box on;
                set(ax,'XTick',1:3,'XTickLabel',{paramnamez{pidx}},'LineWidth',1.5);
                
                ax.XAxis.FontSize = 24;
                ax.YAxis.FontSize = 20;
                
                ylabel('Recovery error','FontSize',24);
                
                ylim([-0.000025 0.00001]);

            end
            
            if do.save_plot
                if m == 1
                    save2svg(figA,paths.figures.current,sprintf('Paramrecov_%s_%s',plotnamez{m},filenamez{p}),[.1 .1 500 450]);
                elseif m == 2                    
                    save2svg(figA,paths.figures.current,sprintf('Paramrecov_%s_%s',plotnamez{m},filenamez{p}),[.1 .1 350 450]);
                end
            end
        
        end
        
    end
end
