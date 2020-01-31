function compute_tf_decomposition(tfParams,paths,inputname,outputname)
%% COMPUTE_TF_DECOMPOSITION()
%
% for all participants and both sample & probe
% this scripts decomposes eeg timeseries data
% into various frequency components, using
% morlet wavelets
%
% Requirements:
%   - eeglab
%   - fieldtrip
% Note: for fieldtrip to work, open file
% eeglab2fieldtrip.m and change row 47 from
% "data.label   = { tmpchanlocs(EEG.icachansind).labels };"
% to
% "data.label = { EEG.chanlocs(1:EEG.nbchan).labels };"
%
% Note2: DON'T parallelize subjects!!! (42gb ram + 10gb swap full in 10secs)
% (c) Timo Flesch, 2016/17
% Summerfield Lab, Experimental Psychology Department, University of Oxford

%% Load

% Load eeglab
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% Load fieldtrip defaults
ft_defaults;

% Turn warnings off
 ft_warning off

%% TF transformation

% load data
eeg = pop_loadset(inputname,paths.data.EEG);

% convert from eeglab to fieldtrip
eeg = eeglab2fieldtrip(eeg,'preprocessing','none');

% perform tf transformation
waveData = ft_freqanalysis(tfParams, eeg);

% remove baseline
if ~isempty(tfParams.baseline)
    waveData = ft_freqbaseline(tfParams,waveData);
end

%% Save data

tfa                 = struct;
tfa.data            = waveData.powspctrm;
tfa.timepoints      = waveData.time;
tfa.labels          = waveData.label';
tfa.freq            = waveData.freq;

save(fullfile(paths.data.saveEEG,outputname),'tfa');

fprintf('\nSaved %s.\n',outputname);

end
