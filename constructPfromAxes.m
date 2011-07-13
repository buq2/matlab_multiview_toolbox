function [P info] = constructPfromAxes(ax)
%Matti Jukola 2010
if nargin < 1
    ax = gca;
end
set(ax,'projection','perspective')
P = view(gca);
P(2,:) = -P(2,:);
P = -P;
info.pos = get(ax,'cameraPosition');
info.target = get(ax,'cameraTarget');
info.up = get(ax,'cameraUpVector');
info.viewangle = get(ax,'cameraViewAngle');
%P = P(1:3,:);
