function S = makeSkew(u)
%HZ A4.2 p. 581
S = [0 -u(3) u(2);u(3) 0 -u(1);-u(2) u(1) 0];