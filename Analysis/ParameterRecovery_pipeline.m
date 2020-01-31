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
do.paramrecov   = true; % do parameter recovery?

recoverParam    = 'm'; % parameter recovery for 'm' or 's'?
savename        = sprintf('Modelfit_SI_paramrecov_%s',recoverParam);

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

switch recoverParam
    case 'm'
        sim_m           = repmat(linspace(lb(1),ub(1),nsteps),nsim,1); % linear steps
        sim_leak        = repmat(lb(2) + (ub(2)-lb(2)).*rand(nsim,1),1,nsteps);
        sim_noise     	= repmat(lb(3) + (ub(3)-lb(3)).*rand(nsim,1),1,nsteps);
        sim_lapse     	= repmat(lb(4) + (ub(4)-lb(4)).*rand(nsim,1),1,nsteps);
    case 's'
        sim_m           = repmat(lb(1) + (ub(1)-lb(1)).*rand(nsim,1),1,nsteps);
        sim_leak        = repmat(lb(2) + (ub(2)-lb(2)).*rand(nsim,1),1,nsteps);
        sim_noise     	= repmat(linspace(lb(3),ub(3),nsteps),nsim,1); % linear steps
        sim_lapse     	= repmat(lb(4) + (ub(4)-lb(4)).*rand(nsim,1),1,nsteps);
end

paramcomb       = cat(2,sim_m(:),sim_leak(:),sim_noise(:),sim_lapse(:));

%%

if do.paramrecov
    
    try
        tic
        
        % Parpooling
        if do.parpooling
            numWorkers = 50;
            c = parcluster();
            c.NumWorkers = numWorkers;
            parpool(c,numWorkers);
        else
            numWorkers = 0;
        end
                
        % Run model fit for each subject
        parfor (comb = 1:allit, numWorkers)
            ParameterRecovery_auxfunc(comb,paramcomb,data,paths,X,param_bounds);
        end
        
        % Save all data in one file
        paramrecov.recov = 0*paramcomb;
        for n = 1:allit
            load(fullfile(paths.data.model,sprintf('Modelfit_SI_paramrecov_sim%d',n)));
            paramrecov.recov(n,:) = bestparam;
        end
        
        paramrecov.orig = paramcomb;
        
         % Save data in one big file
        save(fullfile(paths.data.model,savename),'paramrecov');
        fprintf('\nData concatenated and saved.\n');
        
        elapsedtime = toc;
        fprintf('\nTime elapsed is %.2f minutes or %.2f hours.\n',elapsedtime/60,elapsedtime/60/60);
        
        % Delete all individual files
        delete(fullfile(paths.data.model,'Modelfit_SI_paramrecov_sim*.mat'));
        fprintf('\nAll individual files deleted.\n');
        
    catch ME
        % End parpool session
        if do.parpooling
            delete(gcp);
        end
        disp('Try loop failed.');
        
        elapsedtime = toc;
        fprintf('\nTime elapsed is %.2f minutes or %.2f hours.\n',elapsedtime/60,elapsedtime/60/60);
        
        rethrow(ME)
    end
    
    %% End parpool session
    if do.parpooling
        delete(gcp);
    end
end
