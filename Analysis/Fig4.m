%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Evidence accumulation per sample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

do.smooth       = true; % smooth time series?
do.plotting     = true; % plot?
do.signif       = true; % test significance?
do.save_plot    = false; % save plot?

%% Parpooling

if do.parpooling
    numWorkers = length(params.submat);
    parpool(numWorkers);
else
    numWorkers = 0;
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

%% Load model responses

% Load model results
modname = 'Model_SI_full';
load(fullfile(paths.data.model,modname));

% Get model choices
estY    = 0.*data.respside;
estX    = 0.*data.sample;
cumX    = 0.*data.sample;
data.DV = cat(3,data.leftDV,data.rightDV);

for s = 1:params.nsubj
    
    modparam = [model.w(s) model.leak(s) model.noise(s) model.lapse(s)];
    
    idx = data.sub == params.submat(s) & data.cor >= 0;
    [estY(idx),estX(idx,:,:),cumX(idx,:,:)] = Model_SelectiveIntegration(modparam,data.DV(idx,:,:));
end

model.diffDV    = estX(:,:,2) - estX(:,:,1);
model.cumdiffDV = diff(cumX(:,:,:),[],3); % model

%%

% Use model transformed values as input
whichRegression   	= 2; % 1 = generative, 2 = model
regr_namez          = {'gen','mod'};

% Normalise cumulative data
cdDV    = 0*data.cumdiffDV;
dDV     = 0*data.diffDV;

if whichRegression == 1
    cumdiffDV   = data.cumdiffDV;
    diffDV      = data.diffDV;
elseif whichRegression == 2
    cumdiffDV   = model.cumdiffDV;
    diffDV      = model.diffDV;
end

for s = 1:params.nsubj
    idx             = data.sub == params.submat(s);
    cdDV(idx,:)     = zscore(abs(cumdiffDV(idx,:)));
    dDV(idx,:)      = zscore(abs(diffDV(idx,:)));
end

% Regression matrix (trial x regressor x sample)
whichData   = 2:9; % which samples to use as regressors
X           = zeros(size(cdDV,1),3,length(whichData));

for f = 1:length(whichData)
    X(:,:,f) = [ones(size(cdDV,1),1), cdDV(:,whichData(f)-1) dDV(:,whichData(f))];
end

outputname          = sprintf('ERP_abscumdiff_n-1_diffDV_i_%s',regr_namez{whichRegression});
params.datatype     = 'EEG';
params.whichSamp    = 2:9; % which samples to use from EEG   -> sample 9 very often has same final value!
data.filename       = 'samples'; % name of eeg file to read

params.add_eog      = false; % add eog as regressor
params.resids       = false; % calculate residuals
params.sse          = false; % calculate SSE?

params.extra_idx    = data.respside == 1 | data.respside == 2;

%% Subject loop for regression

if do.regression
    
    try
        
        tic % get current time
        
        Betas   = nan(60,length(timepoints),size(X,3),size(X,2),params.nsubj);
        SSE     = nan(60,length(timepoints),size(X,3),params.nsubj);
        resids  = [];
        
        % Subject regression
        for combo = 1:params.nsubj %parfor (combo = 1:params.nsubj, numWorkers)
            [Betas(:,:,:,:,combo), resids] = SampleRegression(combo,X,data,params,paths);
            
            if params.resids
                outputname_resids = sprintf('%s_sub%03d_resids',outputname,params.submat(combo));
                save(fullfile(paths.data.saveEEG,outputname_resids),'resids');
                fprintf('\nResiduals saved sub %d.\n',params.submat(combo));
            end
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
    
else % load Betas
    load(fullfile(paths.data.saveEEG,outputname));
end

%% Plotting

if do.plotting
    
    %% Channels to plot
    
    leftPO      = label2index({'TP7' 'CP5' 'P7' 'P5' 'PO7' 'PO5' 'O1'},{chanlocs.labels}); % left occipito-parietal
    rightPO     = label2index({'TP8' 'CP6' 'P8' 'P6' 'PO8' 'PO6' 'O2'},{chanlocs.labels}); % right occipito-parietal
    central     = label2index({'CZ'},{chanlocs.labels});
    
    [new_chanlocs] = fEEG_midlineflip(chanlocs);
 
     %% Betas over time (lines)
     
	whichRegr   = 2;
    whichSamp   = 1:8; % is samples 2 to 9
    
    timewdw     = [-100 750];
    timeidx     = timepoints <= timewdw(end);
    tp          = timepoints(timeidx);
    
    plotdat     = squeeze(mean(mean(Betas(central,timeidx,whichSamp,whichRegr,:),1),3));
    
    if do.smooth
        cutoff      = 25;
        samprate    = 250;
        smoothdat   = lowpass(plotdat,cutoff,samprate);
    else
        smoothdat   = plotdat;
    end
    
    smoothdat   = permute(smoothdat,[2,1]);
    
    ylims       = [-0.06 .14];
    masstest    = 'cluster';
    do.signif   = true;
    linecolz    = modcol(1,:);
    
	figE = figure;
    [steh] = fEEG_steplot(smoothdat,tp,ylims,do.signif,masstest,linecolz,[],'bottom');
         
    ax = gca;
    set(ax,'FontSize',axlabelfntsz,'LineWidth',1.5);
    set(ax,'XTick',-100:100:750,'YTick',-.04:.02:.14);
    xlabel('Time from sample onset (ms)','FontSize',24);
    ylabel('Parameter estimate (z)','FontSize',24);
    
    legnamez = {'$\sum\limits_{i=1}^{k-1} I^B_i - I^A_i$'};
    [hL, hObj]  = legend(steh,legnamez,'FontSize',24,'Location','NorthEast','Box','Off','Interpreter','Latex');
    set(hObj(2),'LineWidth',5);
    
    if do.save_plot
        save2eps(figE,paths.figures.current,'Timeseries_cumDV_samples',[.1 .1 600 400]);
    end
    
   %% Scalp plot
    
    %eeglab % run this once for function to work
    %close
    
    whichRegr   = 2;
    timewdw     = [224 388]; % significant time window
    timeidx     = timepoints >= timewdw(1) & timepoints <= timewdw(end);
    windat      = squeeze(mean(mean(Betas(:,timeidx,:,whichRegr,:),2),3));
    
    tdat        = ttransform(windat');
    
    maplims     = [-4 4];
    
    % Egghead plot
    eggheadplot('Channels', {chanlocs.labels}, 'Amplitude', tdat, 'Method', 'natural', 'Scale', maplims, 'Contours', 0, 'FillColor', [1 1 1], 'MapStyle', 'jet', 'Style', 'Full', 'ElectrodeSize', 10, 'ShowBrain','No','Smooth',50);
    axis equal
    
    ct = flipud(cbrewer('div', 'RdYlBu', 100));
    colormap(ct);
    
    if do.save_plot
        save2tiff(gcf,paths.figures.current,'Topo_cumdiffDV',[.1 .1 400 300]);
    end
    
end