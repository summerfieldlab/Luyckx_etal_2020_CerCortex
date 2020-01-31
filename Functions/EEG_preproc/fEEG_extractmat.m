function fEEG_extractmat(params,do,s,inputfile,outputfile)
% function fEEG_extractmat(params,do,s,inputfile,outputfile)
%
% Fabrice Luyckx, 3/11/2016

if do.extract
    
    fprintf('\nExtracting relevant data subject %d in mat-file.\n',params.submat(s));
    
    % Restart eeglab
    close all
    clear ALLEEG EEG CURRENTSET ALLCOM
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
    
    % Load dataset
    EEG             = pop_loadset(inputfile, params.data.saveEEG);
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
    
    % Extract relevant data
    eeg.data        = EEG.data;
    eeg.chanlocs    = EEG.chanlocs;
    eeg.trigger     = [EEG.event.type];
    eeg.timepoints  = EEG.times;
    eeg.nbchan      = EEG.nbchan;
    
    % Save data
    save(fullfile(params.data.finalEEG,outputfile),'eeg');
    
    fprintf('\nEEG mat-file subject %d saved.\n',params.submat(s));

end

end