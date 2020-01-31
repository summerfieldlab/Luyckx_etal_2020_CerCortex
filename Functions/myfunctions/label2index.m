function chanidx = label2index(chanlabels,labels)
%function chanidx = label2index(chanlabels,chanlocs)
%
% Translate channel labels to indices.
%
% Fabrice Luyckx, 5/7/2017

chanidx = [];
for e = 1:length(chanlabels)
    chanidx(e) = strmatch(chanlabels{e},labels);
end

end

