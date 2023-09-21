function [] = makeGIF(stack,squint,x_ax,y_ax,tgt_sch,c_axis)
%MAKEGIF Make gif with multiple focused image, Mode => 1 not eq, 2 eq
%   [] = makeGIF(const,scenario,RX,TX,targets,focus,mode,caxis)


fig = figure("WindowState","maximized");
idxs = [ 1:length(squint) length(squint)-1 :-1:2];
images = cell(size(idxs));

for i = 1:length(idxs)
    % F =20*log10 (filterHammingFocus(F_vec(:,:,idxs(i)),3) );
    I =20*log10 (abs(stack(:,:,idxs(i))));
    imagesc(x_ax,y_ax,I); colorbar; axis xy
    colormap("jet")
    xlabel("x [m]"); ylabel("y [m]"); title("Focused SAR image");

    for n = 1:3
        hold on
        plot(tgt_sch(n,1),tgt_sch(n,2),'^r',LineWidth=1)
    end
    %TX
    plot(tgt_sch(4,1),tgt_sch(4,2),'^g',LineWidth=1)
    hold off
    axis xy tight
    title(strcat("Squint angle ",num2str(squint(idxs(i))),"°" ));
    clim(c_axis)
    frame = getframe(fig);
    images{i} = frame2im(frame);
end
% MAKE GIF
filename = strcat('multi_squint.gif'); % Specify the output file name
for idx = 1:length(images)
    [A,map] = rgb2ind(images{idx},256);
    if idx == 1
        imwrite(A,map,filename,'gif','LoopCount',Inf,'DelayTime',1.5);
    else
        imwrite(A,map,filename,'gif','WriteMode','append','DelayTime',1);
    end
end
end

