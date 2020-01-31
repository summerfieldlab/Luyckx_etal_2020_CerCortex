function fEEG_filter(params,do,s,inputfile,outputfile)
% function fEEG_filter(params,do,s,inputfile,outputfile)
% Function to filter EEG data.
%
% Fabrice Luyckx, 3/10/2016

if do.filtering
        
    fprintf('\nFiltering subject %d at %d high-pass and %d low-pass.\n',params.submat(s),params.filter.highpass,params.filter.lowpass);
    
    % restart eeglab
    close all
    clear ALLEEG EEG CURRENTSET ALLCOM
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
    
    % load dataset
    EEG             = pop_loadset(inputfile, params.data.saveEEG);
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
    
    % low-pass filtering
    if ~isempty(params.filter.lowpass)
        fprintf('\nLow-pass filter subject %d.\n',params.submat(s));
        EEG = pop_eegfiltnew(EEG, [], params.filter.lowpass);
        [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, 1);
    end
    
    % high-pass filtering
    if ~isempty(params.filter.highpass)
        fprintf('\nHigh-pass filter subject %d.\n',params.submat(s));
        EEG = pop_eegfiltnew(EEG, params.filter.highpass, []);
        [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, 1);
    end
    
    % Save the dataset
    EEG.setname     = outputfile;
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
    EEG             = pop_saveset(EEG, outputfile, params.data.saveEEG);
    
    fprintf('\nFilter subject %d finished and saved.\n',params.submat(s));

end

end

