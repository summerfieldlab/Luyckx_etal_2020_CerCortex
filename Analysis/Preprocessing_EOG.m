%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EEG preprocessing pipeline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load path and data

clc
clear

savefolder = 'EOG_samples'; % or 'EEG_resplocked' % where save final mat-files

% Adjust these paths
paths.main                  = []; % change path to location of folder
paths.toolbox.eeglab        = []; % path to location of eeglab version

if isempty(paths.main)
    error('Please change paths.main to the location of the folder ''Luyckx_etal_2019_SI''.');
end

if isempty(paths.toolbox.eeglab)
    error('Please change paths.toolbox.eeglab to the location of your version of eeglab.');
end

% Set path
paths.analysis          = fullfile(paths.main,'Analysis');
paths.data.main         = fullfile(paths.main,'Data');
paths.data.behav        = fullfile(paths.data.main,'Behaviour');
paths.data.EEG          = fullfile(paths.data.main,'EEG_orig'); % original raw files
paths.data.saveEEG      = fullfile(paths.data.main,'EEG_preproc'); % temporary file storage (intermediate steps)
paths.data.finalEEG     = fullfile(paths.data.main,savefolder); % final storage
paths.functions.main    = fullfile(paths.main,'Functions');

% Add paths
cd(paths.analysis);
addpath(paths.data.behav);
addpath(paths.data.EEG);
addpath(paths.toolbox.eeglab);
addpath(genpath(paths.functions.main));

%% Settings

% Which session?
params.session          = 1; % 1 = first session, 2 = second session

params.submat           = sort([2 5:11 13:19]); % valid subject indices
params.trialz           = 1:600; % which trials to use?
params.triggerz.all     = {2 10 11 12 13 14 15 16 17 18 70 71 72 30 31};
params.triggerz.long    = params.triggerz.all(1);
params.triggerz.short   = params.triggerz.all(2:10);
params.triggerz.resplock = {70 71};

params.resamp           = 250; % resampling rate
params.epoch.long       = [-1 7]; % time window of long epoch (check what your first trigger will be!)
params.epoch.short      = [-.1 .75]; % time window of short epoch
params.epoch.resplock   = [-3 .3]; % time window of response locked
params.baseline.long  	= [-500 0]; % baseline trial epoch
params.baseline.short   = [-100 0]; % baseline sample epoch / make empty if you don't want it
params.filter.highpass 	= .5; % high-pass filter
params.filter.lowpass 	= 40; % low-pass filter

params.whichChannel     = {'HEOG'};

%% Steps

do.parpooling       = true;
if minime == false
    do.parpooling   = false;
end

do.selectEOG        = false;    % downsample/remove extra channels
do.downsample       = false;    % downsample data
do.filtering        = false;    % filter data
do.longepoching     = false;    % extract long epochs and baseline correct
do.rejectagain      = false;    % when you changed stuff in the previous steps, but don't want to reject trials manually again
do.ica              = false;    % use automatic ICA (can be quite long)
do.componentrej     = false;    % component rejection of ICA
do.shortepoching    = false;    % epoch on sample level, remove duplicate triggers and possible re-baseline
do.extract          = false;    % make mat-file for data analysis
do.extractWhat      = 'short'; % 'short','long','resplock'

%% Parpooling

if do.parpooling
    numWorkers = length(params.submat);
    parpool(length(params.submat));
else
    numWorkers = 0;
end

try
    %% 1. Select HEOG data
    
    parfor (s = 1:length(params.submat),numWorkers)
        
        inputfile   = sprintf('Subject%d_Session%d_BarExp.set',params.submat(s),params.session);
        outputfile  = sprintf('Subject%d_Session%d_BarExp_downsampled.set',params.submat(s),params.session);
        
        fEEG_select_eog(params,do,s,inputfile,outputfile);
    end
    
    %% 1. DOWNSAMPLE IMPORTED DATA & REMOVE EXTRA CHANNELS
    
    parfor (s = 1:length(params.submat),numWorkers)
        
        inputfile   = sprintf('Subject%d_Session%d_BarExp.set',params.submat(s),params.session);
        outputfile  = sprintf('Subject%d_Session%d_BarExp_downsampled.set',params.submat(s),params.session);
        
        fEEG_downsample_cnt(params,do,s,inputfile,outputfile);
    end
    
    %% 2. FILTER DATA
    
    parfor (s = 1:length(params.submat),numWorkers)
        
        inputfile   = sprintf('Subject%d_Session%d_BarExp_downsampled.set',params.submat(s),params.session);
        outputfile 	= sprintf('Subject%d_Session%d_BarExp_filtered.set',params.submat(s),params.session);
        
        fEEG_filter(params,do,s,inputfile,outputfile);
    end
    
    %% 5. LONG EPOCHING
    
    parfor (s = 1:length(params.submat),numWorkers)
        
        inputfile   = sprintf('Subject%d_Session%d_BarExp_avref.set',params.submat(s),params.session);
        outputfile 	= sprintf('Subject%d_Session%d_BarExp_longepoched.set',params.submat(s),params.session);
        
        fEEG_longepoch(params,do,s,inputfile,outputfile);
    end
    
    %% 6. REJECT ARTEFACTS (partially manually)
    
    if do.artefact
        
        % partially manual
        % click on bad trials + UPDATE MARKS before closing plot window!!
        % then reject the epochs USING EEG LAB - tools -> reject data epochs -> reject marked epochs
        
        subject = [];
        while isempty(subject)
            subject = input('Which subject? ');
            if ~any(subject == params.submat)
                error('Subject index not found.');
            end
        end
        
        inputfile   = sprintf('Subject%d_Session%d_BarExp_longepoched.set',subject,params.session);
        outputfile	= sprintf('Subject%d_Session%d_BarExp_rejtrials.set',subject,params.session);
        mfile       = sprintf('Subject%d_Session%d_BarExp_rejectedTrials.mat',subject,params.session);
        
        if ~isempty(subject)
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
                clear rejectedTrialz
                rejectedTrialz = [EEG.reject.rejmanual(params.trialz), ones(1,length(EEG.reject.rejmanual)-params.trialz(end))]; % reject extra trials as well
                save(fullfile(params.data.saveEEG,mfile),'rejectedTrialz');
                fprintf('\nRejected trials m-file subject %d saved.\n',subject);
                
                % Reject artefacts
                EEG = pop_rejepoch(EEG,rejectedTrialz);
                
                % Save file
                EEG.setname     = outputfile;
                EEG             = pop_saveset(EEG, outputfile, params.data.saveEEG);
                
                fprintf('\nRejected trials subject %d finished and saved.\n',subject);
                
            end
        end
    end
    
    %% 6a EXTRA: reject trials again
    % After you've done something in the previous steps, but you don't want to
    % manually start rejecting all the trials you've rejected before.
    
    for s = 1:length(params.submat)
        
        inputfile   = sprintf('Subject%d_Session%d_BarExp_longepoched.set',params.submat(s),params.session);
        outputfile	= sprintf('Subject%d_Session%d_BarExp_rejtrials.set',params.submat(s),params.session);
        mfile       = sprintf('Subject%d_Session%d_BarExp_rejectedTrials.mat',params.submat(s),params.session);
        
        fEEG_rejectagain(params,do,s,inputfile,outputfile,mfile);
    end
    
    %% 7. ICA
    
    tic
    
    parfor (s = 1:length(params.submat),numWorkers)
        
        inputfile   = sprintf('Subject%d_Session%d_BarExp_rejtrials.set',params.submat(s),params.session);
        outputfile	= sprintf('Subject%d_Session%d_BarExp_ica.set',params.submat(s),params.session);
        
        fEEG_ica(params,do,s,inputfile,outputfile);
    end
    
    disp('Finished all ICA.');
    elapsedtime = toc;
    fprintf('\nTime elapsed is %.2f minutes or %.2f hours.\n',elapsedtime/60,elapsedtime/60/60);
    
    %% 8. REMOVE ICA COMPONENTS
    
    if do.componentrej
        
        close all
        clear ALLEEG EEG CURRENTSET ALLCOM
        
        subject = [];
        while isempty(subject)
            subject = input('Which subject? ');
            if ~any(subject == params.submat)
                error('Subject index not found.');
            end
        end
        
        inputfile   = sprintf('Subject%d_Session%d_BarExp_ica.set',subject,params.session);
        outputfile	= sprintf('Subject%d_Session%d_BarExp_prunedica.set',subject,params.session);
        mfile       = sprintf('Subject%d_Session%d_BarExp_rejectedComponents.mat',subject,params.session);
        
        if ~isempty(subject)
            disp(' ');
            disp(['Removing components of subject ' num2str(subject)])
            
            % restart eeglab (because of memory issues)
            [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
            
            % load dataset
            EEG = pop_loadset(inputfile, params.data.saveEEG);
            [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, 1);
            
            % Open EEG plot
            pop_selectcomps(EEG,1:35); % plot the component map for selection
            %pop_selectcomps(EEG,1:61); % plot the component map for selection
            %pop_eegplot(EEG, 1, 1, 0); % plot channel data timecourse % change scale to 50 and set full screen
            pop_eegplot(EEG, 0, 1, 0); % plot ICA compoments timecourse % change scale to 10 and set full screen
            pause
            EEG = ALLEEG(2);
            
            % Reject marked epochs
            compsUpdated = questdlg('Done with marking components?');
            if strmatch(compsUpdated, 'Yes')
                
                % Save removed components in m-file
                clear rejectedCompz
                rejectedCompz = find(EEG.reject.gcompreject == 1);
                save(fullfile(params.data.saveEEG,mfile),'rejectedCompz');
                fprintf('\nRemoved components m-file subject %d saved\n', subject);
                
                % Remove components
                EEG = pop_subcomp(EEG);
                
                % Save file
                EEG.setname     = outputfile;
                EEG             = pop_saveset(EEG, outputfile, params.data.saveEEG);
                
                fprintf('\nRemoving %d components from subject %d finished and saved.\n',length(rejectedCompz),subject);
                
            end
        end
    end
    
    %% 9a. SHORT EPOCH
    
    parfor (s = 1:length(params.submat),numWorkers)
        
        inputfile   = sprintf('Subject%d_Session%d_BarExp_prunedica.set',params.submat(s),params.session);
        outputfile	= sprintf('Subject%d_Session%d_BarExp_shortepoched.set',params.submat(s),params.session);
        
        fEEG_shortepoch_BarExp(params,do,s,inputfile,outputfile);
    end
    
    %% 9b. RESPONSE LOCKED

    parfor (s = 1:length(params.submat),numWorkers)
        
        inputfile   = sprintf('Subject%d_Session%d_BarExp_prunedica.set',params.submat(s),params.session);
        outputfile 	= sprintf('Subject%d_Session%d_BarExp_resplocked.set',params.submat(s),params.session);
        mfile       = sprintf('Subject%d_Session%d_BarExp_rejectedTrials.mat',params.submat(s),params.session);
        newmfile    = sprintf('Subject%d_Session%d_BarExp_rejectedTrials_resplock.mat',params.submat(s),params.session);
        
        fEEG_resplocked_BarExp(params,do,s,inputfile,outputfile,mfile,newmfile);
    end   
    
    %% 10. EXTRACT RELEVANT DATA IN MAT-FILE
    
    parfor (s = 1:length(params.submat),numWorkers) 
        
        if strcmp(do.extractWhat,'short')
            inputfile   = sprintf('Subject%d_Session%d_BarExp_shortepoched.set',params.submat(s),params.session);
            outputfile 	= sprintf('Subject%d_Session%d_BarExp_EEG_samples.mat',params.submat(s),params.session);
        elseif strcmp(do.extractWhat,'long')
            inputfile   = sprintf('Subject%d_Session%d_BarExp_prunedica.set',params.submat(s),params.session);
            outputfile 	= sprintf('Subject%d_Session%d_BarExp_EEG_longepoch.mat',params.submat(s),params.session);
        elseif strcmp(do.extractWhat,'resplock')
            inputfile   = sprintf('Subject%d_Session%d_BarExp_resplocked.set',params.submat(s),params.session);
            outputfile 	= sprintf('Subject%d_Session%d_BarExp_EEG_resplock.mat',params.submat(s),params.session);
        end
        
        fEEG_extractmat(params,do,s,inputfile,outputfile);        
    end

    %% End parpool session
    
    if do.parpooling
        delete(gcp());
    end
    
catch ME
    
    if do.parpooling
        delete(gcp());
    end
    
    rethrow(ME)
    disp(' ');
    disp('Try loop failed.');
    
end