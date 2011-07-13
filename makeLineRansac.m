function [l best] = makeLineRansac(x1,maxdist)
%Calculates line 'l' from points in x1
%
%Inputs:
%      x1      - Points (homogenous coordinates)
%      maxdist - Maximum dinstance from line so that point is called an
%                 inlier.
%Outputs:
%      l       - Homogenous line
%      best    - Some additional information about RANSAC run
%
%Matti Jukola 2011

maxiter = 1000;
pointsel = 2;
nump = size(x1,2);
if nargin < 2
    maxdist = 3^2; %Maximun 3 pixel reprojection error
else
    maxdist = maxdist^2; %Squareroot not taken from distances
end

if size(x1,2) < pointsel
    error('Too few input points')
end

x1 = wnorm(x1);

%For low nump this lowers maximum number of iterations
maxiter = min(maxiter,nchoosek(nump+1,pointsel)); 

%Best found Line
best.l = NaN(3,1);
best.inliers = -Inf; %How well this line performs
best.inliers_std = Inf;

N = Inf; % Algorithm 4.5 p.121
minprob = 0.99;
sample_count = 0;

ii = 1; %Number of iterations
while ii <= maxiter && N > sample_count %Algo 4.5
   idxs = randi(nump,pointsel,1);
   while numel(unique(idxs)) ~= pointsel
       idxs = randi(nump,pointsel,1);
   end
   
   l = makeLine2DFromPoints2D(x1(:,idxs(1)),x1(:,idxs(2)));
   
   d = calculateLinedist(l,x1,false);
   
   idx = abs(d) < maxdist;
   inliers = sum(idx);
   inliers_std = std(abs(d(idx)));
   e = 1-inliers/nump; %Algo 4.5

   if inliers > best.inliers || inliers == best.inliers && inliers_std < best.inliers_std
       best.inliers = inliers;
       best.inliers_std = inliers_std;
       best.l = l;
   end

   N = log(1-minprob)/log(1-(1-e)^pointsel);
   if isinf(N)
      N = Inf; %Positive inf
   end
   sample_count = sample_count + 1;
   ii = ii+1;
end
l = best.l;
best.maxdist = maxdist;
best.pointsel = pointsel;
best.maxiter = maxiter;
best.number_of_iterations = ii-1;
