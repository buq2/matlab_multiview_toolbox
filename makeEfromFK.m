function E = makeEfromFK(F,K1,K2)
%Compute essential matrix E from fundamental matrix F and calibration
%matrix for first view K1 and calibration matrix for second view K2
%
%If K2 is not given, function will assume that K1 and K2 are same
%
%Matti Jukola 2010.12.21
%
%HZ2 (9.12) p.257

if nargin < 3
    K2 = K1;
end

E = K2'*F*K1;