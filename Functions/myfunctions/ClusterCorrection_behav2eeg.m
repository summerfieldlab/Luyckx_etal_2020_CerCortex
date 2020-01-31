function p = ClusterCorrection_behav2eeg(behavdat,eegdat,nit,p_thresh)
%function p = ClusterCorrection_behav2eeg(behavdat,eegdat,nit,p_thresh)
%
%

nsub        = size(behavdat,1);
ntimepoints = size(eegdat,2);

[orig_r, orig_p] = corr(behavdat,eegdat,'Type','Spearman');
%[orig_r, orig_p] = corr(behavdat,eegdat);
maxSize = zeros(nit,1);

for i = 1:nit
    
    shuff_behav         = behavdat(randperm(nsub),1);
    [perm_r, perm_p] 	= corr(shuff_behav,eegdat,'Type','Spearman');
    %[perm_r, perm_p] 	= corr(shuff_behav,eegdat);
    
    CC = bwconncomp(perm_p<=p_thresh);
    if CC.NumObjects == 0
        maxSize(i) = 0;
    else
        tmpSize = zeros(CC.NumObjects,1);
        for c=1:CC.NumObjects
            tmpSize(c) = abs(sum(perm_r(CC.PixelIdxList{c})));
        end
        maxSize(i) = max(tmpSize);
    end
    
end

p   = nan(size(orig_p));
CC  = bwconncomp((orig_p<=p_thresh));

if CC.NumObjects ~= 0
    for c=1:CC.NumObjects
        ObsCluster = abs(sum(orig_r(CC.PixelIdxList{c})));
        p(CC.PixelIdxList{c}) = (sum(maxSize>=ObsCluster)/nit);
    end
end

end

