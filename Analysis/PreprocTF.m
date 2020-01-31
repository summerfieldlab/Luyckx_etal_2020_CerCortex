function [tfdata, bindx, eindx] = PreprocTF(s,data,params,paths)
% [tfdata, bindx, eindx] = PreprocTF(s,data,params,paths)
% 
% Function to load subject data, concatenate and get indices of
% valid trials.
%
% Fabrice Luyckx, 17/10/2018

%% Initialise

tfdata     = [];

% Index for exluding trials
goodtrials  = [];
bindx       = []; % behavioural index
eindx       = []; % eeg index

%% Load data

fprintf('\nloading ...\n');

for sess = 1:2
        
    %% Load data
    
    % Load EEG data
    load(fullfile(paths.data.EEG,sprintf('BarExp_sub%d_sess%d_8-38_%s.mat',params.submat(s),sess,data.filename)));
    
    % Load bad trials
    rejfile = dir(fullfile(paths.data.EEG,sprintf('Subject%d_Session%d_BarExp_rejectedTrials*.mat',params.submat(s),sess)));
    load(rejfile.name);
    
    %% Define variables
    
    % Good trials
    tmpGood     = 1-rejectedTrialz(1:params.ntrials);
    goodtrials  = cat(2,goodtrials,tmpGood);
    
    % Variables
    ntimepoints = length(tfa.timepoints); % number of time points in epoch
    rtrials     = length(find(tmpGood == 1)); % number of preserved trials
    
    % Reshape
    tfdata = cat(1,tfdata,tfa.data); % (nchannels x ntimepoints (x nsamp) x ntrials(*nsessions))
        
end

%% Indices for excluding trials

idx     = data.sub == params.submat(s);

cortmp  = data.cor(idx) >= 0 & params.extra_idx(idx);
bindx   = cortmp & goodtrials'; % behavioural index
eindx   = cortmp(logical(goodtrials')) == 1; % eeg index

end

