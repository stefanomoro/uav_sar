function [outputArg1,outputArg2] = removeCrosstalk(inputArg1,inputArg2)
%REMOVECROSSTALK Summary of this function goes here
%   Detailed explanation goes here



[~,cross_talk_idxs] = max(Drc,[],1);
% apply median filter and then moving average
cross_talk_idxs = movmean(medfilt1(cross_talk_idxs,1e3) ,1e3);
peak_ampl = zeros(size(tau_ax));
peak_phase = zeros(size(tau_ax));
synt_RC_peak = 0 .* Drc;
for tau = 1:length(tau_ax)
    peak_ampl(tau) = abs(Drc(round(cross_talk_idxs(tau)),tau));
    peak_phase(tau) = angle(Drc(round(cross_talk_idxs(tau)),tau));
    dt = t_ax(2) - t_ax(1);

    t_delay = (cross_talk_idxs(tau) - 1) .* dt + t_ax(1);

    sig = peak_ampl(tau) .* sinc(radar_parameters.B.*(t_ax-t_delay)).';

    synt_RC_peak(:,tau) = sig.*exp(1i * peak_phase(tau));
end
figure,imagesc([],t_ax*3e8/2,db(Drc - synt_RC_peak)),clim([80 180])
end

