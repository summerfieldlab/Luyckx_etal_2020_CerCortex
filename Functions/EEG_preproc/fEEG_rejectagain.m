function fEEG_rejectagain(params,do,s,inputfile,outputfile,mfile)

if do.rejectagain
    
    fprintf('\nRejecting trials again subject %d.\n',params.submat(s));
    
    % restart eeglab (because of memory issues)
    close all
    clear ALLEEG EEG CURRENTSET ALLCOM
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
    
    % load dataset
    EEG             = pop_loadset(inputfile, params.data.saveEEG);
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
    
    % Reject marked epochs
    
    % Save rejected trials in m-file
    load(fullfile(params.data.finalEEG,mfile));
    tmp = rejectedTrialz;
    
    % Reject artefacts
    EEG = pop_rejepoch(EEG,tmp);
    
    % Save file
    EEG.setname     = outputfile;
    EEG             = pop_saveset(EEG, outputfile, params.data.saveEEG);
    
    fprintf('\nRejecting trials subject %d finished and saved.\n',params.submat(s));

end

end