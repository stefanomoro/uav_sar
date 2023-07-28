function [POSE,lla0, targets] = loadDroneTrajectory(experiment_folder)
%LOADDRONETRAJECTORY load preprocessed trajectory of drone (right now support Matrice M600PRO)
%   The trajectory is preprocessed via AirData server and then is Extracted
%   the ENU coordinates

lla0 = load(fullfile(experiment_folder,'..',"drone_tracks","lla0.mat")).lla0;
targets = load(fullfile(experiment_folder,'..',"drone_tracks","targets.mat")).targets;

dirContent = dir(fullfile(experiment_folder,'..',"drone_tracks","track*.mat"));
POSE = table();
for ii = 1:numel(dirContent)
    cont = dirContent(ii);
    pos = load(fullfile(cont.folder,cont.name)).POSE;
    POSE = [POSE; pos];
end

if isa(POSE.UTC(1), 'datetime')
    % Convert to UTC epoch
   POSE.epoch = double(convertTo(POSE.UTC,'epochtime'));
end


end

