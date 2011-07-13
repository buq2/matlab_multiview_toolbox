function out = subpxlCross(xy, H, g)
%XY original pixel location 
%H is from real coodinates to pixel coordinates
%g is gradient image

%Get pixel position in real coordinates
rpos = wnorm(H*[xy(:);1]);

numpxl_len = 51; %Number of pixels to be interpolateda across the edge
numpxl_wid = 111; %Half of the number of pixels to be used for line fitting
dist = 0.2; %Minimum distance from cross center(s)
wid = 0.3; %Width of interpolation area (-wid <-> wid) across the edge

%Coordinates used for 1D gaussian fit
fitcoords = linspace(-wid,wid,numpxl_len); 

%Calculate pixel coordinates for the corners of the image
[xcorn ycorn] = meshgrid([-1+dist 0 1-dist],[-1+dist 0 1-dist]);
xcorn = xcorn+rpos(1);
ycorn = ycorn+rpos(2);
corners = [xcorn(:) ycorn(:) ones(numel(xcorn),1)]';
corners = wnorm(inv(H)*corners);
corners = corners(1:2,:);
corners = [min(corners(1,:)) max(corners(1,:));min(corners(2,:)) max(corners(2,:))];
rcorners = round(corners);
%Smaller image of g for interpolation
if any(rcorners(2,:) < 1) || any(rcorners(2,:) > size(g,1)) || any(rcorners(1,:) < 1) ...
        || any(rcorners(1,:) > size(g,1)) || any(isnan(rcorners(:))) || rcorners(1,2)-rcorners(1,1) < 3 || rcorners(2,2)-rcorners(2,1) < 3
    out = [];
    return
end
cutImage = g(rcorners(2,1):rcorners(2,2),rcorners(1,1):rcorners(1,2));

%Create pixel coordinate mesh
[xp yp] = meshgrid(rcorners(1,1):rcorners(1,2),rcorners(2,1):rcorners(2,2));
%[xp yp] = meshgrid(linspace(corners(1,1),corners(1,2),size(cutImage,2)),linspace(corners(2,1),corners(2,2),size(cutImage,1)));

%Temporary space for rotated (interpolated image)
minimg = zeros(numpxl_len,numpxl_wid);

%For each part of the cross
%First one line
linex = zeros(2*numpxl_wid,1);
%How X and Y interpolation coordinates should be flipped in each iteration
lims = {{[dist 1-dist],[-wid wid]},{[-1+dist -dist],[-wid wid]}};
for ii = 1:numel(lims)
    %Create vector of image coordinates to be interpolated
    [X Y] = meshgrid(linspace(lims{ii}{1}(1),lims{ii}{1}(2),numpxl_wid),...
                 linspace(lims{ii}{2}(1),lims{ii}{2}(2),numpxl_len));
    %Real coordinate position is added -> interpolation goes to right place
    XY = [X(:)+rpos(1) Y(:)+rpos(2) ones(numel(X),1)]';
    XYp = wnorm(inv(H)*XY);
    
    %Interpolate image
    minimg(:) = interp2(xp,yp,cutImage,XYp(1,:),XYp(2,:));
    %And fit gaussian to each column
    for kk = 1:numpxl_wid
        linex((ii-1)*numpxl_wid+kk) = jf1dgauss(minimg(:,kk),fitcoords);
    end
end

%Calculate first line
fit_x = [linspace(-dist,dist-1,numpxl_wid) linspace(dist,1-dist,numpxl_wid)];
idx = isnan(linex);
linex(idx) = [];
if numel(linex) < 2
    out = [];
    return
end
fit_x(idx) = [];
line1 = jfmedline(fit_x,linex);

%Then the second one (switch x and y to rotate 90 degrees)
linex2 = linex;
for ii = 1:numel(lims)
    %Create vector of image coordinates to be interpolated
    [X Y] = meshgrid(linspace(lims{ii}{1}(1),lims{ii}{1}(2),numpxl_wid),...
                 linspace(lims{ii}{2}(1),lims{ii}{2}(2),numpxl_len));
    XY = [Y(:)+rpos(1) X(:)+rpos(2) ones(numel(X),1)]';
    XYp = wnorm(inv(H)*XY);
    
    %Interpolate image
    minimg(:) = interp2(xp,yp,cutImage,XYp(1,:),XYp(2,:));
    %And fit gaussian to each column
    for kk = 1:numpxl_wid
        linex2((ii-1)*numpxl_wid+kk) = jf1dgauss(minimg(:,kk),fitcoords);
    end
end

%Calculate second line, note X and Y are "reversed" compared to first line
fit_y = [linspace(-dist,dist-1,numpxl_wid) linspace(dist,1-dist,numpxl_wid)];
idx = isnan(linex2);
linex2(idx) = [];
if numel(linex2) < 2
    out = [];
    return
end
fit_y(idx) = [];
line2 = jfmedline(linex2,fit_y);

%Calculate line crossing using cross product 
%(derived from triple scalar product indentity)
%This crossing is in real world coordinates
linecros = wnorm(cross([line1(1) -1 line1(2)],[line2(1) -1 line2(2)])');
linecros(1:2) = linecros(1:2)+rpos(1:2);

%Convert linecrossing back to pixel coordinates
linecrospx = wnorm(inv(H)*linecros);

%When we selected smaller image (cutImage), we used rounded pixel coordinates
%we need to adjust final pixel coordinates with difference between rounded
%and not rounded coordinates
%Assume linear change
cdiff = corners-rcorners;
subchange = [interp1([-1+dist 1-dist],cdiff(1,:),linecros(1)-rpos(1)) interp1([-1+dist 1-dist],cdiff(2,:),linecros(2)-rpos(2))]';
out = linecrospx(1:2) - subchange;
