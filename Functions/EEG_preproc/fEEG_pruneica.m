function fEEG_pruneica(params,do,subject,inputfile,outputfile,mfile)
%function fEEG_pruneica(params,do,subject,inputfile,outputfile,mfile)
% Function to remove ICA components and save m-file with removed components
%
% Fabrice Luyckx, 3/11/2016

if do.componentrej
    
    disp(' ');
    disp(['Removing components of subject ' num2str(subject)])
    
    % restart eeglab (because of memory issues)
    close all
    clear ALLEEG EEG CURRENTSET ALLCOM
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
    
    % load dataset
    EEG = pop_loadset(inputfile, params.data.saveEEG);
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, 1);
    
    % Open EEG plot
    pop_selectcomps(EEG); % plot the component map for selection
    pop_eegplot(EEG, 1, 1, 0); % plot channel data timecourse % change scale to 50 and set full screen
    pop_eegplot(EEG, 0, 1, 0); % plot ICA compoments timecourse % change scale to 10 and set full screen
    pause
    EEG = ALLEEG(2);
    
    % Reject marked epochs
    compsUpdated = questdlg('Done with marking components?');
    if strmatch(compsUpdated, 'Yes')
        
        % Save removed components in m-file
        clear reject
        reject = find(EEG.reject.gcompreject == 1);
        save(mfile,'reject');
        disp(' ');
        disp(['Removed components m-file subject ' num2str(subject) ' saved.']);
        
        % Remove components
        EEG = pop_subcomp(EEG);
        
        % Save file
        EEG.setname     = outputfile;
        EEG             = pop_saveset(EEG, outputfile, params.data.saveEEG);
        
        disp(' ');
        disp(['Removing components subject ' num2str(subject) ' saved.']);
    end
end

end

