function [Drc_corr] = correctFreqShift(Drc, tx_ned, rx_ned, t_ax)
%Freq SHIFT CORRECTION correct freq shift error caused by un-syncronized
%clocks
%   Using navigation data to re-compute the correct Phase

[~,cross_talk_idxs] = max(Drc,[],1);
% apply median filter and then moving average
cross_talk_idxs = movmean(medfilt1(cross_talk_idxs,1e3) ,1e3); 

cross_talk_phase = zeros(size(cross_talk_idxs));
for ii = 1 : length(cross_talk_idxs)
    cross_talk_phase(ii) = angle(Drc(cross_talk_idxs(ii),ii));
end

cross_talk_phase = movmean(unwrap(cross_talk_phase),500);

phase_shift = -cross_talk_phase;
phasor = exp(1i*phase_shift);

phasor_mat = repmat(phasor(:).',size(Drc,1),1);
Drc_corr = Drc .* phasor_mat;
%% Apply phase from navigation

tx_rx_dist = sqrt(sum((tx_ned - rx_ned).^2,2));
R_ax = t_ax .* physconst("LightSpeed");

phase_shift = R_ax * exp( 2i* pi *f0 * tx_rx_dist);


phasor = exp(-1i*phase_shift);
peak_final = peak_fixed(:).* phasor(:);

%% FULL matrix correction
phasor_mat = repmat(phasor(:).',size(radar.RC,1),1);
radar.RC = radar.RC .* phasor_mat;

end