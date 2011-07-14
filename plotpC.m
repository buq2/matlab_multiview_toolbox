function plotpC(X, img, x)
%Plots 3D homogenous coordinates and colors the points using image colors
%colors
%
%Inputs:
%      X   - 3D homogenous coordinates, 4xn matrix
%      img - Image which to for point color
%      x   - x = PX (point correspondaces for X)
%
%Matti Jukola (matti.jukola % iki.fi)
%
%Version history:
%  2011.01.23 - Initial version

x = wnorm(x);
X = wnorm(X);

x = round(x);

puthold = ~ishold;

if isa(img,'uint8')
    img = single(img)./255;
end

for ii = 1:size(X,2)
    xp = x(1,ii);
    yp = x(2,ii);
    if xp < 1 || xp > size(img,2) || yp < 1 || yp > size(img,1)
        %Outside of the image (but why?), maybe calibrated (please don't
        %use calibrated pixels)
        error('Did you use calibrated points? -> image and points do not match')
    end
    c = img(x(2,ii),x(1,ii),:);
    c = c(:)';
    c(isnan(c)) = 0;
    if ii == 2 && puthold
        hold on
    end
    plot3(X(1,ii),X(2,ii),X(3,ii),'.','markersize',19,'linewidth',6,'color',c)
end
if puthold
    hold off
end
xlabel('x-Axis')
ylabel('y-Axis')