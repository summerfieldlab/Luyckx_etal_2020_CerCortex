%%%%%%%%%%%%%%%%%%%%%%
%% Model comparisons
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
do.crossval     = true; % compare cross-validated models?

%% Model comparison full vs fixed

if do.crossval
    testmods = {'Model_SI_noW_crossval',...
        'Model_SI_full_crossval'};
else
    testmods = {'Model_SI_noW',...
        'Model_SI_full'};
end

nmods 	= length(testmods);
lme     = zeros(params.nsubj,nmods);

% Calculate BIC
for m = 1:nmods
    
    % Load model results
    load(fullfile(paths.data.model,testmods{m}));
    
    lme(:,m) = -1*allLL;
    
    for s = 1:params.nsubj
        ntrials = sum(data.sub == params.submat(s) & data.cor >= 0);
        [~,bic(s,m)] = aicbic(lme(s,m),model.nparams,ntrials);
    end
end

% Bayesian model selection
[~,~,xp_fixed] = spm_BMS(lme)

%% Model comparison full vs tally

if do.crossval
    testmods = {'Model_SI_tally_crossval',...
        'Model_SI_full_crossval'};
else
    testmods = {'Model_SI_noW',...
        'Model_SI_full'};
end

nmods 	= length(testmods);
lme     = zeros(params.nsubj,nmods);

% Calculate BIC
for m = 1:nmods
    
    % Load model results
    load(fullfile(paths.data.model,testmods{m}));
    
    lme(:,m) = -1*allLL;
    
    for s = 1:params.nsubj
        ntrials = sum(data.sub == params.submat(s) & data.cor >= 0);
        [~,bic(s,m)] = aicbic(lme(s,m),model.nparams,ntrials);
    end
end

% Bayesian model selection
[~,~,xp_tally] = spm_BMS(lme)

