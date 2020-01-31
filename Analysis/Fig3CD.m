%%%%%%%%%%%%
%% Fig 3C-D
%%%%%%%%%%%%

%% LOAD DATA

clc
clear

% Paths
eegfolder       = 'EEG_TF_samples';
saveEEGfolder   = 'EEG_outcomes_regressions';
figfolder       = 'EEG_regressions';

% Load stuff
Load_vars; % load data and path
Config_plot; % load plot variables

% Logicals
do.parpooling   = false; % parallel processing?

do.regression   = true; % run regression?
do.save_betas   = false; % save betas?
do.save_eog     = false; % save averaged eog?

do.smooth       = true; % smooth time series?
do.interp       = true; % do interpolation for visualization?
do.plotting     = true; % plot?
do.signif       = true; % test significance?
do.save_plot    = true; % save plot?

%% Parpooling

if do.parpooling
    numWorkers = length(params.submat);
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

%% Extra variables

params.nfreq            = 11;
freqrange               = 8:3:38;
params.tp               = timepoints*1000;

lowindx                 = data.frame == 0; % low frame

% PV and DV
data.leftPV             = data.sample(:,:,1);
data.rightPV            = data.sample(:,:,2);
data.leftDV             = data.leftPV;
data.rightDV            = data.rightPV;
data.leftDV(lowindx,:)  = 200-data.leftPV(lowindx,:); % flip for low frame
data.rightDV(lowindx,:) = 200-data.rightPV(lowindx,:); % flip for low frame

% Cumulative difference DV
data.diffDV             = data.rightDV - data.leftDV;
data.cumdiffDV          = cumsum(data.diffDV,2);

% Trial mean
Lmean                   = mean(data.leftDV,2);
Rmean                   = mean(data.rightDV,2);
Tmean                   = mean([Lmean, Rmean],2);

% Categorical winner/loser
Iwin                    = sign(data.diffDV);
Iwin(Iwin < 0)          = 0;
Ilose                   = 1-Iwin;

% Parametric regressors DV
lDV                     = bsxfun(@minus,data.leftDV,Tmean);
lDVwin                  = abs(lDV);
lDVlose                 = abs(lDV);
rDV                     = bsxfun(@minus,data.rightDV,Tmean);
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
X = cat(3,Iwin,Ilose,lDVwin,lDVlose,rDVwin,rDVlose);
X = repmat(permute(X,[1,3,2]),1,1,1,params.nfreq);

% Settings for regression
outputname          = 'TF_winlose_abseog';
params.whichSamp    = 1:params.nsamp; % which samples to use
params.add_eog      = true; % add eog as regressor

params.extra_idx    = data.respside == 1 | data.respside == 2;

%% Subject loop for regression

if do.regression
    
    try
        
        tic % get current time
        
        data.filename   = 'samples';
        data.basewdw    = []; % baseline window (in seconds)
        
        if params.add_eog
            Betas   = nan(length(chanlocs),length(params.tp),params.nsamp,params.nfreq,size(X,2)+2,params.nsubj);
        else
            Betas   = nan(length(chanlocs),length(params.tp),params.nsamp,params.nfreq,size(X,2),params.nsubj);
        end
        
        % Subject regression
        for combo = 1:params.nsubj %parfor (combo = 1:params.nsubj, numWorkers)
            Betas(:,:,:,:,:,combo) = SampleRegression_TF(combo,X,data,params,paths); %
        end
        
        % Save results
        if do.save_betas
            save(fullfile(paths.data.saveEEG,outputname),'Betas');
            disp('Betas saved.');
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
    
    %% End parpool session
    if do.parpooling
        delete(gcp);
    end
    
else % load Betas
    load(fullfile(paths.data.saveEEG,outputname));
end

%% Plotting

if do.plotting
    
    %% Labels
    
    leftPO      = label2index({'TP7' 'CP5' 'P7' 'P5' 'PO7' 'PO5' 'O1'},{chanlocs.labels}); % left occipito-parietal
    rightPO     = label2index({'TP8' 'CP6' 'P8' 'P6' 'PO8' 'PO6' 'O2'},{chanlocs.labels}); % right occipito-parietal
    
    % Flipped electrodes
    new_chanlocs = fEEG_midlineflip(chanlocs);
    
    %% Fig 3C: parametric
    
    winRegr     = [3,5];
    loseRegr    = [4,6];
    whichSamp   = 1:params.nsamp;
    timeidx     = 1:length(params.tp);
    tp          = params.tp(timeidx);
    windat      = squeeze(mean(mean(Betas(rightPO,timeidx,whichSamp,:,winRegr(1),:),3)) + mean(mean(Betas(leftPO,timeidx,whichSamp,:,winRegr(2),:),3)));
    losedat     = squeeze(mean(mean(Betas(rightPO,timeidx,whichSamp,:,loseRegr(1),:),3)) + mean(mean(Betas(leftPO,timeidx,whichSamp,:,loseRegr(2),:),3)));
    diffdat     = windat - losedat;
    
    % Smooth data
    if do.smooth
        wdwsz(1)    = round(300/25); % time
        wdwsz(2)    = 3; % frequencies
        fwhm(1)     = round(.33*wdwsz(1));
        fwhm(2)     = round(.33*wdwsz(2));
        smoothdat   = smoothTF(diffdat,wdwsz,fwhm);
        testdat     = permute(smoothdat,[3,1,2]);
        plotdat     = ttransform(testdat);
    else
        testdat     = permute(diffdat,[3,1,2]);
        plotdat     = ttransform(testdat);
    end
    
    % Interpolation for visualization
    if do.interp
        k           = 3;
        plotdat     = interp2(plotdat,k);
        
        time_interp = linspace(tp(1),tp(end),size(plotdat,1));
        freq_interp = linspace(freqrange(1),freqrange(end),size(plotdat,2));
    else
        time_interp = tp;
        freq_interp = freqrange;
    end
    
    % Cluster testing
    if do.signif
        
        nit         = 5000;
        p_thresh    = .025;
        p_crit      = p_thresh;
        
        fprintf('\nRunning cluster correction (n = %d), p_crit = %s, p_thresh = %s.\n',nit,num2str(p_crit),num2str(p_thresh));
        
        [p,praw]    = ClusterCorrection2(testdat,nit,p_crit,p_thresh);
        pmask       = double(squeeze(p <= p_thresh)); % 0 = not significant
        
    end
    
    figure;
    
    % colormap
    ct          = flipud(cbrewer('div', 'RdYlBu', 100));
    colormap(ct);
    
    maplims     = [-3 3];
    
    hm          = imagesc(time_interp,freq_interp,plotdat',maplims);  hold on;
    axis xy
    plot([0,0],[freqrange(1)-1.5,freqrange(end)+1.5],'k-','LineWidth',1.5);
    hC = colorbar;
    
    if do.signif
        pline = imcontour(tp,freqrange,pmask',1,'w--','LineWidth',3);
    end
    
    ax = gca;
    set(ax,'FontSize',axlabelfntsz);
    xlabel('Time from stimulus onset (ms)','FontSize',20);
    ylabel('Frequencies (Hz)','FontSize',20);
    ylabel(hC,'t-values','FontSize',axlabelfntsz);
    
    set(ax,'XTick',-100:100:750);
    
    if do.save_plot
        save2tiff(gcf,paths.figures.current,'Param_alpha_p025',[.1 .1 650 400]);
    end
    
    %% Fig 3C: scalp plot
    
    eeglab; % run once
    close
    
    whichFreq   = freqrange == 11;
    winRegr     = [3,5];
    loseRegr    = [4,6];
    whichSamp   = 1:params.nsamp;
    timewdw     = [300 700];
    timeidx     = params.tp >= timewdw(1) & params.tp <= timewdw(end);
    tp          = params.tp(timeidx);
    windat      = squeeze(mean(mean(Betas(new_chanlocs,timeidx,whichSamp,whichFreq,winRegr(1),:),2),3) + mean(mean(Betas(:,timeidx,whichSamp,whichFreq,winRegr(2),:),2),3));
    losedat     = squeeze(mean(mean(Betas(:,timeidx,whichSamp,whichFreq,loseRegr(1),:),2),3) + mean(mean(Betas(new_chanlocs,timeidx,whichSamp,whichFreq,loseRegr(2),:),2),3));
    diffdat     = windat - losedat;
    
    tdat        = ttransform(diffdat'-diffdat(new_chanlocs,:)');
    tdat(isnan(tdat)) = 0;
    
    maplims     = [-3 3];
    
    % Egghead plot
    eggheadplot('Channels', {chanlocs.labels}, 'Amplitude', tdat, 'Method', 'natural', 'Scale', maplims, 'Contours', 0, 'FillColor', [1 1 1], 'MapStyle', 'jet', 'Style', 'Full', 'ElectrodeSize', 10, 'ShowBrain','No','Smooth',50);
    axis equal
    
    ct = flipud(cbrewer('div', 'RdYlBu', 100));
    colormap(ct);
    
    if do.save_plot
        save2tiff(gcf,paths.figures.current,sprintf('Topo_alpha_param_diff_%dHz',freqrange(whichFreq)),[.1 .1 400 300]);
    end
    
    %% Fig 3D: intercept
    
    winRegr     = 1;
    loseRegr    = 2;
    whichSamp   = 1:params.nsamp;
    timeidx     = 1:length(params.tp);
    tp          = params.tp(timeidx);
    windat      = squeeze(mean(mean(Betas(leftPO,timeidx,whichSamp,:,winRegr,:),3)) + mean(mean(Betas(rightPO,timeidx,whichSamp,:,loseRegr,:),3)));
    losedat     = squeeze(mean(mean(Betas(rightPO,timeidx,whichSamp,:,winRegr,:),3)) + mean(mean(Betas(leftPO,timeidx,whichSamp,:,loseRegr,:),3)));
    diffdat     = windat - losedat;
    
    plotdat     = ttransform(permute(diffdat,[3,1,2]));
    
    tmpval      = max(abs([min(plotdat(:)) max(plotdat(:))]));
    maplims     = [-3 3];
    
    % Smooth data
    if do.smooth
        wdwsz(1)    = round(300/25); % time
        wdwsz(2)    = 3; % frequencies
        fwhm(1)     = round(.33*wdwsz(1));
        fwhm(2)     = round(.33*wdwsz(2));
        smoothdat   = smoothTF(diffdat,wdwsz,fwhm);
        testdat     = permute(smoothdat,[3,1,2]);
        plotdat     = ttransform(testdat);
    else
        testdat     = permute(diffdat,[3,1,2]);
        plotdat     = ttransform(testdat);
    end
    
    % Interpolation for visualization
    if do.interp
        k           = 3;
        plotdat     = interp2(plotdat,k);
        
        time_interp = linspace(tp(1),tp(end),size(plotdat,1));
        freq_interp = linspace(freqrange(1),freqrange(end),size(plotdat,2));
    else
        time_interp = tp;
        freq_interp = freqrange;
    end
    
    % Cluster testing
    if do.signif
        
        nit         = 5000;
        p_thresh    = .025;
        p_crit      = p_thresh;
        
        fprintf('\nRunning cluster correction (n = %d), p_crit = %s, p_thresh = %s.\n',nit,num2str(p_crit),num2str(p_thresh));
        
        [p,praw]    = ClusterCorrection2(testdat,nit,p_crit,p_thresh);
        pmask       = double(squeeze(p <= p_thresh)); % 0 = not significant
        
    end
    
    figure;
    
    % colormap
    ct          = flipud(cbrewer('div', 'RdYlBu', 200));
    colormap(ct);
    
    hm          = imagesc(time_interp,freq_interp,plotdat',maplims);  hold on;
    plot([0,0],[freqrange(1)-1.5,freqrange(end)+1.5],'k-','LineWidth',1.5);
    axis xy
    hC = colorbar;
    
    if do.signif
        pline = imcontour(tp,freqrange,pmask',1,'w--','LineWidth',3);
    end
    
    ax = gca;
    set(ax,'FontSize',axlabelfntsz);
    xlabel('Time from stimulus onset (ms)','FontSize',20);
    ylabel('Frequencies (Hz)','FontSize',20);
    ylabel(hC,'t-values','FontSize',axlabelfntsz);
    
    set(ax,'XTick',-100:100:750);
    
    if do.save_plot
        save2tiff(gcf,paths.figures.current,'Intercept_alpha_p025',[.1 .1 650 400]);
    end
    
    %% Fig 3D: scalp plot
    
    eeglab % run once
    close
    
    whichFreq   = freqrange == 11;
    whichSamp   = 1:params.nsamp;
    
    % Get difference of both signals
    whichRegr   = [1,2];
    timewdw     = [300 700];
    timeidx     = params.tp >= timewdw(1) & params.tp <= timewdw(end);
    xdat        = squeeze(mean(mean(Betas(:,timeidx,whichSamp,whichFreq,whichRegr,:),2),3));
    diffdat     = squeeze(xdat(:,1,:) + xdat(new_chanlocs,2,:));
    
    tdat        = ttransform(diffdat'-diffdat(new_chanlocs,:)'); % contra-ipsi
    tdat(isnan(tdat)) = 0;
    
    maplims     = [-3 3];
    
    % Egghead plot
    eggheadplot('Channels', {chanlocs.labels}, 'Amplitude', tdat, 'Method', 'natural', 'Scale', maplims, 'Contours', 0, 'FillColor', [1 1 1], 'MapStyle', 'jet', 'Style', 'Full', 'ElectrodeSize', 10, 'ShowBrain','No','Smooth',50);
    axis equal
    
    ct = flipud(cbrewer('div', 'RdYlBu', 100));
    colormap(ct);
    
    if do.save_plot
        save2tiff(gcf,paths.figures.current,sprintf('Topo_alpha_intercept_diff_%dHz',freqrange(whichFreq)),[.1 .1 400 300]);
    end
    
end

