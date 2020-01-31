function [nrows,ncols] = getSize_subplot(N,direction)
%function [nrows,ncols] = getSize_subplot(N,[direction])
%
% Determine ideal rows and columns for subplot window;
%
% Input:
%   - N: min. number of windows required
%   - [direction]: more horizontally or vertically oriented ['horizontal']
%
% Ouput:
%   - nrows: number of rows
%   - ncols: number of columns
%
% Fabrice Luyckx, 10/11/2016

if nargin == 1
    direction = 'horizontal';
end
    
a = floor(N/sqrt(N));
b = ceil(N/a);

switch direction
    case 'horizontal'
        nrows = min([a,b]);
        ncols = max([a,b]);
    case 'vertical'
        nrows = max([a,b]);
        ncols = min([a,b]);
end

end

