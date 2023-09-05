function [tx_enu, rx_enu] = alignDroneRadarTime(POSE, targets, tau_ax, radar_parameters)
%ALIGNDRONERADARTIME align drone and radar time, return ENU trajectory
%   return ENU trajectory of TX and RX, ready for bistatic case
[uniqueEpoch,uniqIdx] = unique(POSE.epoch);

rx_enu = vertcat(...
    interp1(uniqueEpoch,POSE.RX(uniqIdx,1), tau_ax, "linear"), ...
    interp1(uniqueEpoch,POSE.RX(uniqIdx,2), tau_ax, "linear"), ...
    interp1(uniqueEpoch,POSE.RX(uniqIdx,3), tau_ax, "linear") ...
    ).';



if strcmp(radar_parameters.mode,'bistatic')
    warning("Check tx idx for specific flight!!")
    TX_idx = 4;
    tx_enu = ones(size(rx_enu)) .* [targets(TX_idx).X, targets(TX_idx).Y, targets(TX_idx).Z];
else
    tx_enu = vertcat(...
        interp1(uniqueEpoch,POSE.TX(uniqIdx,1), tau_ax, "linear"), ...
        interp1(uniqueEpoch,POSE.TX(uniqIdx,2), tau_ax, "linear"), ...
        interp1(uniqueEpoch,POSE.TX(uniqIdx,3), tau_ax, "linear") ...
        ).';
end

end

