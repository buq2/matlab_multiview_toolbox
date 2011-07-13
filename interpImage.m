function outimg = interpImage(imgx,imgy,img,interpx,interpy,outsize)
%Performs 2 interpolation to image (or any 3D matrix)
%
%Inputs:
%      imgx/y - Coordinates of matrix 'img' (2D matrices)
%      img        - Image or any 3D matrix
%      interpx/y  - Interpolation points
%                    If vectors and numel(interpx) == numel(imgx)
%                    output will be automatically reshaped.
%      outsize    - (optional) In case if interpx is vector this input can
%                    be used to set size of output
%Outputs:
%      outmg      - Interpolated image, numeric class same as inputs
%
%Matti Jukola 2011.02.19

if nargin < 6
    if numel(interpx) == numel(imgx);
        outimg = zeros(size(img),class(img));
    else
        outimg = zeros(size(interpx,1),size(interpx(2)),size(img,3),class(img));
    end
else
    outimg = zeros([outsize(1) outsize(2) size(img,3)],class(img));
end

if ~isfloat(img)
    img = single(img);
end

for ii = 1:size(img,3)
    outimg(:,:,ii) = reshape(interp2(imgx,imgy,img(:,:,ii),interpx,interpy),size(outimg(:,:,ii)));
end