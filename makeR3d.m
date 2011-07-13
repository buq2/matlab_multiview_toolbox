function [rx ry rz] = makeR3d(r)
%Creates rotation matrices rx, ry, rz from three angles 
%(r(1) -> rx, r(2) -> ry, r(3) -> rz
%
%Matti Jukola 2011.01.23

rx = [1 0 0;
      0 cos(r(1)) -sin(r(1));
      0 sin(r(1)) cos(r(1))];
      
ry = [cos(r(2)) 0 sin(r(2));
      0 1 0;
      -sin(r(2)) 0 cos(r(2))];

rz = [cos(r(3)) -sin(r(3)) 0;
      sin(r(3)) cos(r(3)) 0;
      0 0 1];
      