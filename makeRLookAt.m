function R = makeRLookAt(c,lookat)
%Create rotation matrix R from camera center c and point to which
%camera is looking at (lookat). Both points should be homogenous 3D points
%
%Camera up-direction will be "almost" [0 0 1 1]' (camera is straight /
%camera is not rotated around pricipal point).
%
%Reference: Antti Puhakka - 3D-grafiikka pp.174-175
%Note that in the reference camera up-vector is [0 1 0 1]'
%
%Matti Jukola 2011.01.23
if numel(c) ~= 4 || numel(lookat) ~= 4
    error('Both points must be homogenous 3D points')
end

c = wnorm(c(:));
lookat = wnorm(lookat(:));

%Look at direction
v = c-lookat;
v = v(1:3);
v = v./norm(v);

%Camera is not rotated around principal point
uy = [0 0 1]';
ux = cross(uy,-v);
ux = ux./norm(ux);
uz = -v;


%Calculate correct uy
uy = cross(uz,ux);

%Now R is
R = [ux';uy';uz'];