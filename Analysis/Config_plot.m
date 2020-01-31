%%%%%%%%%%%%%%%%%%%%%%%%
%% DEFINE plot variables
%%%%%%%%%%%%%%%%%%%%%%%%

%% Functions

% Function to make matrix one long column
makeLong = @(x) x(:);

% Function to calculate color matrices
rgb     = @(x) round(x./255,2);

% Standard error
sem     = @(x,n) nanstd(x)./sqrt(n);

%% Plot variables

axfntsz         = 14;
axlabelfntsz    = 18;
titlefntsz      = 16;
lgndfntsz       = 20;
lnwid           = 2;
mksz            = 10;
barwid          = .9;

set(0,'DefaultAxesFontName', 'Helvetica');
set(0,'DefaultTextFontname', 'Helvetica');

modmark     = {'d','x'};
markers 	= {'o','s','d','x','h','p','+','*'};

colz(1,:)   = rgb([46 129 171]); % blue
colz(2,:)   = rgb([135 200 144]); % green
colz(3,:)   = rgb([255 133 82]); % orange
colz(4,:)   = rgb([239 118 122]);
colz(5,:)   = rgb([73 190 170]);
colzedge    = colz*.8;

modcol      = [1 0 0; rgb([29,120,116])]; % full/fixed

framez      = {'Low frame','High frame'}; 
frametype   = {'low','high'};
conditionz  = {'Low variance','High variance','Frequent winner','Infrequent winner'};
samplenamez = {'S_1','S_2','S_3','S_4','S_5','S_6','S_7','S_8','S_9'};