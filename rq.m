function [r, q] = rq(a)
%Rq decomposition of matrix a
%Matti Jukola 2010

[q r] = qr(flipud(a).');
q = flipud(q');
r = rot90(r,2)';

if det(q)<0
    r = -r;
    q = -q;
end