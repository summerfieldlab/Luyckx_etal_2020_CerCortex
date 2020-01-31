function fEEG_trigger(params,do,s,inputfile,outputfile)
% function fEEG_trigger(params,do,s,inputfile,outputfile)
% Function to choose triggers you want to retain.
%
% Fabrice Luyckx, 3/11/2016

if do.picktrigger
    
    disp(' ');
    disp(['Pick triggers subject ' num2str(params.submat(s))])
    
    % restart eeglab (because of memory issues)
    close all
    clear ALLEEG EEG CURRENTSET ALLCOM
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
    
    % Load dataset
    EEG             = pop_loadset(inputfile, params.data.saveEEG);
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
    
    for i = 1:length(EEG.event)
        if any(EEG.event(i).type==cell2mat(params.triggerz.all))
            trigindx(i)=1;
        else
            trigindx(i)=0;
        end
    end
    
    clear trigindx data tmp
    
    % Save dataset
    EEG.setname     = outputfile;
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
    EEG             = pop_saveset(EEG, outputfile, params.data.saveEEG);
    
    disp(' ');
    disp(['Pick trigger subject ' num2str(params.submat(s)) ' saved.']);
    
end

end

