function [focused_stack,SumCount] = focusingCUDA(Drc, t_ax, f0, tx_sch, rx_sch,rx_speed, X,Y,Z, rho_az, squint)
%FOCUSINGTDBP compute the focusing on the defined grid with TDBP
%   [focus] = focusingTDBP_CUDA(const,radar,scenario,RX,TX,ang_vec)

% Processed Antenna aperture
%focus.psi_proc = const.lambda / 2 / scenario.grid.pho_az;
%focus.R_min = 50;
%focus.synt_apert = 2 * tan(focus.psi_proc/2) * focus.R_min;

% Processed wavenumbers
Dk = single(2*pi/rho_az);

% Sqint angle vectors
%focus.angle_vec = ang_vec(:);

% Copy variables for optimizing parfor
%reset(gpuDevice)
idxs = t_ax >= 0;
t_ax = t_ax(idxs);
RC = Drc(idxs,:);


% remove mean value from grid 
%X = scenario.grid.X;
%Y = scenario.grid.Y;
%reference_x = mean(X(:,1));
%reference_y = mean(Y(1,:));
X = single(X);
Y = single(Y);
%ref = [reference_x;reference_y;0];
tic
TX_pos = single(tx_sch);
TX_pos_x = gpuArray(TX_pos(:,1));TX_pos_y = gpuArray(TX_pos(:,2));TX_pos_z = gpuArray(TX_pos(:,3));
RX_pos = single(rx_sch);
RX_pos_x = gpuArray(RX_pos(:,1));RX_pos_y = gpuArray(RX_pos(:,2));RX_pos_z = gpuArray(RX_pos(:,3));
RX_speed = single(rx_speed);
X = gpuArray(X); Y = gpuArray(Y); z0 = single(0);
lambda = single(single(physconst("LightSpeed")/f0)); f0 = single(f0);
RC = gpuArray(single(RC));
t_ax = gpuArray(single(t_ax));
median_speed = median(RX_speed);



disp (strcat("GPU array loading time: ",num2str(toc/60)," min"))

tic
    
k_rx_0_vec = single(sin(deg2rad(squint)).*(2*pi/lambda));
k_rx_0_vec = k_rx_0_vec(:);
  
[S,SumCount] = cudaFocusingv2(X,Y,z0,TX_pos_x,TX_pos_y,TX_pos_z,RX_pos_x,...
    RX_pos_y,RX_pos_z,lambda,Dk,RC,t_ax,f0,k_rx_0_vec,RX_speed,median_speed);
wait(gpuDevice);

SumCount = gather(SumCount);
focused_stack = gather(S);


disp (strcat("CUDA elaboration time: ",num2str(toc/60)," min"))
end

