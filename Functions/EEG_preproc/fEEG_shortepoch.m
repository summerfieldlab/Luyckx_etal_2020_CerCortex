function fEEG_shortepoch(params,do,s,inputfile,outputfile)
%function fEEG_shortepoch(params,do,s,inputfile,outputfile)
% Function to extract short (sample) epochs and baseline correct
% 
% Fabrice Luyckx, 3/11/2016

if do.shortepoching
       
    disp(' ');
    disp(['Short epoching subject ' num2str(params.submat(s))])
    
    % Restart eeglab (because of memory issues)
    close all
    clear ALLEEG EEG CURRENTSET ALLCOM
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
    
    % Load dataset
    EEG = pop_loadset(inputfile, params.data.saveEEG);
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, 1);
    
    % Epoching
    newname         = outputfile;
    EEG             = pop_epoch(EEG, params.triggerz.short, params.epoch.short, 'newname', newname, 'epochinfo', 'yes');
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
    
    % Baseline correction
    if ~isempty(params.baseline.short)
        EEG             = pop_rmbase(EEG, params.baseline.short);
        [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
        disp('Short epoch is baselined again.');
    end
    
    % Save the dataset
    EEG.setname     = outputfile;
    EEG             = pop_saveset(EEG, outputfile, params.data.saveEEG);
    
    disp(' ');
    disp(['Short epoching subject ' num2str(params.submat(s)) ' done.']);
    
end

end


