%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% HEOG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% LOAD DATA

clc
clear

% Paths
eegfolder       = 'EOG_samples';
saveEEGfolder   = 'EOG_outcomes_regressions';
figfolder       = 'EOG_regressions';

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

%%

% Normalise data
dDV         = 0*data.diffDV;

for s = 1:params.nsubj
    idx             = data.sub == params.submat(s);
    dDV(idx,:)      = zscore(abs(data.diffDV(idx,:)));
end

% Regression matrix (trial x regressor x sample)
whichData   = 1:9; % which samples to use as regressors
X           = zeros(size(dDV,1),3,length(whichData));

for f = 1:length(whichData)
    X(:,:,f) = [ones(size(dDV,1),1), sign(data.diffDV(:,whichData(f))), dDV(:,whichData(f))];
end

outputname          = 'HEOG_signdiffDV_absdiffDV';
params.datatype     = 'EOG';
params.whichSamp    = 1:9; % which samples to use from EEG   -> sample 9 very often has same final value!
data.filename       = 'samples'; % name of eeg file to read

params.resids       = false; % calculate residuals?
params.sse          = false; % calculate SSE?

params.extra_idx    = data.respside == 1 | data.respside == 2;

%% Subject loop for regression

if do.regression
    
    try
        
        tic % get current time
        
        Betas   = nan(1,length(timepoints),size(X,3),size(X,2),params.nsubj);
        SSE     = [];
        
        % Subject regression
        for combo = 1:params.nsubj %parfor (combo = 1:params.nsubj, numWorkers)
            [Betas(:,:,:,:,combo)] = SampleRegression(combo,X,data,params,paths);
        end
        
        % Save results
        if do.save_betas
            save(fullfile(paths.data.saveEEG,outputname),'Betas','SSE');
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

%%

if do.plotting
    
    whichRegr = [3 2];
    whichSamp = 1:9;
    plotdat = squeeze(mean(Betas(:,:,whichSamp,whichRegr,:),3));
    
    if do.smooth
        cutoff      = 25;
        samprate    = 250;
        smoothdat   = lowpass(plotdat,cutoff,samprate);
    else
        smoothdat   = plotdat;
    end
    
    if ndims(smoothdat) == 3
        smoothdat = permute(smoothdat,[3,1,2]);
    elseif ndims(smoothdat) == 2
        smoothdat = smoothdat';
    end
    
    %ylims       = [-.05 0.4];
    ylims       = [-.25 .4];
    do.signif   = true;
    masstest    = 'cluster';
    
    figH = figure;
    steh = fEEG_steplot(smoothdat,timepoints,ylims,do.signif,masstest,colz(4:5,:),[],'bottom');
    
    ax = gca;
    set(ax,'FontSize',axlabelfntsz,'LineWidth',1.5);
    set(ax,'XTick',-100:100:750);
    xlabel('Time from sample onset (ms)','FontSize',24);
    ylabel('Parameter estimate (z)','FontSize',24);
    
    [hL, hObj]  = legend(fliplr(steh),{' sgn( X^B - X^A )','       | X^B - X^A |'},'FontSize',20,'Location','NorthWest','Box','Off');    
    set(hObj([3,5]),'LineWidth',5);
    
    if do.save_plot
        save2eps(figH,paths.figures.current,'HEOG',[.1 .1 650 400]);
    end
    
end
