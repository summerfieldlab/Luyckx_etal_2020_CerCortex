function [bestparam,LL] = ModelFitting_auxfunc_SI_crossval(X,Y,use,param_bounds,crossval)
%function [bestparam,LL] = ModelFitting_auxfunc_SI_crossval(X,Y,use,param_bounds,crossval)
%   Based on juechems_etal_2017 (Github)

nparams = size(param_bounds,2); % number of parameters
bnd_low = param_bounds(1,:); % lower bound
bnd_up  = param_bounds(2,:); % upper bound

init    = rand(1,nparams);
init    = init .* (bnd_up - bnd_low) + bnd_low;

% Find global minimum
gs              = GlobalSearch('Display','off');
problem       	= createOptimProblem('fmincon','x0',init,'objective',@log_likelihood,'lb',bnd_low,'ub',bnd_up);
[bestparam,LL]  = run(gs,problem);

%% CROSS-VALIDATION

if crossval
    use     = ~use;
    LL      = log_likelihood(bestparam);
end

% Get model choices and probabilities
%moddata = SelectiveIntegration(bestparam,X,Y,nit);

%% LOG LIKELIHOOD FUNCTION

    function log_l = log_likelihood(modparam)
        p_choice    	= Model_SelectiveIntegration(modparam,X(use,:,:));
        decision        = Y(use);
        
        p_choice(p_choice < 0.0000001) = 0.0000001;
        p_choice(p_choice > 0.9999999) = 0.9999999;
        
        likelihood      = decision .* log(p_choice) + (1-decision) .* log(1-p_choice);
        log_l           = -1*sum(likelihood);
    end

end