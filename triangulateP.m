function X = triangulateP(P,x,method)
%Triangulation from multiple views
%P and x are cells
%
%Method 1 == Linear triangulation method (HZ2 p. 312)
%
%Matti Jukola 2010
if nargin < 3
    method = 1;
end

%Reserve memory
nump = size(x{1},2);
X = ones(4,nump);
for ii = 1:numel(x) %To real coordinates
    x{ii} = wnorm(x{ii});
end

if method == 1
    A = zeros(numel(x)*2,4);
    for ii = 1:size(x{1},2)
        for jj = 1:numel(x)
            start = ((jj)-1)*2+1;
            A(start,:) =   x{jj}(1,ii)*P{jj}(3,:) - P{jj}(1,:);
            A(start+1,:) = x{jj}(2,ii)*P{jj}(3,:) - P{jj}(2,:);
        end
        [U S V] = svd(A);
        X(:,ii) = V(:,end);
    end
end