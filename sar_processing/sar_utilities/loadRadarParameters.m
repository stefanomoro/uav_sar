function radar_parameters = loadRadarParameters(experiment_folder,radar_mode)
%loadRadarParameters.m loads the radar parameters into a structure
%
% Inputs:
%       experiment_folder: a string containing the experiment folder. See the script
%                           generateProjectFolder.m for the structure of
%                           this folder
%       radar_mode: string to choose between monostatic and bistatic mode
%
% Outputs:
%       radar_parameters: a structure containing the following values
%       radar_parameters.f0: central frequency
%       radar_parameters.lambda: wavelength
%       radar_parameters.rho_rg: slant range resolution given by the
%       bandwidth
%       radar_parameters.B: bandwidth
%       radar_parameters.fs: sampling frequency in fast time
%       radar_parameters.TX_gain: TX gain
%       radar_parameters.RX_gain: RX gain
%       radar_parameters.TX_waveform: an array with the transmitte waveform
%       radar_parameters.samples_waveform: the number of samples of the
%       transmitted waveform
%       radar_parameters.PRI: Pulse Repetition Interval
%       radar_parameters.PRF: Pulse Repetition Frequency



if not(exist(experiment_folder, 'dir'))
    error("The experiment folder does not exist");
end

if exist(fullfile(experiment_folder,"waveform/TX_waveform_S56M.mat"),'var')
    tx_wave_file = fullfile(experiment_folder,"waveform/TX_waveform_S56M.mat");
else
    warning("No waveform file. Using the standard 56MHz chirp")
    tx_wave_file = fullfile("../utilities/tx_waveform_S56M.mat");
end

c = physconst('lightspeed');

radar_parameters.mode = radar_mode;
radar_parameters.f0         = 2.47e9;
fprintf("Selected Carrier Frequency %d GHz\n",radar_parameters.f0/1e9);
if strcmp(radar_parameters.mode,"monostatic")
    radar_parameters.B          = 36e6;
    radar_parameters.fs         = 40e6;
    radar_parameters.TX_gain    = 60; % dB
    radar_parameters.RX_gain    = 70; % dB
elseif strcmp(radar_parameters.mode,"bistatic")
    radar_parameters.B          = 56e6 * 0.9;
    radar_parameters.fs         = 56e6;
    radar_parameters.TX_gain    = 73; % dB
    radar_parameters.RX_gain    = 73; % dB
    
end


radar_parameters.lambda     = c/radar_parameters.f0;
radar_parameters.rho_rg     = c/2/radar_parameters.B;

radar_parameters.TX_waveform        = load(tx_wave_file).s_pad;
radar_parameters.samples_waveform   = length(radar_parameters.TX_waveform);
radar_parameters.PRI                = radar_parameters.samples_waveform/radar_parameters.fs;
radar_parameters.PRF                = 1/radar_parameters.PRI;

end


%%%%%%%%%%%%%%%%% Waveform check %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% N = length(radar_parameters.TX_waveform);
% df = radar_parameters.fs/N;
% f_ax = (-N/2:N/2-1)*df;
%
% figure; plot(f_ax, abs(fftshift(fft(radar_parameters.TX_waveform)))); grid on;
% xlabel("Frequency [Hz]");