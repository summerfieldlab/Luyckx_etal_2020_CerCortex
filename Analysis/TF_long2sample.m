%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BarExp - EEG: long epoch TF to sample TF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% LOAD DATA

clc
clear
%close all

% Logicals
eegfolder           = 'EEG_TF_long';
savefolder          = 'EEG_TF_samples';

% Load stuff
Load_vars; % load data and path

% Logicals
do.save_data    = true; % save sample data?

%% Load subject data and indices

data.filename   = 'long';
freqrange       = 8:3:38;
params.nfreq    = length(freqrange);
basewdw         = [-300 300];
sampwdw         = [-100 750];
tp              = timepoints*1000;

for s = 1:params.nsubj
    for sess = 1:params.nsessions
          
        clear tfa tfdat
        
        fprintf('\nChunking subject %d, session %d\n',params.submat(s),sess);
        
        % Load EEG data
        load(fullfile(paths.data.EEG,sprintf('Sub%d_sess%d_8-38_long.mat',params.submat(s),sess)));
        
        % Load bad trials
        rejfile = dir(fullfile(paths.data.EEG,sprintf('Subject%d_Session%d_BarExp_rejectedTrials*.mat',params.submat(s),sess)));
        load(rejfile.name);
                
        % Get indices
        goodtrials  = 1 - rejectedTrialz(1:params.ntrials);
        idx         = data.sub == params.submat(s) & data.session == sess;
        
        goodidx = logical(goodtrials');        
        gapz    = data.randgap(idx,:);
        goodgapz = gapz(goodidx,:);
        ntrials = size(tfa.data,1);
        nchan   = size(tfa.data,2);
        nfreq   = size(tfa.data,3);
        ntime   = sum(abs(sampwdw/25))+1;
        tfdat   = zeros(ntrials,nchan,nfreq,ntime,params.nsamp);
        
        % Baseline data
        basedat = baseline_tf(tfa.data,tp,basewdw);
        
        % Chunck data based on random gaps 
        startepoch  = 350; % 300 ms fix + 50 ms mask
        sampdur     = 350; % sample duration 350 ms
        maskdur     = 50; % mask duration 50 ms
        for t = 1:ntrials
            for n = 1:params.nsamp
                samponset           = startepoch + sum(goodgapz(t,1:n-1)) + sampdur*(n-1) + maskdur*(n-1);
                [~,besttp]          = min(abs(tp-samponset)); % find closest value
                sampidx             = besttp+(sampwdw(1)/25):besttp+(sampwdw(end)/25);
                tfdat(t,:,:,:,n)    = tfa.data(t,:,:,sampidx);
            end
        end
        
        % Put in right structure
        tfa.data        = tfdat;
        tfa.timepoints  = linspace(sampwdw(1),sampwdw(end),ntime)/1000;
             
        % Save data
        if do.save_data
            outputname = sprintf('Sub%d_sess%d_8-38_samples.mat',params.submat(s),sess);
            save(fullfile(paths.data.saveEEG,outputname),'tfa');
            fprintf('\nSample data subject %d, session %d saved.\n',params.submat(s),sess);
        end
        
    end
    
end