%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BarExp - EEG: time-frequency transformation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% LOAD DATA

clc
clear

% Paths long epoch (cut into samples with TF_long2sample)
eegfolder       = 'EEG_preproc';
saveEEGfolder   = 'EEG_TF_long';
infilename      = 'prunedica'; % long = prunedica, short = shortepoched, resplock = resplocked
outfilename     = 'long';

% Load stuff
Load_vars; % load data and path

%% Set parameters

% Parameters of original eeg data
params.hipass           = .5;
params.lowpass          = 40;
params.epoch.short      = [-.1 .75];  % short epoch
params.epoch.long       = [-1 7]; % long epoch % 0 = fixation cross
params.epoch.resplock   = [-3 .3]; % time of response locked epoch
params.basewdw.short    = [params.epoch.short(1) 0]; % baseline window of short epoch
params.basewdw.long     = [-.5 0]; % baseline window of 
params.basewdw.resplock = [];

% Set time-frequency analysis parameters 

% note: the wavelet duration is equal to width/F/pi
tfParams                = [];
tfParams.method      	= 'wavelet'; % perform wavelet analysis
tfParams.toi            = params.epoch.long(1):.025:params.epoch.long(2); % 25ms -> 40 Hz
tfParams.foi         	= 8:3:38; % frequencies of interest
tfParams.width       	= 7; % width of wavelets (expressed in n cycles)
tfParams.output      	= 'pow'; % output are power spectra -> decreasing power at increasing frequency!
tfParams.keeptrials    	= 'yes'; % perform on single trial level
tfParams.pad         	= 'nextpow2';

% Baseline
tfParams.baseline      	= []; % baseline window
tfParams.baselinetype  	= []; % no baselining 

%% Run TF transformation

for s = 1:params.nsubj
    for sess = 1:params.nsessions
        
        fprintf('\nTF processing subject %d, session %d.\n',s,sess);
        
        inputname   = sprintf('Subject%d_Session%d_BarExp_%s.set',params.submat(s),sess,infilename);
        outputname  = sprintf('Sub%d_sess%d_%d-%d_%s.mat',params.submat(s),sess,tfParams.foi(1),tfParams.foi(end),outfilename);
        
        % Run time-frequency transformation
        compute_tf_decomposition(tfParams,paths,inputname,outputname);
        
    end
    fprintf('\nFinished TF processing subject %d.\n',s);
end
