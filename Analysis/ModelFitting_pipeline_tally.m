%%%%%%%%%%%%%%%%%%%%%%
%% Fit models to data
%%%%%%%%%%%%%%%%%%%%%%

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

do.modelfit     = true; % fit model?
do.crossval     = true; % cross-validation?

do.signif       = true; % test significance of model parameter

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

% Subject data
X   = cat(3,data.leftDV,data.rightDV);
Y   = data.respside - 1;

crossval        = do.crossval; % for parallell processing

% Get file names and set parameter bounds
modsavename = sprintf('Model_SI_tally');

% Parameter bounds
lb              = [10 0 0 0]; % w, leak, noise, lapse
ub              = [10 .5 .5 .2];
param_bounds    = [lb;ub];


if do.crossval
    modsavename = [modsavename '_crossval'];
end

%% Global Search

if do.modelfit
    
    try
        tic
        
        % Parpooling
        if do.parpooling
            numWorkers = params.nsubj;
            c = parcluster();
            c.NumWorkers = numWorkers;
            parpool(c,numWorkers);
        else
            numWorkers = 0;
        end
        
        % Run model fit for each subject
        parfor (s = 1:params.nsubj, numWorkers)
            ModelFitting_auxfunc_tally(s,data,params,paths,X,Y,param_bounds,crossval);
        end
        
        elapsedtime = toc;
        fprintf('\nTime elapsed is %.2f minutes or %.2f hours.\n',elapsedtime/60,elapsedtime/60/60);
        
        % Concatenate model data
        model   = struct();
        allLL   = zeros(params.nsubj,1);
        
        for s = 1:params.nsubj
            
            % Load individual fits
            load(fullfile(paths.data.model,sprintf('Modelfit_tallyfit_sub%d',params.submat(s))));
            
            % Full model fit
            if ~do.crossval
                model.w(s)      = bestparam(1);
                model.leak(s)   = bestparam(2);
                model.noise(s)  = bestparam(3);
                model.lapse(s)  = bestparam(4);
                model.nparams   = sum(lb ~= ub);
                allLL(s)        = LL;
            % Only care about log-likelihood fits for cross-val
            elase 
                model.nparams   = sum(lb ~= ub);
                allLL(s)        = LL{1}+LL{2};
            end
        end
        
        save(fullfile(paths.data.model,modsavename),'model','allLL');
        
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
