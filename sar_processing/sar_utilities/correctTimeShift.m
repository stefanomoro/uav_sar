function [Drc_corr] = correctTimeShift(Drc, tx_ned, rx_ned, t_ax)
%TIME SHIFT CORRECTION correct time shift error caused by no absolute time
%   Using navigation data to shift the all signal

[~,cross_talk_idxs] = max(Drc,[],1);
% apply median filter and then moving average
cross_talk_idxs = movmean(medfilt1(cross_talk_idxs,1e3) ,1e3); 

%% TIME SHIFT CORRECTION
tx_rx_dist = sqrt(sum((tx_ned - rx_ned).^2,2));
R_ax = t_ax .* physconst("LightSpeed");
dR = (R_ax(2) - R_ax(1));
corr_idx = (tx_rx_dist-R_ax(1)) ./ dR;


cross_talk_shifts = cross_talk_idxs(:) - corr_idx(:);

Nf = 2^nextpow2(size(Drc,1));
X = fftshift(fft(Drc,Nf,1),1);

f = (-Nf/2:Nf/2 - 1)/Nf;
H = exp(1i*2*pi*f(:)*cross_talk_shifts.');
H(1,:) = 0;                         

RC_Dt_fixed = ifft(ifftshift(X.* H,1),Nf,1);
RC_Dt_fixed = RC_Dt_fixed(1:size(Drc,1),:);
%% PLOT
figure,imagesc([],R_ax,abs(Drc)),hold on, plot(R_ax(round(cross_talk_idxs)),'r','LineWidth',1.2);,title("Original max tracking")

Drc_corr = RC_Dt_fixed; 
figure,imagesc([],R_ax,abs(Drc_corr)),hold on, plot(R_ax(round(corr_idx)),'r','LineWidth',1.2),title("Corrected")

end

