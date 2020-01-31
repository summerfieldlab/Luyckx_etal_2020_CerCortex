%% Load path and data

% Adjust these paths
paths.main                  = fullfile('/Volumes','Data_drive','Luyckx_etal_2019_SI'); % change path to location of folder
paths.toolbox.eeglab        = fullfile('~','Documents','MATLAB','eeglab14_1_2b'); % path to location of eeglab version
paths.toolbox.fieldtrip     = fullfile('~','Documents','MATLAB','fieldtrip'); % path to location of fieldtrip
paths.toolbox.spm           = fullfile('~','Documents','MATLAB','spm12'); % path to location of spm

if isempty(paths.main)
    error('Please change paths.main to the location of the folder ''Luyckx_etal_2019_SI''.');
end

if isempty(paths.toolbox.eeglab)
    error('Please change paths.toolbox.eeglab to the location of your version of eeglab.');
end

if isempty(paths.toolbox.fieldtrip)
    error('Please change paths.toolbox.fieldtrip to the location of your version of fieldtrip.');
end

if isempty(paths.toolbox.spm)
    error('Please change paths.toolbox.spm to the location of your version of spm.');
end

% Set path
paths.analysis          = fullfile(paths.main,'Analysis2');
paths.data.main         = fullfile(paths.main,'Data');
paths.data.behav        = fullfile(paths.data.main,'Behaviour');
paths.data.model        = fullfile(paths.data.main,'Model');
paths.data.EEG          = fullfile(paths.data.main,eegfolder);
paths.data.saveEEG      = fullfile(paths.data.main,saveEEGfolder);
paths.functions.main    = fullfile(paths.main,'Functions');
paths.figures.main      = fullfile(paths.main,'Figures');
paths.figures.current   = fullfile(paths.figures.main,figfolder);

% Add paths
cd(paths.analysis);
addpath(paths.data.behav);
addpath(paths.data.model);
addpath(paths.data.EEG);
addpath(paths.toolbox.eeglab);
addpath(paths.toolbox.spm);
addpath(paths.toolbox.fieldtrip);
addpath(genpath(paths.functions.main));
addpath(paths.figures.current);

% Load behavioural data
load(fullfile(paths.data.behav,'BarExp_behav_full.mat'));

% Load channel data
if exist(fullfile(paths.data.EEG,'chanlocs_file.mat')) > 0
    load(fullfile(paths.data.EEG,'chanlocs_file'));
end

% Load timepoints for data
if exist(fullfile(paths.data.EEG,'timepoints_file.mat')) > 0
    load(fullfile(paths.data.EEG,'timepoints_file'));
end

%% Variables

params.submat       = unique(data.sub)';
params.nsubj        = length(params.submat);
params.ttrials      = length(data.sub);
params.ntrials      = length(data.sub(data.sub == params.submat(1) & data.session == 1));
params.nblocks      = length(unique(data.block));
params.btrials      = params.ntrials/params.nblocks;
params.nsamp        = size(data.sample,2);
params.nsessions    = length(unique(data.session));
params.nframes      = length(unique(data.frame));
params.ncond        = length(unique(data.type));
params.frame        = unique([data.sub,data.session,data.frame],'rows');
params.bandpass     = [];
params.cluster      = {};