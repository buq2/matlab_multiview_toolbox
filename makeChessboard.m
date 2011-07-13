function img = makeChessboard(X,Y)
%Creates chessboard from X and Y values
%
%Example: 
% [X Y] = meshgrid(linspace(-5,5,1024),linspace(-5,5,1024));
% x = [X(:) Y(:) ones(numel(X),1)]';
% h = [1 2 0;2 1 0.1;-0.2 0.5 1];
% x = wnorm(h*x);
% X(:) = x(1,:);
% Y(:) = x(2,:);
% imagesc(makeChessboard(X,Y))
X = floor(X);
Y = floor(Y);
img = xor(mod(X,2),mod(Y,2));
