% uav_focus.m

close all;
clc;

%% Add the paths
% Add the folders with the functions

addpath('./trajectories',...
    './sar_utilities',...
    './focusing', ...
    genpath('../utilities'),...
    addpath(genpath('../range_compression')));

%% Definition of the parameters

% Each experiment has a folder. The folder can be generated using the
% generateProjectFolder.m script.
%
% The folder will containg the following sub-directories:

% raw:          place here the .dat file generated by the SDR
% rc:           the script will write in this folder the range compressed data
% images:       place here images, videos or figures of the experiment
% trajectories: place here the .mat file containing the
%               trajectory of the platform for the current experiment. See the
%               loadTrajectories.m function
% waveform:     Place here the .mat file containing the transmitted waveform

% TODO: write a file info.txt with infos about the experiment such as (PRF, PRI,
% pulse length, bandwidth, central frequency, total trajectory lenth)

% Folder of the experiment.
experiment_folder              = "D:\Droni_Campaigns\20230331_giuriati_2\exp15";

% Maximum range. The script will cut the data after range compression
max_range                      = 200;

% Over sampling factor. After range compression and data cut, the data will be
% oversampled by this factor in fast time
OSF                            = 4;

% Under sampling factor for the slow-times (odd-number!). We use a very
% high PRF, therefore we can filter the data in slow-time and undersample
% it to improve SNR and reduce computational burden in the TDBP
USF                            = 11;

% Flag for the notching of the zero doppler peak (mean removal). The direct
% path from TX to RX antennae will be very strong. This flag abilitate a
% zero-doppler filtering of the data in slow-time.
zero_doppler_notch             = true;

% Azimuth resolution (-1 means same as range resolution). set the desiderd azimuth
% resolution
rho_az = 1;

% Squint for the focusing (deg).
squint = 0;

% Starting sample to process in slow-time. This is useful to trow away some
% samples at the beginning of the acquisition
index_start = 100;


%% Start the processing

% loading the parameters of the radar (f0,PRI,PRF,BW,fs,gains, waveform, etc.)
radar_parameters = loadRadarParameters(experiment_folder);

% Convert raw data from .dat to .mat
rawDataConvert(experiment_folder, radar_parameters.samples_waveform);

% load the raw data and range compress it. If it finds some data in the RC
% folder it just loads it without doing the range compression.
[Drc, t_ax, tau_ax] = loadRawDataAndRangeCompress(experiment_folder, radar_parameters, max_range, OSF);

figure; imagesc(tau_ax, t_ax*3e8/2, db(Drc)); colorbar; title("Range compressed data without zero doppler notching");
xlabel("slow time [s]"); ylabel("fast time [s]"); axis xy

% Cut the data to remove bad values at the beginning of the acquisition
Drc = Drc(:,index_start:end);
tau_ax = tau_ax(index_start:end);

% Plot the incoherent mean along slow-times to check resolution from the
% direct path.
figure; plot(t_ax*3e8/2, mean(abs(Drc),2)); xlabel("range [m]"); ylabel("Amplitude");
title("Resolution check from the direct path"); grid on;
if zero_doppler_notch
    % Notch filter on the zero Doppler to kill the direct path from TX antenna
    % to RX antenna
    Drc = zeroDopplerNotch(Drc, radar_parameters.PRF);

    index_zero = find(min(abs(t_ax))==t_ax);

    % Plot the range compressed data matrix
    figure; imagesc(tau_ax, t_ax(index_zero:end), db(Drc(index_zero:end,:)));
    axis xy
    xlabel("Slow time [s]");
    ylabel("range [m]");
    title("Range compressed data WITH zero doppler notching");
    colorbar;
    caxis([100,140]);

    showDopplerPlot(Drc(1:end,:),tau_ax, t_ax(1:end), "full"); caxis([140,200])
end
% Filter the range compressed data with a gaussian filter in range to
% remove sidelobes
Drc = filterRange(Drc, t_ax, radar_parameters.B);

% Low pass filter and undersample the range compressed data. We have a very
% high PRF, so we can do it
[Drc_lp, PRF, tau_ax] = lowPassFilterAndUndersample(Drc, radar_parameters.PRF, tau_ax, USF);

showDopplerPlot(Drc_lp(1:end,:),tau_ax, t_ax(1:end), "full");
caxis([140, 200])

figure; imagesc(tau_ax, t_ax*3e8/2, db(Drc_lp));
caxis([100,140]);
xlabel("Slow time [s]");
ylabel("range [m]");
axis xy
title(["Range compressed data", "With zero doppler notching", "With range filtering for sidelobes removal", "Filtered and undersampled in slow-time"]);

% Trajectory interpolation to match the radar timestamps. This must be
% modificed when we will have syncronized trajectories and radar data
Nbegin  = 190;%4500;
Nend    = 4540;%5840;%64300;
figure; imagesc([], t_ax*3e8/2, db(Drc_lp)); caxis([100,140]); hold on;
plot([Nbegin Nbegin],[t_ax(1)*3e8/2, t_ax(end)*3e8/2], 'r');
plot([Nend Nend],[t_ax(1)*3e8/2, t_ax(end)*3e8/2], 'r'); axis xy

traj = loadTrajectories(experiment_folder);
traj = alignTrajectoryWithRadarData(traj.lat, traj.lon, traj.alt, traj.speed, traj.time_stamp, ...
    tau_ax, Nbegin, Nend);

%% Focusing
if rho_az == -1
    rho_az = radar_parameters.rho_rg;
end

traj.Sx = zeros(size(Drc,2),1);
traj.Sx(Nbegin:Nend) = linspace(-15,15,length(Nbegin:Nend));
traj.Sy = zeros(size(traj.Sx));
traj.Sz = zeros(size(traj.Sx));


% Define the backprojection grid
x = -30 : radar_parameters.rho_rg/15 : 30;
y = 1 : -radar_parameters.rho_rg/15 : -200;
[X,Y] = meshgrid(x,y);
Z = zeros(size(X));

I = focusDroneTDBP(Drc_lp(:,Nbegin:Nend), t_ax, radar_parameters.f0,...
    traj.Sx(Nbegin:Nend), traj.Sy(Nbegin:Nend), traj.Sz(Nbegin:Nend),...
    X,Y,Z,...
    rho_az, squint);

figure; imagesc(x,y,db(I)); colorbar; axis xy
xlabel("x [m]"); ylabel("y [m]"); title("Focussed SAR image");
axis xy tight
set(gca, 'YDir','reverse')
set(gca, 'XDir','reverse')
caxis([100,150])
%caxis([1e7 11e7]);
% Autofocusing