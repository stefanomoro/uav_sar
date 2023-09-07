function [focused_stack,SumCount] = focusingTDBP(Drc, t_ax, f0, tx_sch, rx_sch, X,Y,Z, rho_az, squint)
% function I = focusDroneTDBP(Drc, t_ax, f0, tx_sch, rx_sch, X,Y,Z, rho_az, squint)

%FOCUSINGTDBP compute the focusing on the defined grid with TDBP
%   [focus] = focusingTDBP(const,radar,scenario,RX,TX,ang_vec)

[Ny,Nx] = size(X);

% % Processed Antenna aperture
% focus.psi_proc = const.lambda / 2 / scenario.grid.pho_az;
% focus.R_min = 50;
% focus.synt_apert = 2 * tan(focus.psi_proc/2) * focus.R_min;

% Processed wavenumbers
Dk = single(2*pi/rho_az);
% 
% % Squint angle vectors
% focus.angle_vec = ang_vec;

wbar = waitbar(0,strcat('Backprojecting n 1/',num2str(length(squint))));

% Copy variables for optimizing parfor
%reset(gpuDevice)
idxs = t_ax >= 0;
t = t_ax(idxs);
RC = Drc(idxs,:);
% remove mean value from grid 
% X = scenario.grid.X;
% Y = scenario.grid.Y;
X = single(X);
Y = single(Y);
% ref = [reference_x;reference_y;0].';

TX_pos = single(tx_sch);
TX_pos_x = gpuArray(TX_pos(:,1));TX_pos_y = gpuArray(TX_pos(:,2));TX_pos_z = gpuArray(TX_pos(:,3)); 
RX_pos = single(rx_sch);
RX_pos_x = gpuArray(RX_pos(:,1));RX_pos_y = gpuArray(RX_pos(:,2));RX_pos_z = gpuArray(RX_pos(:,3)); 
% RX_speed = gpuArray(single(RX.speed));
X = gpuArray(X); Y = gpuArray(Y); Z = gpuArray(single(Z));
f0 = single(f0); lambda = single(physconst("LightSpeed")/f0);
RC = gpuArray(single(RC));
y_ax = gpuArray(single(Y(:,1)));
t = gpuArray(single(t));
% median_speed = median(RX_speed);


% Initialize vectors for the result
focused_stack = zeros(size(X,1),size(X,2),length(squint),'single');
% focus.not_coh_sum = zeros(size(focus.Focused_vec),'single');
%SumCount = zeros(size(focused_stack),'single');

tic
for ang_idx = 1:length(squint)
    waitbar(ang_idx/length(squint),wbar,strcat("Backprojecting n "...
        ,num2str(ang_idx),"/",num2str(length(squint))));
    
    psi_foc = deg2rad(squint(ang_idx));
    k_rx_0 = single(sin(psi_foc).*(2*pi/lambda)); 
 
    S = gpuArray(zeros(Ny,Nx,'single'));
%     A = zeros(Nx,Ny,'gpuArray');
    SumCount = gpuArray(zeros(Ny,Nx,'single'));
    parfor n = 1 : size(RC,2)
        [Sn,Wn] = elementTDBP(X,Y,Z,TX_pos_x(n),TX_pos_y(n),TX_pos_z(n),RX_pos_x(n),...
           RX_pos_y(n),RX_pos_z(n),lambda,Dk,RC(:,n),t,f0,k_rx_0,y_ax);
        
        % Give less weight to not moving positions
        % speed_norm = RX_speed(n)/median_speed;
        % Count number of summations for each pixel
        SumCount = SumCount + Wn;
        
        % Coherent sum over all positions along the trajectory 
        S = S + Sn;
        % Inchoerent sum over all positions along the trajectory
%         A = A + abs(Sn);
    end
    waitbar(ang_idx/length(squint),wbar);
    
    % SumCount(:,:,ang_idx) = gather(SumCount);
    focused_stack(:,:,ang_idx) = gather(S);
%     focus.not_coh_sum(:,:,ang_idx) = gather(A); 
end

close(wbar)

disp (strcat("Total elaboration time: ",num2str(toc/60)," min"))
end

