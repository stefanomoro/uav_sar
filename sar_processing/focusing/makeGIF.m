function [] = makeGIF(stack,squint,x_ax,y_ax,rx_sch,tx_sch,tgt_sch,cax)
%MAKEGIF Make gif with multiple focused image, Mode => 1 not eq, 2 eq
%   [] = makeGIF(const,scenario,RX,TX,targets,focus,mode,caxis)


fig = figure("WindowState","maximized");
idxs = [ 1:length(squint) length(squint)-1 :-1:2];
images = cell(size(idxs));

for i = 1:length(idxs)
    % F =20*log10 (filterHammingFocus(F_vec(:,:,idxs(i)),3) );
    I =stack(:,:,idxs(i));

    printFocused(hamming2DFilter(I,3), x_ax, y_ax, rx_sch,tx_sch,tgt_sch, cax,strcat("Squint angle ",num2str(squint(idxs(i))),"°" ))

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

