function [erpdata, bindx, eindx] = PreprocERP(s,data,params,paths)
% [erpdata, bindx, eindx] = PreprocEEG(s,data,params,paths)
% 
% Function to load subject data, concatenate and get indices of
% valid trials.
%
% Fabrice Luyckx, 17/10/2018

%% Initialise

erpdata     = [];

% Index for exluding trials
goodtrials  = [];
bindx       = []; % behavioural index
eindx       = []; % eeg index

%% Load data

fprintf('\nloading ...\n');

for sess = 1:2
        
    %% Load data
    
    % Load EEG data
    load(fullfile(paths.data.EEG,sprintf('Subject%d_Session%d_BarExp_%s_%s.mat',params.submat(s),sess,params.datatype,data.filename)));
    
    % Load bad trials
    rejfile = dir(fullfile(paths.data.EEG,sprintf('Subject%d_Session%d_BarExp_rejectedTrials*.mat',params.submat(s),sess)));
    load(rejfile.name);
    
    %% Define variables
    
    % Good trials
    tmpGood     = 1-rejectedTrialz(1:params.ntrials);
    goodtrials  = cat(2,goodtrials,tmpGood);
    
    % Variables
    ntimepoints = length(eeg.timepoints); % number of time points in epoch
    rtrials     = length(find(tmpGood == 1)); % number of preserved trials
    
    % Reshape
    if sum(tmpGood) ~= size(eeg.data,3)
        tmpErp  = reshape(eeg.data,[eeg.nbchan,ntimepoints,params.nsamp,rtrials]);  
        erpdata = cat(4,erpdata,tmpErp); % (nchannels x ntimepoints (x nsamp) x ntrials(*nsessions))
    else
        erpdata = cat(3,erpdata,eeg.data); % (nchannels x ntimepoints (x nsamp) x ntrials(*nsessions))
    end
        
end

%% Indices for excluding trials

idx     = data.sub == params.submat(s);

cortmp  = data.cor(idx) >= 0 & params.extra_idx(idx);
bindx   = cortmp & goodtrials'; % behavioural index
eindx   = cortmp(logical(goodtrials')) == 1; % eeg index

end

