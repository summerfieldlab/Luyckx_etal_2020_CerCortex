
function fEEG_select_eog(params,do,s,inputfile,outputfile)
% function fEEG_downsample_cnt(params,do,s,inputfile,outputfile)
%  Function to downsample data that has already been formatted to .set files.
%
% Fabrice Luyckx, 5/10/2018

if do.downsample
        
    fprintf('\nImporting subject %d.\n', params.submat(s));
    
    % Restart eeglab because of memory things
    close all
    clear ALLEEG EEG CURRENTSET ALLCOM
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
    
    % import the NEUROSCAN data in eeglab
    EEG             = pop_loadset(inputfile, params.data.eeg);
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
    
    % Get channel information
    EEG.chanlocs    = readlocs(fullfile(params.data.eeg,'locs.ced'));    
    
    % Keep channels    
    for remmy=1:length(params.whichChannel)
        remz(remmy)=strmatch(chan2rem{remmy},{EEG.chanlocs.labels});
    end
    
    EEG.chanlocs(remz)      = [];
    EEG.data(remz(3:end),:) = []; % removing the corresponding data
    EEG.nbchan              = size(EEG.data,1);
     
    % Re-sample data
    fprintf('\nDownsampling ...\n');
    EEG = pop_resample(EEG, params.resamp);
    [ALLEEG, EEG, index] = eeg_store(ALLEEG, EEG);
    
    EEG = eeg_checkset(EEG);
    
    fprintf('\nSaving ...\n');
    EEG.setname     = outputfile;
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG             = pop_saveset(EEG, outputfile, params.data.saveEEG);
    
    fprintf('\nImporting and downsampling subject %d finished and saved.\n',params.submat(s));
    
end

end