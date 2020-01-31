function fEEG_badchan(params,do,s,inputfile,outputfile)
% function fEEG_badchan(params,do,s,inputfile,outputfile)
% Function to interpolate bad channels.
%
% Fabrice Luyckx, 3/11/2016

if do.badchan
    
    fprintf('\nRemoving bad channels subject %d.\n',params.submat(s));

    % restart eeglab (because of memory issues)
    close all
    clear ALLEEG EEG CURRENTSET ALLCOM
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
    
    % Load dataset
    EEG             = pop_loadset(inputfile, params.data.saveEEG);
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
    
    % Get labels
    for i = 1:size(EEG.chanlocs,2)
        labels{i} = EEG.chanlocs(i).labels;
    end
    
    % Determine bad channels
    baddy   = params.badchan{s};
    
    if ~isempty(baddy)
        for r = 1:length(baddy)
            bad4interp(r) = strmatch(baddy{r},labels);
        end
        
        % Interpolate bad channels
        EEG = eeg_interp(EEG,bad4interp,'spherical');
        [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, 1);
        eeglab redraw
    end
    
    % save the dataset
    EEG.setname     = outputfile;
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
    EEG             = pop_saveset(EEG, outputfile, params.data.saveEEG);
    
    fprintf('\nBad channels subject %d removed and saved.\n',params.submat(s));

end

end

