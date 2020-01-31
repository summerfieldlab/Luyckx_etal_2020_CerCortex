function fEEG_averageref(params,do,s,inputfile,outputfile)
%function fEEG_averageref(params,do,s,inputfile,outputfile)
% Function for average referencing.
%
% Fabrice Luyckx, 17/10/2017

if do.averageref
    
    fprintf('\nAverage referencing subject %d.\n',params.submat(s));
    
    % restart eeglab (because of memory issues)
    close all
    clear ALLEEG EEG CURRENTSET ALLCOM
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
    
    % Load dataset
    EEG = pop_loadset(inputfile, params.data.saveEEG);
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, 1);    
    
    % Rereferencing data    
    EEG.nbchan          = EEG.nbchan+1;
    EEG.data(end+1,:)   = zeros(1, EEG.pnts);
    EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
    EEG                 = pop_reref(EEG, []); % [] is average reference
    EEG                 = pop_select( EEG,'nochannel',{'initialReference'});
   
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, 1);
    eeglab redraw
    
    % Save the dataset
    EEG.setname     = outputfile;
    [ALLEEG, EEG]   = eeg_store(ALLEEG, EEG, 1);
    EEG             = pop_saveset(EEG, outputfile, params.data.saveEEG);
    
    fprintf('\nAverage referencing subject %d finished and saved.\n',params.submat(s));
    
end

end

