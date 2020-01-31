function fEEG_rejartefact(params,do,subject,inputfile,outputfile,mfile)
%function fEEG_rejartefact(params,do,subject,inputfile,outputfile,mfile)
% Function to manually reject epochs.
%
% Fabrice Luyckx, 3/11/2016

if do.artefact
    
    disp(' ');
    disp(['Rejecting trials of subject ' num2str(subject)])
    
    % restart eeglab (because of memory issues)
    close all
    clear ALLEEG EEG CURRENTSET ALLCOM
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
    
    % load dataset
    EEG = pop_loadset(inputfile, params.data.saveEEG);
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, 1);
    
    % Open EEG plot
    pop_eegplot(EEG,1,1,0);
    pause
    EEG = ALLEEG(2);
    
    % Reject marked epochs
    marksUpdated = questdlg('Done with updating marks?');
    if strmatch(marksUpdated, 'Yes')
        
        % Save rejected trials in m-file
        clear reject
        reject = [EEG.reject.rejmanual(params.trialz), ones(1,length(EEG.reject.rejmanual)-params.trialz(end))]; % reject extra trials as well
        save(['Subject' num2str(subject) '_Session1_BarExp_rejectedTrials.mat'],'reject');
        disp(' ');
        disp(['Rejected trials m-file subject ' num2str(subject) ' saved.']);
        
        % Reject artefacts
        EEG = pop_rejepoch(EEG,reject);
        
        % Save file
        EEG.setname     = outputfile;
        EEG             = pop_saveset(EEG, outputfile, params.data.saveEEG);
        
        disp(' ');
        disp(['Rejected trials subject ' num2str(subject) ' saved.']);
        
    end
end

end

