function [new_chanlocs, new_labels] = fEEG_midlineflip(chanlocs)
%function [new_chanlocs, new_labels] = fEEG_midlineflip(chanlocs)
%
% Function to flip electrodes across the vertical midline (right becomes
% left). Changes both index and labels of electrodes.
%
% Input:
%   - chanlocs: EEG.chanlocs structure from eeglab
%
% Output:
%   - new_chanlocs: new index of electrodes
%   - new_labels: new labels of electrodes
%
% Fabrice Luyckx, 4/5/2017

%%

nbchan          = length(chanlocs);
new_chanlocs    = zeros(1,nbchan);
new_labels      = {};

for e = 1:nbchan
    labels{e} = chanlocs(e).labels;
end

for i = 1:nbchan
    orig_Ypos(i)    = chanlocs(i).Y;
    orig_Xpos(i)    = chanlocs(i).X;
end

new_Ypos        = -1*orig_Ypos;
new_Xpos        = orig_Xpos;

for i = 1:nbchan
    new_chanlocs(i) = find(round(new_Ypos(i)) == round(orig_Ypos) & round(new_Xpos(i)) == round(orig_Xpos));
    new_labels{i}   = labels{new_chanlocs(i)};
end

end

