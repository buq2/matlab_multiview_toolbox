function [sifts testvals blockdata_raw ...
    blockdata_filt blockdata_color blockdata_final] = ...
    matchRectifiedSimpleColor(img1,img2,maxshift,filtwin)
%Uses block matching on rectified images to find pixel neighborhood sifts
%
%Matti Jukola 2011.02.20

if numel(maxshift) == 1
    maxshift = [0 maxshift];
end
maxshift = -fliplr(maxshift);


%Color distance
fun = @(img1,img2)(sum((img1-img2).^2,3));

blockdata_raw = calculateBlock(img1,img2,fun,maxshift);

%Try to separate kernel

%First make sure that sum(h) == 1
filtwin = filtwin./sum(filtwin(:));

if size(filtwin,3) > 1
    error('Function supports only 2D filters')
end
h1 = filtwin(:,1);
h2 = h1\filtwin;
h = h1*h2;

if all((filtwin(:)-h(:))<eps('single')*sum(h(:)))
    %Can be separated
    disp('Filter kernel can be separated in to two 1D filters')
    blockdata_filt = convn(blockdata_raw,h1,'same');
    blockdata_filt = convn(blockdata_raw,h2,'same');
else
    %Can not be separated
    disp('Filter kernel can not be separated (slow)')
    blockdata_filt = convn(blockdata_raw,filtwin,'same');
end

%Calculate color distance matrix
%%
C = makecform('srgb2lab');
img1_lab = applycform(uint8(img1),C);
img2_lab = applycform(uint8(img2),C);
blockdata_color = calculateBlock(img1_lab,img2_lab,fun,maxshift);
gamma_c = 14;
gamma_p = 36;
k = -1;
w = k*exp(bsxfun(@minus,-blockdata_color./gamma_c,permute(abs((maxshift(1):maxshift(2))')./gamma_p,[2 3 1])));
%%
blockdata_final = blockdata_filt .* w;

[testvals sifts] = min(blockdata_final,[],3);
shiftvals = -(maxshift(1):maxshift(2));
sifts = reshape(shiftvals(sifts),size(sifts));

function blockdata = calculateBlock(img1,img2,fun,maxshift)
img1 = single(img1);
img2 = single(img2);
blockdata = NaN(size(img1,1),size(img1,2),maxshift(2)-maxshift(1)+1,'single');
lay = 0;
for shift = maxshift(1):maxshift(2)
    lay = lay+1;
    as = abs(shift);
    if shift < 0
        img1s = img1(:,as+1:end,:);
        img2s = img2(:,1:end-as,:);
        blockdata(:,as+1:end,lay) = fun(img1s,img2s);
    elseif shift > 0
        img1s = img1(:,1:end-as,:);
        img2s = img2(:,as+1:end,:);
        blockdata(:,1:end-as,lay) = fun(img1s,img2s);
    else
        blockdata(:,:,lay) = fun(img1,img2);
    end
end