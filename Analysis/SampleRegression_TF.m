function Betas = SampleRegression_TF(combo,X,data,params,paths)

%% Get dimensions

s = combo(1);

fprintf('\nRunning tf regression subject %d, both sessions.\n',params.submat(s));

%% Load data

[tfdata,bindx,eindx] = PreprocTF(s,data,params,paths);

%% Baseline

if ~isempty(data.basewdw)
    basedat = baseline_tf(tfdata(eindx,:,:,:,params.whichSamp),params.tp,data.basewdw);
else
    basedat = tfdata(eindx,:,:,:,params.whichSamp);
end

%% Regressors

regr        = X(data.sub == params.submat(s),:,:,:);

% Index regressors (omit eeg removed trials)
regr        = regr(bindx,:,:,:);

% Add eog as regressor
if params.add_eog
    
    % Load EOG data
    load(fullfile(paths.data.EOG,params.eog_filename));
    
    sub_eog     = eogdata{s};
    
    eog_regr(:,1,:) = zscore(abs(sub_eog(:,eindx))'.*squeeze(regr(:,1,:,1)),[],2); % normalise right win
    eog_regr(:,2,:) = zscore(abs(sub_eog(:,eindx))'.*squeeze(regr(:,2,:,1)),[],2); % normalise left win
    
    eog_regr = repmat(eog_regr,[1,1,1,params.nfreq]);
    
    regr = cat(2,regr,eog_regr);
end

%% Regression

nchan       = size(basedat,2);
ntimepoints = size(basedat,4);
ntrials     = sum(eindx);
nregr       = size(regr,2);
nsamp       = size(regr,3);
nfreq       = size(regr,4);

allLoops    = allcomb(1:nchan,1:nsamp,1:nfreq,1:ntimepoints);
pseudoInv   = nan(nregr,ntrials,nchan,nsamp,nfreq,ntimepoints);

% Get pseudoinverse

fprintf('\npseudoinverse ...');

for r = 1:size(allLoops,1)
    
    curr_chan   = allLoops(r,1);
    curr_samp   = allLoops(r,2);
    curr_freq   = allLoops(r,3);
    curr_time   = allLoops(r,4);
    
    pseudoInv(:,:,curr_chan,curr_samp,curr_freq,curr_time) = pinv(regr(:,:,curr_samp,curr_freq));
end

% Reshape EEG data
ydat = permute(basedat,[1,6,2,5,3,4]);

% Regression
fprintf('\nregression ...\n');
Betas = mtimesx(pseudoInv,ydat);

% Reshape betas
Betas = squeeze(permute(Betas,[3,6,4,5,1,2]));

%% Save betas in case it crashes

outputname = sprintf('BarExp_EEG_sub%d_TF_samples',params.submat(s));
save(fullfile(paths.data.saveEEG,outputname),'Betas');

end