function [] = save2svg(fighandle,figpath,figtitle,varargin)
%function [] = save2svg(fighandle,figpath,figtitle,sz)
% Save figure in svg format.
%
% fighandle = figure handle
% figpath = path to save picture to
% figtitle = title of your figure
% [sz] = size of the figure in pixels, [current_size]
%
% Fabrice Luyckx, 22/10/2015

current_size = get(fighandle,'Position');

%% DEFAULT VALUES
optargs = {current_size};

% Now put these defaults into the valuesToUse cell array, 
% and overwrite the ones specified in varargin.
specif = find(~cellfun(@isempty,varargin)); % find position of specified arguments
[optargs{specif}] = varargin{specif};

% Place optional args in memorable variable names
[sz] = optargs{:};

if nargin > 3
    % Change size of figure
    set(fighandle, 'Units','pixels','Position',sz,'PaperPositionMode','auto');
end

% Path to save figure to
fullpath = fullfile(figpath,figtitle);

% Set background to white
set(fighandle,'color','w');

% Save figure
print(fighandle,'-dsvg','-r300',fullpath);

disp(' ');
disp([figtitle '.svg saved succesfully.']);

end

