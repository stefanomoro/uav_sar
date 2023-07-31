function [enu2sch, center_enu]= computeENU2SCH(pos_enu)   

A = [pos_enu(:,1) pos_enu(:,2)];
origin = mean(A,1);
A = A - origin;
[~,~,V] = svd(A' * A);
% Transforming from NED to SCH with SVD. 
% The transformation is done with Vt (V hermitian), knowing that A = U * diag(S) * Vt
% ned2sch = [
%     B.Vt[1,1] B.Vt[1,2] 0;
%     B.Vt[2,1] B.Vt[2,2] 0;
%     0 0 -1
% ]
Vt = V';
enu2sch = [
    Vt(1,1) Vt(1,2) 0;
    Vt(2,1) Vt(2,2) 0;
    0 0 1;
    ];

center_enu = [origin , 0];



end