% uav_focus.m
%clear variables
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

experiment_folder              = "E:\data-stefano\20230713_bistatic\exp1";

% Maximum range. The script will cut the data after range compression
max_range                      = 500;

% Over sampling factor. After range compression and data cut, the data will be
% oversampled by this factor in fast time
OSF                            = 8;

% Under sampling factor for the slow-times (odd-number!). We use a very
% high PRF, therefore we can filter the data in slow-time and undersample
% it to improve SNR and reduce computational burden in the TDBP
USF                            = 1;

% Flag for the notching of the zero doppler peak (mean removal). The direct
% path from TX to RX antennae will be very strong. This flag abilitate a
% zero-doppler filtering of the data in slow-time.
zero_doppler_notch             = 0;

% Azimuth resolution (-1 means same as range resolution). set the desiderd azimuth
% resolution
rho_az = 1;

% Squint for the focusing (deg).
squint = [-15 0 15];

% Starting sample to process in slow-time. This is useful to trow away some
% samples at the beginning of the acquisition
index_start = 1;


%% Start the processing

% loading the parameters of the radar (f0,PRI,PRF,BW,fs,gains, waveform, etc.)
radar_parameters = loadRadarParameters(experiment_folder,"bistatic");

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
%% Bistatic processing
[POSE, lla0, targets] = loadDroneTrajectory(experiment_folder);
[tx_enu, rx_enu] = alignDroneRadarTime(POSE, targets, tau_ax, radar_parameters);

if strcmp(radar_parameters.mode, "bistatic")
    Drc_corr = correctTimeShift(Drc, tx_enu, rx_enu, t_ax);
    Drc_corr1 = correctFreqShift(Drc_corr,tx_enu, rx_enu, radar_parameters.f0);
    Drc = Drc_corr1;
end

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

    % Filter the range compressed data with a gaussian filter in range to
    % remove sidelobes
    Drc = filterRange(Drc, t_ax, radar_parameters.B);

    % Low pass filter and undersample the range compressed data. We have a very
    % high PRF, so we can do it
    [Drc_lp, PRF, tau_ax] = lowPassFilterAndUndersample(Drc, radar_parameters.PRF, tau_ax, USF);

    showDopplerPlot(Drc(1:end,:),tau_ax, t_ax(1:end), "full");
    caxis([140, 200])

    figure; imagesc(tau_ax, t_ax*3e8/2, db(Drc_lp));
    caxis([100,140]);
    xlabel("Slow time [s]");
    ylabel("range [m]");
    axis xy
    title(["Range compressed data", "With zero doppler notching", "With range filtering for sidelobes removal", "Filtered and undersampled in slow-time"]);
end
%% Coordinate transformation
% define the rotation matrix to use SCH reference frame. It is like XYZ,
% where S move along the aperture
[enu2sch, center_enu] = computeENU2SCH(rx_enu);

rx_sch = (rx_enu - center_enu) * enu2sch;
tx_sch = (tx_enu - center_enu) * enu2sch;

rx_speed = [0;diff(rx_sch(:,1))] ./ (tau_ax(2)-tau_ax(1));


figure,subplot(3,1,1),plot(rx_sch(:,1)),title("S"),grid
subplot(3,1,2),plot(rx_sch(:,2)), title("C"),grid
subplot(3,1,3),plot(rx_sch(:,3)), title("H"),grid

for n = 1:length(targets)
    tgt_sch(n,:) = ([targets(n).X targets(n).Y targets(n).Z] - center_enu) * enu2sch;
end


% Scenario ENU
figure, plot(rx_enu(:,1),rx_enu(:,2),"LineWidth",1.7), title("Scenario ENU"), hold on
plot(rx_enu(1,1),rx_enu(1,2),'ro')
for n = 1:3
    plot(targets(n).X,targets(n).Y,'^r',LineWidth=1)
end
%TX
plot(targets(4).X,targets(4).Y,'^g',LineWidth=1)
plot(targets(5).X,targets(5).Y,'^k',LineWidth=1)
hold off


figure, plot(rx_sch(:,1),rx_sch(:,2),"LineWidth",1.7), title("Scenario SCH"), hold on
plot(rx_sch(1,1),rx_sch(1,2),'ro')
for n = 1:3
    plot(tgt_sch(n,1),tgt_sch(n,2),'^r',LineWidth=1)
end
%TX
plot(tgt_sch(4,1),tgt_sch(4,2),'^g',LineWidth=1)
plot(tgt_sch(5,1),tgt_sch(5,2),'^k',LineWidth=1)
hold off
%% Focusing
if rho_az == -1
    rho_az = radar_parameters.rho_rg;
end

% traj.Sx = zeros(size(Drc,2),1);
% traj.Sx(Nbegin:Nend) = linspace(-15,15,length(Nbegin:Nend));
% traj.Sy = zeros(size(traj.Sx));
% traj.Sz = zeros(size(traj.Sx));


% Define the backprojection grid
x_ax = min(rx_sch(:,1))*2 : rho_az/2 : max(rx_sch(:,1))*2;
y_ax = 1*(1 : radar_parameters.rho_rg/2 : 500);
[X,Y] = meshgrid(x_ax,y_ax);
Z = zeros(size(X));

Nbegin = 35000;%exp1
Nend = 96000;
%Nbegin = 17157;%exp9
%Nend = 71916;

[stack,sumCount] = focusingCUDA(Drc(:,Nbegin:Nend), t_ax, radar_parameters.f0, tx_sch(Nbegin:Nend,:), rx_sch(Nbegin:Nend,:),rx_speed(Nbegin:Nend), X,Y,Z, rho_az, squint);
%I = focusDroneTDBP(Drc_lp(:,Nbegin:Nend), t_ax, radar_parameters.f0,...
%    traj.Sx(Nbegin:Nend), traj.Sy(Nbegin:Nend), traj.Sz(Nbegin:Nend),...
%    X,Y,Z,...
%    rho_az, squint);
%%
squintIdx = 3;
I = stack(:,:,squintIdx);
Ieq = I ./ sumCount(:,:,squintIdx);
figure; imagesc(x_ax,y_ax,10*log10(abs(I).^2)); colorbar; axis xy
xlabel("x [m]"); ylabel("y [m]"); title("Focused SAR image");

for n = 1:3
    hold on
    plot(tgt_sch(n,1),tgt_sch(n,2),'^r',LineWidth=1)
end
%TX
plot(tgt_sch(4,1),tgt_sch(4,2),'^g',LineWidth=1)
hold off
axis xy tight
%set(gca, 'YDir','reverse')
%set(gca, 'XDir','reverse')
caxis([5,50])
%caxis([1e7 11e7]);
% Autofocusing