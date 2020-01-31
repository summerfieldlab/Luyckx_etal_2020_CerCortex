function smoothdat = smoothTF(tfdat,wdwsz,fwhm)
% function smoothdat = smoothTF(tfdat,wdwsz,fwhm)
%
% tfdat     = time x frequency x sub
% wdwsz     = n data points (not time points)
%
% Fabrice Luyckx, 13/11/2018

fprintf('... smoothing\n');

smoothdat   = 0*tfdat;
sd1         = fwhm(1)/sqrt(8*log(2));
sd2         = fwhm(2)/sqrt(8*log(2));

gs = customgauss(wdwsz,sd1,sd2,0,0,1,[0 0]); 
smoothfilt = gs/sum(gs(:));

for s = 1:size(tfdat,3)
    smoothdat(:,:,s) = nanconv(squeeze(tfdat(:,:,s)),smoothfilt,'2d','nanout');
end

end

