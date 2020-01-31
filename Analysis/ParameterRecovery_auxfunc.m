function ParameterRecovery_auxfunc(comb,paramcomb,data,paths,X,param_bounds)
%function ParameterRecovery_auxfunc(comb,paramcomb,data,paths,X,param_bounds)

if comb == 1
    fprintf('\nStarted simulation %d',comb);
else
    fprintf('\n%d/%d',comb,size(paramcomb,1));
end

%%

% Determine which random data set will be used
submat      = unique(data.sub);
nsub        = length(submat);
randsub     = randi(nsub);

idx         = data.sub == submat(randsub); % pick random data set

%% Get model choices

modparam        = paramcomb(comb,:);
estY            = Model_SelectiveIntegration(modparam,X(idx,:,:));

%% Do model fitting

use             = 1:length(estY);
bestparam       = ModelFitting_auxfunc_SI_crossval(X(idx,:,:),estY,use,param_bounds,false);

%% Save results

save(fullfile(paths.data.model,sprintf('Modelfit_SI_paramrecov_sim%d',comb)),'modparam','bestparam');

%fprintf('\nSaved simulation %d\n',comb);

end