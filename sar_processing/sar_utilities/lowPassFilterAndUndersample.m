function [Drc, radar_parameters, tau_ax] = lowPassFilterAndUndersample(Drc,radar_parameters, tau_ax, USF)
%LOWPASSFILTERANDUNDERSAMPLE Low pass the data in Doppler and undersample
%it. This improves SNR and reduce computational burden during TDBP
%
% Inputs:
%       Drc:            range compressed data matrix. Fast time along the rows,
%                       slow-time along the columns.
%       PRF:            pulse repetition frequency
%       tau_ax:         slow time axis
%       USF:            Under Sampling Factor. 
%   
% Outputs:
%       Drc:            range compressed data matrix. Fast time along the rows,
%                       slow-time along the columns.
%       PRF:            new system PRF after undersampling
%       tau_ax:         new slow-time axis after undersampling.
%

if rem(USF,2) ~= 1
    warning("Under Sampling Factor (USF) must be odd, rounding the the lower odd number");
    USF = USF - 1;
end

%Drc_ll = conv2(Drc, fir1(501,12/radar_parameters.PRF), "same");
    
%  b = fir1(4*USF,1/USF,"low");
% b = b./sqrt(b*b');
% %Drc = filter(b, 1,Drc, [], 2);
% Drc_ll = conv2(Drc, b, "same");

% For the moment is a moving average, later on we will make this more
% sophisticate
Drc = movmean(Drc,USF,2);
Drc = Drc(:, 1:USF:end);

% It changes also the PRF
radar_parameters.PRF = radar_parameters.PRF/USF;
radar_parameters.PRI = radar_parameters.PRI*USF;

% And the slow-time axis
tau_ax = tau_ax(1:USF:end);

end

