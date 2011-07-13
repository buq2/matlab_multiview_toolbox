function h = drawLine(lines,xlims)
%Plots 2D lines
%
%Inputs:
%      lines - 3xn array of homogenous lines
%      xlims - Plotting limit (x-axis)
%Outputs:
%      h     - Handles to plotted lines
%
%Note that if line is vertical, xlims is used as limits for yaxis (how high
%    will be drawn).
%
%HZ2 2.2.1 p.26
%
%Matti Jukola 2010

if nargin < 2
    xlims = xlim();
end

if nargout > 0
    h = zeros(size(lines,2),1);
end
for ii = 1:size(lines,2)
    a = lines(1,ii);
    b = lines(2,ii);
    c = lines(3,ii);
    if b == 0
        xs = (-b.*xlims-c)/a;
        ys = xlims;
    else
        xs = xlims;
        ys = (-a.*xlims-c)./b;
    end
    
    if nargout > 0
        h(ii) = line(xs,ys);
    else
        line(xs,ys);
    end
end
