function [enu2sch, center_enu]= computeENU2SCH(pos_enu)

% linear regression of path

x = pos_enu(1:10:end,1);
y = pos_enu(1:10:end,2);
center_enu = [mean(x),mean(y),0];
x = x - center_enu(1);
y = y - center_enu(2);
X = [ones(length(x),1) x];

b = X\y;
ang = atan(b(2));

enu2sch = [cos(ang) -sin(ang) 0;  ...
    sin(ang) cos(ang) 0; ...
    0 0 1];
end