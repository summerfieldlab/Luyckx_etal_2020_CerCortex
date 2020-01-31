function smoothdat = lowpass(xdat,cutoff,samprate)
%function smoothdat = lowpass(xdat,cutoff,samprate)
% 
% Low pass filter (1st order butterworth).
%
% Input:
%   - xdat: eeg data (time series x ...)
%   - cutoff: top cut-off frequency
%   - samprate: sampling rate
%
% Output:
%   - smoothdat: filtered data
%
% Fabrice Luyckx, 2/12/2018

%% Make butterworth filter of order 1

[b,a] = butter(1,cutoff/(samprate/2)); % Butterworth filter of order 1

%% Filter data

sz          = size(xdat);
nts         = sz(1); % number of time-series to smooth
allLoops    = fullfact(sz(2:end));
nloops      = size(allLoops,1);

newX        = reshape(xdat,[nts,nloops]);
smoothdat   = nan(nts,nloops);

for f = 1:nloops
    smoothdat(:,f) = filtfilt(b,a,newX(:,f)); % Will be the filtered signal
end

if length(sz) > 2
    smoothdat = reshape(smoothdat,sz);
end


end

