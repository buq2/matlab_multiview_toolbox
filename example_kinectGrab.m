[depth rgb accel] = kinectGrab(1);
%%
for ii = 1:100
    %imagesc(depth(:,:,ii));
    imagesc(rgb(:,:,:,ii))
    drawnow
end
%%
R = kinectAccelerationsToRotations(accel);
[X Y Z invalidDepth] = kinectDepthToXYZ(depth);
[rgb invalidColor] = kinectRGBtransform(rgb,X,Y,Z);

dat = [X(:) Y(:) Z(:) ones(numel(X),1)]';
dat = inv(R)*dat; %Back to "normal" coordinates
X(:) = dat(1,:);
Y(:) = dat(2,:);
Z(:) = dat(3,:);

X(invalidDepth|invalidColor) = NaN;
Y(invalidDepth|invalidColor) = NaN;
Z(invalidDepth|invalidColor) = NaN;
surf(X,Z,Y,'edgecolor','none','FaceColor','texturemap','cdata',rgb) %Easier to look at when permuted
set(gca,'xdir','reverse')