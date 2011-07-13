function A = wedgeProduct(X)
%Directly from Wikipedia (http://en.wikipedia.org/wiki/Exterior_algebra)
%In mathematics, the exterior product or wedge product of vectors is an 
%algebraic construction generalizing certain features of the cross product 
%to higher dimensions.
%
%Function calculates vector A for which dot(A,X(:,ii)) = 0 for each ii, etc
%
%TODO: Lis‰‰ hyv‰ viite laskentatavalle

dim = size(X,1);
m = mod(dim,2);
A = zeros(size(dim,1),1);
for ii = 1:dim
    A(ii) = (-1)^(ii+m)*det(X([1:ii-1 ii+1:dim],:));
end