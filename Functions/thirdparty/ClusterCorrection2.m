function [p,praw] = ClusterCorrection2(dat, nSims, p_crit, p_thresh,tail)
%function [p,praw] = ClusterCorrection2(dat, nSims, p_crit, p_thresh,tail)
% Cluster Correct across any number of dimensions
%author: M Stokes

if nargin < 4
    p_thresh = p_crit;
end  

if nargin < 5
    tail = 'both';
end

[h,p,ci,stats] = ttest(dat,0,'tail',tail);
pObs = p;
tObs = stats.tstat;
maxSize = zeros(nSims,1);
if nSims > 0 %do correction
    for sim=1:nSims
        permind = sign(rand(size(dat,1),1)-.5);
        permind = repmat(permind,size(pObs));
        simDat  = dat.*permind;
        [h,p,ci,stats] = ttest(simDat,0,'tail',tail);

        CC = bwconncomp((p<=p_thresh));
        if CC.NumObjects == 0
            maxSize(sim) = 0;
        else
            tmpSize = zeros(CC.NumObjects,1);
            for c=1:CC.NumObjects
                tmpSize(c) = abs(sum(stats.tstat(CC.PixelIdxList{c})));
            end    
            maxSize(sim) = max(tmpSize);
        end    
    end

    praw = pObs;
    p = nan(size(pObs));
    CC = bwconncomp((pObs<=p_crit));
    if CC.NumObjects ~= 0
        for c=1:CC.NumObjects
            ObsCluster = abs(sum(tObs(CC.PixelIdxList{c})));
            p(CC.PixelIdxList{c}) = (sum(maxSize>=ObsCluster)/nSims);
        end
    end
else %return all clusters (uncorrected)
    praw = pObs;
    p = zeros(size(pObs),'single');    
    CC = bwconncomp((pObs<=p_crit) );
    if CC.NumObjects ~= 0
        for c=1:CC.NumObjects            
            p(CC.PixelIdxList{c}) = c;
        end
    end
end
end