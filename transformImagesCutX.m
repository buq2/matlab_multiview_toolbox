function [outimg minmax_x minmax_y X Y] = transformImagesCutX(img,H,outsize)
%Transforms images img using transformation matrices H
%Black boarders in x direction are cut
%
%Inputs:
%      img - Image or images. Cell array or in case of single image MxNxK
%            matrix. 
%      H   - Transformation matrices. Transformation matrices must not be
%            singular. Cell array.
%      outsize   
%          - (Optional) Size of output
%
%Note: If X and Y are not given, interpolation coordinates will be
%      calculated automatically
%
%Outpus:
%      outimg   - Transformed images
%      minmax_x - Output images left and right edges coordinates 
%                  (image x-axis)
%      minmax_y - Output images top and bottom edge coordinages
%                  (image y-axis)
%      X / Y    - Common interpolation coordinates
%
%Matti Jukola (2011.01.30), 2011.04.02

if ~iscell(img)
    outputMatrix = true;
    img = {img};
else
    outputMatrix = false;
end

if ~iscell(H)
    H = {H};
end

if numel(H) == 1 && numel(img) > 1
    H = repmat(H,size(img));
elseif numel(H) ~= numel(img)
    error('Don''t know which H belongs to which image. There should be equal number of Hs and images');
end


%Calculate interpolation coordinates
minmax_x = [Inf -Inf];
minmax_y = [Inf -Inf];
for ii = 1:numel(img)
    s = size(img{ii});
    corners = [0 s(2)-1 s(2)-1 0;
        0 0      s(1)-1 s(1)-1;
        1 1      1      1];
    tcorners = wnorm(H{ii}*corners);
    
    tmp = [min(tcorners(1,:)) max(tcorners(1,:))];
    if tmp(1) < minmax_x(1)
        minmax_x(1) = tmp(1);
    end
    if tmp(2) > minmax_x(2)
        minmax_x(2) = tmp(2);
    end
    
    tmp = [min(tcorners(2,:)) max(tcorners(2,:))];
    if tmp(1) < minmax_y(1)
        minmax_y(1) = tmp(1);
    end
    if tmp(2) > minmax_y(2)
        minmax_y(2) = tmp(2);
    end
end

if nargin < 3 && (minmax_x(2)-minmax_x(1))*(minmax_y(2)-minmax_y(1)) > 16e6
    error('Output image would be larger than 16MP, are you sure?')
end

outimg = cell(size(img));

sprev = [Inf Inf];
for ii = 1:numel(img)
    s = size(img{ii});
    corners = [0 s(2)-1 s(2)-1 0;
                   0 0      s(1)-1 s(1)-1;
                   1 1      1      1];
    tcorners = wnorm(H{ii}*corners);
    xlims = [min(tcorners(1,:)) max(tcorners(1,:))];
    if nargin < 3 
        %Approx
        outsize = round([minmax_y(2)-minmax_y(1) xlims(2)-xlims(1)]);
    end

    [X Y] = meshgrid(linspace(xlims(1),xlims(2),outsize(2)), ...
                                linspace(minmax_y(1),minmax_y(2),outsize(1)));
    Xp = convertToHom([X(:) Y(:)]');                        
    Xp_transformed = wnorm(inv(H{ii})*Xp);
    
    s = size(img{ii}); 
    if sprev(1) ~= s(1) || sprev(2) ~= s(2)
        [imgx imgy] = meshgrid(1:s(2),1:s(1));
        sprev = s;
    end
    outimg{ii} = interpImage(imgx,imgy,img{ii},Xp_transformed(1,:),Xp_transformed(2,:),outsize);
end

if outputMatrix
    outimg = outimg{ii};
end