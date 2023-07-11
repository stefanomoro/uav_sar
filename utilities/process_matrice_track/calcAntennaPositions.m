% Script for taking DARTS data, and giving the positions of the antennas
function POSE = calcAntennaPositions(POSE,locTx,locRx)
% APM data - data from the flight controller (gives roll/pitch/yaw and timings from GPS)
% POS - reference positions
% locTx - offset for the TX antenna
% locRx - offset for the RX antenna

POSE.TX = nan(numel(POSE.UTC),3);
POSE.RX = nan(numel(POSE.UTC),3);

% Find antenna positions
for jj = 1:numel(POSE.UTC)

    phi = POSE.roll(jj)/180.0*pi;
    the = POSE.pitch(jj)/180.0*pi;
    psi = POSE.yaw(jj)/180.0*pi;

    % rotate vec to actual attitude, and then sum to POSE in ENU reference
    % frame
    vecNED = axesrot(locTx,phi,the,psi);
    POSE.TX(jj,:) = [vecNED(2) vecNED(1) -vecNED(3)] + [ POSE.X(jj), POSE.Y(jj), POSE.Z(jj)];
    vecNED = axesrot(locRx,phi,the,psi);
    POSE.RX(jj,:) = [vecNED(2) vecNED(1) -vecNED(3)] + [ POSE.X(jj), POSE.Y(jj), POSE.Z(jj)];

end

return
end


function xp = axesrot(x,phi,the,psi,dflag)
%
%  AXESROT  Finds vector components in a rotated coordinate system.
%
%  Usage: xp = axesrot(x,phi,the,psi,dflag);
%
%  Description:
%
%    Computes the components of input vector x in an axis system
%    which is rotated by the Euler angles phi, the, and psi.
%    Input dflag is optional.
%
%  Input:
%
%       x = input (3 x 1) vector or (npts x 3) matrix of input vectors.
%     phi = Euler roll angle, rad.
%     the = Euler pitch angle, rad.
%     psi = Euler yaw angle, rad.
%   dflag = rotation flag (optional):
%           = 1 for body to earth axes conversion (default).
%           = 0 for earth to body axes conversion.
%
%  Output:
%
%    xp = rotated input (3 x 1) vector
%         or (npts x 3) matrix of input vectors.
%

%
%    Calls:
%      None
%
%    Author:  Eugene A. Morelli
%
%    History:
%      17 June 1995 - Created and debugged, EAM.
%      12 July 2004 - Changed name from axcnv.m to axesrot.m, EAM.
%
%  Copyright (C) 2006  Eugene A. Morelli
%
%  This program carries no warranty, not even the implied
%  warranty of merchantability or fitness for a particular purpose.
%
%  Please email bug reports or suggestions for improvements to:
%
%      e.a.morelli@nasa.gov
%
[m,n]=size(x);
xp=zeros(m,n);
if nargin<5
    dflag=1;
end
sphi=sin(phi);
sthe=sin(the);
spsi=sin(psi);
cphi=cos(phi);
cthe=cos(the);
cpsi=cos(psi);
%
%  More than one vector to process.
%
if n > 1
    x=x(:,[1:3]);
    %
    %  Vectors of Euler angles.
    %
    if length(phi)==m,
        for i=1:m,
            lmat(1,1)=cthe(i).*cpsi(i);
            lmat(1,2)=cthe(i).*spsi(i);
            lmat(1,3)=-sthe(i);
            lmat(2,1)=sphi(i).*sthe(i).*cpsi(i) - cphi(i).*spsi(i);
            lmat(2,2)=sphi(i).*sthe(i).*spsi(i) + cphi(i).*cpsi(i);
            lmat(2,3)=sphi(i).*cthe(i);
            lmat(3,1)=cphi(i).*sthe(i).*cpsi(i) + sphi(i).*spsi(i);
            lmat(3,2)=cphi(i).*sthe(i).*spsi(i) - sphi(i).*cpsi(i);
            lmat(3,3)=cphi(i).*cthe(i);
            if dflag==1
                lmat=lmat';
            end
            xp(i,:) = (lmat*x(i,:)')';
        end
    else
        %
        %  Single set of the Euler angles, more
        %  than one vector to process.
        %
        lmat(1,1)=cthe(1).*cpsi(1);
        lmat(1,2)=cthe(1).*spsi(1);
        lmat(1,3)=-sthe(1);
        lmat(2,1)=sphi(1).*sthe(1).*cpsi(1) - cphi(1).*spsi(1);
        lmat(2,2)=sphi(1).*sthe(1).*spsi(1) + cphi(1).*cpsi(1);
        lmat(2,3)=sphi(1).*cthe(1);
        lmat(3,1)=cphi(1).*sthe(1).*cpsi(1) + sphi(1).*spsi(1);
        lmat(3,2)=cphi(1).*sthe(1).*spsi(1) - sphi(1).*cpsi(1);
        lmat(3,3)=cphi(1).*cthe(1);
        if dflag==1
            lmat=lmat';
        end
        xp=(lmat*x')';
    end
else
    %
    %  Single set of the Euler angles,
    %  one vector to process.
    %
    lmat(1,1)=cthe(1).*cpsi(1);
    lmat(1,2)=cthe(1).*spsi(1);
    lmat(1,3)=-sthe(1);
    lmat(2,1)=sphi(1).*sthe(1).*cpsi(1) - cphi(1).*spsi(1);
    lmat(2,2)=sphi(1).*sthe(1).*spsi(1) + cphi(1).*cpsi(1);
    lmat(2,3)=sphi(1).*cthe(1);
    lmat(3,1)=cphi(1).*sthe(1).*cpsi(1) + sphi(1).*spsi(1);
    lmat(3,2)=cphi(1).*sthe(1).*spsi(1) - sphi(1).*cpsi(1);
    lmat(3,3)=cphi(1).*cthe(1);
    if dflag==1
        lmat=lmat';
    end
    xp=lmat*x;
end
return
end

