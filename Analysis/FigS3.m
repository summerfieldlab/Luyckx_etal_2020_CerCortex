%%%%%%%%%%%%
%% Fig 3A-B
%%%%%%%%%%%%

%% LOAD DATA

clc
clear

% Paths
eegfolder       = 'EEG_samples';
saveEEGfolder   = 'EEG_outcomes_regressions';
figfolder       = 'EEG_regressions';

% Load stuff
Load_vars; % load data and path
Config_plot; % load plot variables

% Logicals
do.parpooling   = false; % parallel processing?

do.regression   = false; % run regression?
do.save_betas   = true; % save betas?
do.save_eog     = false; % save averaged eog?

do.smooth       = true; % smooth time series?
do.plotting     = true; % plot?
do.signif       = true; % test significance?
do.save_plot    = false; % save plot?

%% Parpooling

if do.parpooling
    numWorkers = params.nsubj;
    parpool(numWorkers);
else
    numWorkers = 0;
end

%% Load eye-tracking data

timewdw         = 226+[-50 +50]; % mean peak at 224-228
timeidx         = timepoints >= timewdw(1) & timepoints <= timewdw(end);

paths.data.EOG          = fullfile(paths.data.main,'EOG_samples');
params.eog_filename     = sprintf('EOG_samples_av_%d-%dms',timewdw);
eogdata                 = {};

if do.save_eog
    
    for s = 1:params.nsubj
        
        fprintf('\n Loading EOG subject %d.\n',s);
        
        erpdata         = [];
        goodtrials      = [];
        
        for sess = 1:2
            
            % Load EOG data
            load(fullfile(paths.data.EOG,sprintf('Subject%d_Session%d_BarExp_EOG_samples.mat',params.submat(s),sess)));
            
            % Load bad trials
            rejfile = dir(fullfile(paths.data.EOG,sprintf('Subject%d_Session%d_BarExp_rejectedTrials*.mat',params.submat(s),sess)));
            load(rejfile.name);
            
            % Good trials
            tmpGood     = 1-rejectedTrialz(1:params.ntrials);
            goodtrials  = cat(2,goodtrials,tmpGood);
            
            % Variables
            ntimepoints = length(eeg.timepoints); % number of time points in epoch
            rtrials     = length(find(tmpGood == 1)); % number of preserved trials
            
            % Reshape
            if sum(tmpGood) ~= size(eeg.data,3)
                tmpErp  = reshape(eeg.data,[eeg.nbchan,ntimepoints,params.nsamp,rtrials]);
                erpdata = cat(4,erpdata,tmpErp); % (nchannels x ntimepoints (x nsamp) x ntrials(*nsessions))
            else
                erpdata = cat(3,erpdata,eeg.data); % (nchannels x ntimepoints (x nsamp) x ntrials(*nsessions))
            end
            
        end
        
        eogdata{s} = squeeze(mean(erpdata(:,timeidx,:,:),2));
        
    end
    
    save(fullfile(paths.data.EOG,params.eog_filename),'eogdata');
    fprintf('\n Saved EOG data.\n');
end

%% Create design matrix

lowindx                 = data.frame == 0; % low frame

% PV and DV
data.leftPV             = data.sample(:,:,1);
data.rightPV            = data.sample(:,:,2);
data.leftDV             = data.leftPV;
data.rightDV            = data.rightPV;
data.leftDV(lowindx,:)  = 200-data.leftPV(lowindx,:); % flip for low frame
data.rightDV(lowindx,:) = 200-data.rightPV(lowindx,:); % flip for low frame
data.diffDV             = data.rightDV - data.leftDV;
data.cumdiffDV          = cumsum(data.diffDV,2);

% Subject data
X   = cat(3,data.leftDV,data.rightDV);
Y   = data.respside - 1;

% Get model choices
modname = 'Model_SI_full'; % full model
load(fullfile(paths.data.model,modname));

estY    = 0.*Y;
estX    = 0.*X;

for s = 1:params.nsubj
    
    modparam = [model.w(s) model.leak(s) model.noise(s) model.lapse(s)];
    
    idx = data.sub == params.submat(s) & Y >= 0;
    [estY(idx), estX(idx,:,:)] = Model_SelectiveIntegration(modparam,X(idx,:,:));
end

mods.leftDV             = estX(:,:,1);
mods.rightDV            = estX(:,:,2);
mods.diffDV             = mods.rightDV - mods.leftDV;

% Trial mean
Lmean                   = mean(mods.leftDV,2);
Rmean                   = mean(mods.rightDV,2);
Tmean                   = mean([Lmean, Rmean],2);

% Categorical winner/loser
Iwin                    = sign(mods.diffDV);
Iwin(Iwin < 0)          = 0;
Ilose                   = 1-Iwin;

% Parametric regressors DV
lDV                     = bsxfun(@minus,mods.leftDV,Tmean);
lDVwin                  = abs(lDV);
lDVlose                 = abs(lDV);
rDV                     = bsxfun(@minus,mods.rightDV,Tmean);
rDVwin                  = abs(rDV);
rDVlose                 = abs(rDV);

lDVwin                  = lDVwin .* Ilose; % left DV when left wins
lDVlose                 = lDVlose .* Iwin; % left DV when left loses
rDVwin                  = rDVwin .* Iwin; % right DV when right wins
rDVlose                 = rDVlose .* Ilose; % right DV when right loses

% Normalise for each intercept (per sample)
for s = 1:params.nsubj
    for f = 1:params.nsamp
        Widx = data.sub == params.submat(s) & Iwin(:,f) == 1; % right stream wins, left stream loses
        Lidx = data.sub == params.submat(s) & Iwin(:,f) == 0; % right stream loses, left stream wins
        
        lDVwin(Lidx,f)  = zscore(lDVwin(Lidx,f)); % sample left wins
        lDVlose(Widx,f) = zscore(lDVlose(Widx,f)); % sample right wins
        rDVwin(Widx,f)  = zscore(rDVwin(Widx,f)); % sample right wins
        rDVlose(Lidx,f) = zscore(rDVlose(Lidx,f)); % sample left wins
    end
end

% Regression matrix (trial x regressor x sample)
X_mod = cat(3,Iwin,Ilose,lDVwin,lDVlose,rDVwin,rDVlose);
X_mod = permute(X_mod,[1,3,2]);

% Settings for regression
outputname          = 'ERP_winlose_transf_abseog';
data.filename       = 'samples'; % name of eeg file to read
params.datatype     = 'EEG'; % EEG/EOG
params.whichSamp    = 1:9; % which samples to use from EEG   -> sample 9 very often has same final value!
params.add_eog      = true; % add eog as regressor

params.resids       = false; % calculate residuals?
params.sse          = false; % calculate SSE?

params.extra_idx    = data.respside == 1 | data.respside == 2;

%% Subject loop for regression

if do.regression
    
    try
        
        tic % get current time
        
        if params.add_eog
            Betas = nan(60,length(timepoints),size(X_mod,3),size(X_mod,2)+2,params.nsubj);
        else
            Betas = nan(60,length(timepoints),size(X_mod,3),size(X_mod,2),params.nsubj);
        end
        
        % Subject regression
        parfor (combo = 1:params.nsubj, numWorkers)
            Betas(:,:,:,:,combo) = SampleRegression(combo,X_mod,data,params,paths);
        end
        
        % Save results
        if do.save_betas
            save(fullfile(paths.data.saveEEG,outputname),'Betas');
        end
        
        % Wrap up
        disp('Finished all regressions.');
        elapsedtime = toc;
        fprintf('\nTime elapsed is %.2f minutes or %.2f hours.\n',elapsedtime/60,elapsedtime/60/60);
        
    catch ME
        % End parpool session
        if do.parpooling
            delete(gcp);
        end
        disp('Try loop failed.');
        
        elapsedtime = toc;
        fprintf('\nTime elapsed is %.2f minutes or %.2f hours.\n',elapsedtime/60,elapsedtime/60/60);
        
        rethrow(ME)
    end
    
    % End parpool session
    if do.parpooling
        delete(gcp);
    end
    %%
else % load Betas
    load(fullfile(paths.data.saveEEG,outputname));
end

%% Plotting

if do.plotting
    
    %% Channels to plot
    
    leftPO      = label2index({'TP7' 'CP5' 'P7' 'P5' 'PO7' 'PO5' 'O1'},{chanlocs.labels}); % left occipito-parietal
    rightPO     = label2index({'TP8' 'CP6' 'P8' 'P6' 'PO8' 'PO6' 'O2'},{chanlocs.labels}); % right occipito-parietal
    
    [new_chanlocs] = fEEG_midlineflip(chanlocs);
    
    %% Fig 3A: betas over time (parametric)
    
    clear sigY
    
    whichSamp   = 1:params.nsamp;
    winRegr     = [3,5];
    loseRegr    = [4,6];
    do.signif   = true;
    masstest    = 'cluster';
    
    timewdw     = [-100 750];
    timeidx     = timepoints <= timewdw(end);
    tp          = timepoints(timeidx);
    
    windat      = squeeze(mean(mean(Betas(rightPO,timeidx,whichSamp,winRegr(1),:) + Betas(leftPO,timeidx,whichSamp,winRegr(2),:)),3)); % lDVwin (rightPO) + rDVwin (leftPO)
    losedat     = squeeze(mean(mean(Betas(rightPO,timeidx,whichSamp,loseRegr(1),:) + Betas(leftPO,timeidx,whichSamp,loseRegr(2),:)),3)); % lDVlose (rightPO) + rDVlose (leftPO)
    
    if do.smooth
        cutoff      = 25;
        samprate    = 250;
        smoothwin   = lowpass(windat,cutoff,samprate);
        smoothlose  = lowpass(losedat,cutoff,samprate);
        diffdat     = smoothwin' - smoothlose';
        sepdat      = cat(3,smoothwin',smoothlose');
    else
        diffdat     = windat' - losedat';
        sepdat      = cat(3,windat',losedat');
    end
    
    % Plot time series separate
    p_crit      = .05;
    ylims       = [-.7 .25];
    
    % Get significance of difference
    if do.signif
        figure;
        [~,sigp] = fEEG_steplot(diffdat,tp,ylims,do.signif,masstest,colz,p_crit);
        sigX = sigp.XData;
        sigY = sign(sigp.YData);
        close
    end
    
    % Plot signals
    figS        = figure;
    [steh,sigp] = fEEG_steplot(sepdat,tp,ylims,do.signif,masstest,colz,p_crit,'bottom');
    
    ax = gca;
    set(ax,'FontSize',axlabelfntsz,'LineWidth',1.5);
    set(ax,'XTick',-100:100:750);
    xlabel('Time from sample onset (ms)','FontSize',24);
    ylabel('Parameter estimate (z)','FontSize',24);
    
    legnamez = {'X_{win}','X_{lose}'};
    [hL, hObj]  = legend(fliplr(steh),fliplr(legnamez),'FontSize',24,'Location','SouthEast','Box','Off');
    set(hObj(3),'LineWidth',5);
    set(hObj(5),'LineWidth',5);
    
    if exist('sigY','var')
        minX = min(sigX(sigY==1));
        maxX = max(sigX(sigY==1));
        sigfill = fill([minX maxX maxX minX],[min(ylims),min(ylims) max(ylims) max(ylims)],[.5 .5 .5],'Edgecolor','none','FaceAlpha',.25);
        uistack(sigfill,'bottom');
    end
    
    if do.save_plot
        save2eps(figS,paths.figures.current,'Sample_parametric_winlose_transformedvals',[.1 .1 650 400]);
    end
    
    %% Bar plot difference parametric
    
    clear sigY
    
    whichSamp   = 1:params.nsamp;
    winRegr     = [3,5];
    loseRegr    = [4,6];
    
    timewdw     = [200 250];
    timeidx     = timepoints >= timewdw(1) & timepoints <= timewdw(end);
    tp          = timepoints(timeidx);
    
    windat      = squeeze(mean(mean(mean(Betas(rightPO,timeidx,whichSamp,winRegr(1),:) ...
                    + Betas(leftPO,timeidx,whichSamp,winRegr(2),:)),3),2)); % lDVwin (rightPO) + rDVwin (leftPO)
    losedat     = squeeze(mean(mean(mean(Betas(rightPO,timeidx,whichSamp,loseRegr(1),:) ...
                    + Betas(leftPO,timeidx,whichSamp,loseRegr(2),:)),3),2)); % lDVlose (rightPO) + rDVlose (leftPO)
    
    ci_win      = 1.96.*std(windat)./sqrt(params.nsubj);
    ci_lose     = 1.96.*std(losedat)./sqrt(params.nsubj);
    
    % Plot differences
    figB = figure; hold on
    
    M   = mean([windat,losedat]);
    CI  = [ci_win,ci_lose];
    
    for b = 1:2
        bar(b,M(b),.4,'FaceColor',colz(b,:),'LineWidth',1.5);
        errorbar(b,M(b),CI(b),'ko','MarkerSize',0.01,'LineWidth',1.5);
    end
    xlim([.5 2.5]);
    ax = gca;
    set(ax,'XTick',[],'XAxisLocation','top','LineWidth',1.5,'FontSize',20);
    
    if do.save_plot
        save2eps(figB,paths.figures.current,'Param_transvals_bar_200-250ms',[.1 .1 300 300]);
    end

end