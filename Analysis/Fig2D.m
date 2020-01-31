%%%%%%%%%%
%% Fig 2D
%%%%%%%%%%

%% LOAD DATA

clc
clear

% Paths
saveEEGfolder   = []; % unused here
eegfolder       = []; % unused here
figfolder       = 'Model';

% Load stuff
Load_vars; % load data and path
Config_plot; % load plot variables

% Logicals
do.parpooling   = false; % parallel processing?
do.plotting     = true; % plot results?
do.save_plot    = false; % save plot?

%% Extra variables

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

% Model data
modname = 'Model_SI_full'; % full model
load(fullfile(paths.data.model,modname));

%% Correlation model w and noise

[r,p] = corr(model.noise',model.w','Type','Spearman')

% Get ranks
rW      = tiedrank(model.w)';
rNoise  = tiedrank(model.noise)';

figR = figure; hold on;
plot(rNoise,rW,'ko','MarkerFaceColor','k','MarkerSize',10);

xlims   = [0 params.nsubj+1];
ylims   = [0 params.nsubj+1];

xvals   = linspace(xlims(1),xlims(end),5);

hls = lsline;
hls.LineWidth = 2;
hls.Color   = [.6 .6 .6];

xlim(xlims);
ylim(ylims);

ax = gca;
set(ax,'FontSize',axfntsz,'LineWidth',1.5,'XTick',[1 5 10 15],'YTick',[1 5 10 15]);
xlabel('Rank {\it s}','FontSize',axlabelfntsz);
ylabel('Rank {\it m}','FontSize',axlabelfntsz);
axis square

text(.25,1,sprintf('r = %.2f, p < 0.001',r),'FontSize',axlabelfntsz);

if do.save_plot
    save2svg(figR,paths.figures.current,'Correlation_w_noise',[.1 .1 350 300]);
end
