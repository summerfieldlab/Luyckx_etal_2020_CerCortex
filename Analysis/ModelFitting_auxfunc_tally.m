function [bestparam,LL] = ModelFitting_auxfunc_tally(s,data,params,paths,X,Y,param_bounds,crossval)
% function [bestparam,LL] = ModelFitting_auxfunc_tally(s,data,params,paths,X,Y,param_bounds,crossval)
%
% Used in ModelFitting_pipeline_tally

idx     = data.sub == params.submat(s) & Y >= 0;

if crossval
    
    fprintf('\nFitting sub %d, cross-validation\n',s);
    
    for u = 1:2
        use = data.session(idx) == u; % cross-validate between session
        [bestparam{u},LL{u}] = ModelFitting_auxfunc_tally_crossval(X(idx,:,:),Y(idx),use,param_bounds,crossval);
    end   
else
    
    fprintf('\nFitting sub %d\n',s);
    
    use = 1:sum(idx); % use all data
    [bestparam,LL] = ModelFitting_auxfunc_tally_crossval(X(idx,:,:),Y(idx),use,param_bounds,crossval);
end

%% Save results

save(fullfile(paths.data.model,sprintf('Modelfit_tallyfit_sub%d',params.submat(s))),'bestparam','LL');

fprintf('\nSaved sub %d\n',s);

end