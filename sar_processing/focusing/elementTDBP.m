function [Sn,Wn] = elementTDBP(X,Y,Z,TX_pos_x,TX_pos_y,TX_pos_z,RX_pos_x,RX_pos_y,RX_pos_z,lambda,Dk,RC,t,f0,k_rx_0,y_ax)
%ELEMENTFUNCTDBP Summary of this function goes here
%   Detailed explanation goes here

R_tx = sqrt((TX_pos_x - X).^2 + (TX_pos_y - Y).^2  + ...
    (TX_pos_z - Z).^2);                                           %Range distances from the tx antenna [m]

R_rx = sqrt((RX_pos_x-X).^2 + (RX_pos_y - Y).^2  + ...
    (RX_pos_z - Z).^2);                                           %Range distances from the rx antenna [m]
distance = R_tx+R_rx;                                               %Total Tx-target-Rx distance [m]
delay = distance./physconst('LightSpeed');

%Compute target wave number
R = sqrt((RX_pos_x - X).^2 + (RX_pos_y - Y).^2);

temp = (X-RX_pos_x)./R;
temp(temp > 1) = 1;
temp(temp < -1) = -1;
psi = asin(temp);
k_rx = sin(psi).*(2*pi/lambda);

%Weight function
%         Wn = rectpuls((k_rx - k_rx_0)./psi_proc);
sigma = Dk/2;
Wn = exp(-0.5*((k_rx - k_rx_0)./sigma).^2);

cut = find(y_ax>RX_pos_y);                                       %Cut the back-lobe
if(~isempty(cut))
    cut = cut(1);

    Wn(1:cut,:) = zeros(size(Wn(1:cut,:)));
end
% Backprojection of data from a single Radar position
Sn = Wn.*interp1(t,RC(:),delay).*exp(+1i*2*pi*f0*delay);
end

