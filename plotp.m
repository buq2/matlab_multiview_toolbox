function plotp(xy,label,markertype)
%Matti Jukola (matti.jukola % iki.fi)
%Version history:
%  2010.04.xx - Initial version
if isempty(xy)
    return
end
if nargin < 2 || isempty(label)
    label = false;
end
if nargin < 3
   markertype = 'r.'; 
end
xy = wnorm(xy);
puthold = ~ishold;
if puthold
    useHold = @()hold;
else
    useHold = @()([]); 
end
if size(xy,1) == 4
    plot3(xy(1,:),xy(2,:),xy(3,:),markertype,'markersize',19,'linewidth',6)
    useHold();
    plot3(xy(1,1),xy(2,1),xy(3,1),'m*','markersize',19,'linewidth',6)
    if size(xy,2) > 1
        plot3(xy(1,2),xy(2,2),xy(3,2),'g*','markersize',3,'linewidth',3)
    end
    useHold();
    xlabel('x-Axis')
    ylabel('y-Axis')
else
    plot(xy(1,:),xy(2,:),markertype,'markersize',19,'linewidth',6)
    useHold();
    plot(xy(1,1),xy(2,1),'m*','markersize',19,'linewidth',6)
    if size(xy,2) > 1
        plot(xy(1,2),xy(2,2),'g*','markersize',3,'linewidth',3)
    end
    useHold();
end

if label
   useHold();
   for ii = 1:size(xy,2)
       if size(xy,1) == 4
           text(xy(1,ii),xy(2,ii),xy(3,ii),num2str(ii),'color',[0 0 1]);
       else
           text(xy(1,ii),xy(2,ii),num2str(ii),'color',[0 0 1]);
       end
   end
   useHold();
end

if size(xy,1) ~= 4
    %Reverse ydir for 2d points
    set(gca,'ydir','reverse')
end
%axis equal