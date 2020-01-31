function [values]= mypseudorand(array_mean,array_sd,nitms,critmean,critsd)
% critmean is the maximal distance between outcome mean and expected mean
%       (0 = outcome very close to expected value)
% critsd is the maximal distance between outcome variance and expected variance
%       (0 = outcome very close to expected value)

if nargin<4
    distmean=2;
    distsd=0.01;
end

pass = 0;
% n = 0; zemeans = []; zestds = [];
while pass<1
    % generate a sample
    values = array_mean + array_sd*randn(1,nitms);
    % distance between the sample statistics and expected statistics
    distsd   = abs(std(values) - array_sd);
    distmean = abs(mean(values) - array_mean);
    % criterion
    if distsd<critsd && distmean<critmean
        pass=pass+1;
%         disp(num2str(sum(values<0.1) + sum(values>0.9))); % check for range
    end
    % save for distribution statisticts
%     n = n+1; zestds = [zestds std(values)]; zemeans = [zemeans,mean(values)];
end

% disp([array_sd distsd]); % disp([array_mean distmean]); % disp(n); % disp(sqrt(var(values)))

% if 1
% figure,
% subplot(1,2,1),hist(zemeans);set(gca,'Xlim',[-0.2 0.2]);
% subplot(1,2,2),hist(zestds);set(gca,'Xlim',[-0.05 0.15]);
% end

return





