function [] = printFocused(I, x_ax, y_ax, rx_sch,tx_sch,tgt_sch, cax, title_txt)
%PRINTFOCUSED print the focused image with trajectories and targets
%   Detailed explanation goes here

I =db(abs(I));
imagesc(x_ax,y_ax,I); colorbar; axis xy
colormap("jet")
xlabel("x [m]"); ylabel("y [m]");
hold on

plot(rx_sch(:,1),rx_sch(:,2),"LineWidth",1.7), hold on
plot(rx_sch(1,1),rx_sch(1,2),'ro')
for n = 1:size(tgt_sch,1)
    plot(tgt_sch(n,1),tgt_sch(n,2),'^r',LineWidth=1)
end
%TX
plot(tx_sch(1,1),tx_sch(1,2),'*g',LineWidth=1)
hold off
axis xy tight equal


title(title_txt);
clim(cax)
end

