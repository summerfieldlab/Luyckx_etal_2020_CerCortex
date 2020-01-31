function fEEG_ica(params,do,s,inputfile,outputfile)
% function fEEG_ica(params,do,s,inputfile,outputfile)
% Function to run ica.
%
% Fabrice Luyckx, 3/11/2016

if do.ica
    
    disp(' ');
    disp(['ICA subject ' num2str(params.submat(s))])
    
    % Restart eeglab
    close all
    clear ALLEEG EEG CURRENTSET ALLCOM
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
    
    % Load dataset
    EEG             = pop_loadset(inputfile, params.data.saveEEG);
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
    
    % Run the ica
    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1);
   
    % Save the dataset
    EEG.setname     = outputfile;
    [ALLEEG, EEG]  	= eeg_store(ALLEEG, EEG, 1);
    EEG             = pop_saveset(EEG, outputfile, params.data.saveEEG);
    
    disp(' ');
    disp(['ICA subject ' num2str(params.submat(s)) ' done.']);
end

end

