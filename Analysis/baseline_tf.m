function basedat = baseline_tf(tfdata,timepoints,basewdw)
%function basedat = baseline_tf(tfa,timepoints,basewdw)
%
% Baselining TF data per trial (trials x channels x frequencies x timepoints)
% dB baseline: 10*log10(data/bl)
% Relative baseline change: (data-bl)/bl
%
% Fabrice Luyckx, 18/10/2018

fprintf('\nbaseline [%.2f - %.2f] ...\n',basewdw(1),basewdw(end));

%% Baseline tf data

blidx           = timepoints >= basewdw(1) & timepoints <= basewdw(end);

ntrials         = size(tfdata,1);
nchan           = size(tfdata,2);
nfreq           = size(tfdata,3);
ntimepoints     = size(tfdata,4);

allLoops        = allcomb(1:ntrials,1:nchan,1:nfreq);
basedat         = 0*tfdata;

for b = 1:size(allLoops,1)
    
    curr_trial  = allLoops(b,1);
    curr_chan   = allLoops(b,2);
    curr_freq   = allLoops(b,3);
    
    %curr_tf     = tfdata(:,curr_chan,curr_freq,:);
    bl          = nanmean(tfdata(curr_trial,curr_chan,curr_freq,blidx),4);
    
    % Percentage change
    %basedat(curr_trial,curr_chan,curr_freq,:) = (tfdata(curr_trial,curr_chan,curr_freq,:) - bl)/bl;
    
    % dB
    basedat(curr_trial,curr_chan,curr_freq,:) = 10*log10(tfdata(curr_trial,curr_chan,curr_freq,:)./bl);
end

end