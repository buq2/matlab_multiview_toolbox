function x = wnorm(x)
%Matti Jukola (matti.jukola % iki.fi)
%Version history:
%  2010.04.xx - Initial version
x = bsxfun(@rdivide, x(1:end,:), x(end,:));