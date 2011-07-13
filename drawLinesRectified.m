function h = drawLinesRectified(img1,img2,numlines)
%Visualizes rectified image by plotting horizontal lines
%
%Outputs:
%       h  -  Handle to 'plot' object
%
%Matti Jukola 2011.05.28

if nargin < 3
    numlines = 50;
end

imagesc([img1 img2])
s1 = size(img1);
s2 = size(img2);
hold on
h_tmp = plot(repmat([1 s1(2)+s2(2)],[numlines 1])',repmat((linspace(1,s1(1),numlines)),[2 1]));
hold off

if nargout > 0
    h = h_tmp;
end