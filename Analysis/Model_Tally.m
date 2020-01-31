function [estY, estX, cumX] = Model_Tally(modparam,X)
%function [estY, estX, cumX] = Model_Tally(modparam,X)
% parameters = [w leak noise lapse]
% Based on Glickman 2018

w       = modparam(1); % w: slope gating function
leak    = modparam(2); % l: leak
noise   = modparam(3); % noise: slope response function
lapse   = modparam(4); % lapse: lapse rate response function

ntrials = size(X,1);
nsamp   = size(X,2);

% Inputs
Xa  = squeeze(X(:,:,1));
Xb  = squeeze(X(:,:,2));

% Tally
diffX   = Xb - Xa; % R - L
wXb     = sigmf(diffX,[w,0]);
wXa     = 1 - wXb;
Ia      = round(wXa);
Ib    	= round(wXb);

% Accumulation v2 (same results as v1)
Ya = cumsum(Ia .* ((1-leak).^(nsamp:-1:1)/(1-leak)),2);
Yb = cumsum(Ib .* ((1-leak).^(nsamp:-1:1)/(1-leak)),2);

% Decision
diffY   = Yb(:,end) - Ya(:,end);
estY    = lapse + (1 - lapse*2).*sigmf(diffY,[noise,0]);
estX    = cat(3,Ia,Ib);
cumX    = cat(3,Ya,Yb);

end

