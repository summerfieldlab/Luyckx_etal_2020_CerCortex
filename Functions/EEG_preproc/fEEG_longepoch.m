function fEEG_longepoch(params,do,s,inputfile,outputfile)
%function fEEG_longepoch(params,do,s,inputfile,outputfile)
% Function to extract long epochs and baseline correct
% 
% Fabrice Luyckx, 3/11/2016

if do.longepoching
       
    fprintf('\nExtracting long epoch subject %d.\n',params.submat(s));
    
    % Restart eeglab (because of memory issues)
    close all
    clear ALLEEG EEG CURRENTSET ALLCOM
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
    
    % Load dataset
    EEG = pop_loadset(inputfile, params.data.saveEEG);
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, 1);
    
    % Epoching
    newname         = outputfile;
    EEG             = pop_epoch(EEG, params.triggerz.long, params.epoch.long, 'newname', newname, 'epochinfo', 'yes');
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
    
    % Baseline correction
    EEG             = pop_rmbase(EEG, params.baseline.long);
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
    
    % Save the dataset
    EEG.setname     = outputfile;
    EEG             = pop_saveset(EEG, outputfile, params.data.saveEEG);
    
    fprintf('\nLong epochs subject %d finished and saved.\n',params.submat(s));
    
end

end

