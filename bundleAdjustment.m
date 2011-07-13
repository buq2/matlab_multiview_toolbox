function [P X] = bundleAdjustment(P,x,X,xtoX)
%Calculates bundle adjustment for camera matrices P, image point correspondances
%x and world points X.
%
%Inputs:
%       P    - Initial camera matrices (cell array, each cell containing 3x4
%                 matrix)
%       x    - Image points (cell array, each cell containin 3xn_i matrix.
%                 If not all image points have same correspondances,
%                 input xtoX must be given).
%       X    - (optional) Initial world points, 4xn (numeric) matrix
%       xtoX - (optional) (cell array) Correspondances between x and X.
%                 Each cell contains integer (index) from x{ii}(:,jj) to
%                 X(:,xtoX{ii}(jj))
%Outputs:
%       P    - Final P
%       X    - Final X
%
%HZ2 (18.1) p.435 (reference)
%HZ2 A6.6 p.613 Sparse bundle adjustment (reference)
%MASKS Algorithm 5.5 p.167 (reference)
%MASKS 11.3.3 p.397 (reference)

numP = numel(P);
numX = size(X,2);
numx = zeros(size(P));
for ii = 1:numel(numx)
   numx(ii) = size(x{ii},2);
end

%Input vector has format:
%[all camera matrices, column first (P{ii}(:));
% points X, column first (X(:))
inputvector = zeros(12*numP+numX*4,1);
for ii = 1:numP
   inputvector((ii-1)*12:ii*12) = P{ii}(:);
end
inputvector(numP*12+1:end) = X(:);

