dist = sqrt(sum((tx_sch - rx_sch).^2,2));

t_delay = dist ./physconst("LightSpeed");

phase_cross = exp(-2i*pi*radar_parameters.f0*t_delay).';
phase_cross = repmat(phase_cross,[length(t_ax) 1]);

sig = sinc(radar_parameters.B.*(t_ax-t_delay)).';

sig = sig.*phase_cross;


% figure,imagesc([],t_ax,abs(sig)),hold on,plot(t_delay,'r',LineWidth=1.5)


dist_tgt = sqrt(sum((tgt_sch(1,:) - rx_sch).^2,2)) + sqrt(sum((tgt_sch(1,:) - tx_sch).^2,2));
dist_tgt = dist_tgt(:);
t_delay_tgt = dist_tgt ./physconst("LightSpeed");

phase_tgt = exp(-2i*pi*radar_parameters.f0*t_delay_tgt).';
phase_tgt = repmat(phase_tgt,[length(t_ax) 1]);

sig_tgt = .5 * sinc(radar_parameters.B.*(t_ax-t_delay_tgt)).';

sig_tgt = sig_tgt.*phase_tgt;
% figure,imagesc([],t_ax,abs(sig_tgt)),hold on,plot(t_delay_tgt,'r',LineWidth=1.5)


RC_synt = sig+ sig_tgt;

figure,imagesc([],t_ax,abs(RC_synt)),hold on,plot(t_delay,'r',LineWidth=1.1),plot(t_delay_tgt,'g',LineWidth=1.1)
figure,imagesc([],t_ax,abs(Drc)),hold on,plot(t_delay,'r',LineWidth=1.1),plot(t_delay_tgt,'g',LineWidth=1.1)
% figure,imagesc([],t_ax,angle(RC_synt))
