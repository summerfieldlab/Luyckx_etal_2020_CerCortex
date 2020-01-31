function [Betas, resids, SSE] = SampleRegression(combo,X,data,params,paths)

%% Get dimensions

s = combo(1);

fprintf('\nRunning regression subject %d, both sessions.\n',params.submat(s));

%% Load data

[erpdata,bindx,eindx] = PreprocERP(s,data,params,paths);

%% Regressors

regr        = X(data.sub == params.submat(s),:,:);

% Index regressors (omit eeg removed trials)
regr        = regr(bindx,:,:);

% Add eog as regressor
if params.add_eog
    
    % Load EOG data
    load(fullfile(paths.data.EOG,params.eog_filename));
    
    sub_eog     = eogdata{s};
    
    eog_regr(:,1,:) = zscore(abs(sub_eog(:,eindx))'.*squeeze(regr(:,1,:)),[],2); % normalise right win
    eog_regr(:,2,:) = zscore(abs(sub_eog(:,eindx))'.*squeeze(regr(:,2,:)),[],2); % normalise left win
    
    regr = cat(2,regr,eog_regr);
end

%% Regression

% Get dimensions
nbchan      = size(erpdata,1);
ntimepoints = size(erpdata,2);
ntrials     = sum(eindx);
nsamp       = size(regr,3);
nregr       = size(regr,2);

allLoops    = allcomb(1:nbchan,1:nsamp,1:ntimepoints);
pseudoInv   = nan(nregr,ntrials,nbchan,nsamp,ntimepoints);

% Get pseudoinverse

fprintf('\npseudoinverse ...');

for r = 1:size(allLoops,1)
    
    curr_chan   = allLoops(r,1);
    curr_samp   = allLoops(r,2);
    curr_time   = allLoops(r,3);
    
    pseudoInv(:,:,curr_chan,curr_samp,curr_time) = pinv(regr(:,:,curr_samp));
end

% Reshape EEG data
ydat = erpdata(:,:,params.whichSamp,eindx);
ydat = permute(ydat,[4,5,1,3,2]);

% Regression
fprintf('\nregression ...\n');
Betas = mtimesx(pseudoInv,ydat);

% Reshape betas
Betas = permute(Betas,[3,5,4,1,2]);

%% Calculate residuals

if params.resids || params.sse
    
    Y       = squeeze(ydat);
    Yhat    = 0*Y;
    
    for r = 1:size(allLoops,1)
        
        curr_chan   = allLoops(r,1);
        curr_samp   = allLoops(r,2);
        curr_time   = allLoops(r,3);
        
        Yhat(:,curr_chan,curr_samp,curr_time) = sum(squeeze(Betas(curr_chan,curr_time,curr_samp,:))'.*regr(:,:,curr_samp),2);
    end
    
    resids  = Y-Yhat;
    resids  = permute(resids,[2,4,3,1]);
else
    resids = 0*squeeze(ydat);
end

%% Calculate sum of squares

if params.sse
    SSE     = squeeze(sum(resids.^2,1));
    SSE     = permute(SSE,[1,3,2]);    
end

end