function plotCorrespondanceN(imgs,xs)
%Plots multiple point correspondances to multiple figures
%
%Inputs:
%      imgs - Cell array of images
%      xs   - Cell array of points. Each image must have equal number of
%               points
%
%Matti Jukola 2011.05.29

for ii = 1:numel(imgs)
    x = wnorm(xs{ii});
    
    figure
    imagesc(imgs{ii})
    hold on
    plot([x(1,:); x(1,:)],[x(2,:); x(2,:)],'.')
    hold off
end