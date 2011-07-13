function [x1 x2] = matchRectified(img1R,img2R,H1,H2,size_img1,size_grid,corr_size,minmax_x,minmax_y)
%Uses correlation matching to find dense point correspondaces for two images
%which have bee rectified

[X Y] = meshgrid(linspace(1,size_img1(2),size_grid(2)),linspace(1,size_img1(1),size_grid(1)));
X = convertToHom([X(:) Y(:)]');
x1 = wnorm(H1*X);

x2 = ones(3,size(X,2));

for ii = 1:size(x1,2)
    x1_ = round(x1(:,ii));
    x1(:,ii) = x1_;
    
    xlims1 = [x1_(1)-corr_size x1_(1)+corr_size];
    ylims1 = [x1_(2)-corr_size x1_(2)+corr_size];
    
    xlims1 = floor(interp1(minmax_x,[1 size(img1R,2)],xlims1));
    ylims1 = floor(interp1(minmax_y,[1 size(img1R,1)],ylims1));
    
    if xlims1(1) < 1 || xlims1(2) > size(img1R,2) || ylims1(1) < 1 || ylims1(2) > size(img1R,1)
       x2(:,ii) = NaN; 
       continue
    end
    
    ylims = [x1_(2)-corr_size x1_(2)+corr_size];
    ylims = floor(interp1(minmax_x,[1 size(img1R,2)],ylims));
    
    if isnan(ylims(1))
        ylims(1) = ylims(2)-corr_size*2;
    elseif isnan(ylims(2))
        ylims(2) = ylims(1)+corr_size*2;
    end
    
    if ylims(1) < 0
        ylims = ylims-ylims(1)+1;
    elseif ylims(2) > size(img2R,1);
        ylims = ylims-size(img2R,1)+ylims(2);
    end
    
    minimg1 = img1R(ylims1(1):ylims1(2),xlims1(1):xlims1(2),1);
    minimg2 = img2R(ylims(1):ylims(2),:,1);
    c = 2;
end

%function xlims = getXlims(x,H2,size_img1)
%y, y+, x, x+
%ls = [cross(H2*[0 0 1]',H2*[0 size_img1(1) 1]'), cross(H2*[0 size_img1(1) 1]',H2*[size_img1(2) size_img1(1) 1]') ...
%      cross(H2*[0 0 1]',H2*[size_img1(2) 0 1]'), cross(H2*[size_img1(2) size_img1(1) 1]',H2*[size_img1(2) 0 1]')]

