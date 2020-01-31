function [zevalues]= mypseudorandrange(array_mean,array_sd,nitms,critmean,critsd,range,nsamples)
% critmean is the maximal distance between outcome mean and expected mean
%       (0 = outcome very close to expected value)
% critsd is the maximal distance between outcome variance and expected variance
%       (0 = outcome very close to expected value)
% range is the range, of course





if array_sd==0
    zevalues = array_mean*ones(nsamples,nitms);
else
    pass = 0; dumcount=0;
    zevalues = zeros(0,nitms);
    while pass<nsamples
        dumcount=dumcount+1;
        values = array_mean + array_sd*randn(nitms,10000); % generate 10000 samples
        out = sum( (values<range(1)) + (values>range(2)) )>0;
        if any(~out) % take samples that are not out of range
            values = values(:,~out);
            distsd   = abs(std(values) - array_sd); % distance between the sample statistics and expected statistics
            distmean = abs(mean(values) - array_mean);
            zecrit = distsd<critsd & distmean<critmean; % criterion
            if any(zecrit) % add the samples that pass the criterion
                pass=pass+sum(zecrit);
                zevalues = [zevalues; values(:,zecrit)'];
                if size(zevalues,1)>nsamples
                    zevalues((nsamples+1):end,:) = [];
                end
            end
            % save for distribution statisticts
            %     n = n+1; zestds = [zestds std(zevalues)]; zemeans = [zemeans,mean(zevalues)];
        end
    end
end

% disp([array_sd distsd]); % disp([array_mean distmean]); % disp(n); % disp(sqrt(var(zevalues)))

% if 1
% figure,
% subplot(1,2,1),hist(zemeans);set(gca,'Xlim',[-0.2 0.2]);
% subplot(1,2,2),hist(zestds);set(gca,'Xlim',[-0.05 0.15]);
% end

return





