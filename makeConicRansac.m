function [C best] = makeConicRansac(x1,maxdist)
%Calculates conic C from points x1 on the conic
%using random sample consensus.
%
%Matti Jukola 2011.06.12

maxiter = 1000;
pointsel = 5;
nump = size(x1,2);
if nargin < 2
    maxdist = 2; %Maximun 2 pixel reprojection error
end
maxdist = maxdist^2; %Check if correct

if size(x1,2) < pointsel
    error('Too few input points')
end

%For low nump this lowers maximum number of iterations
s = warning('off', 'MATLAB:nchoosek:LargeCoefficient');
maxiter = min(maxiter,nchoosek(nump+1,pointsel)); 
warning(s); 

%Best found C
best.C = NaN(3);
best.c = NaN(6,1);
best.inliers = -Inf; %How well this C performs
best.inliers_std = -Inf;

N = Inf; % Algorithm 4.5 p.121
minprob = 0.99;
sample_count = 0;

x1 = wnorm(x1);

%For clearer code
X = x1(1,:)';
Y = x1(2,:)';
%Form constraints
A = [X.^2 X.*Y Y.^2 X Y ones(numel(X),1)]; %= 0

ii = 1; %Number of iterations
while ii <= maxiter && N > sample_count %Algo 4.5
   idxs = randi(nump,pointsel,1);
   while numel(unique(idxs)) ~= pointsel
       idxs = randi(nump,pointsel,1);
   end
   
   [c C]= makeConic(x1(:,idxs));
     
   d = A*c;
   
   idx = abs(d) < maxdist;
   inliers = sum(idx);
   inliers_std = std(abs(d(idx)));
   e = 1-inliers/nump; %Algo 4.5
   if inliers > best.inliers || inliers == best.inliers && inliers_std < best.inliers_std
       best.inliers = inliers;
       best.inliers_std = inliers_std;
       best.C = C;
       best.c = c;
   end
   N = log(1-minprob)/log(1-(1-e)^pointsel);
   if isinf(N)
      N = Inf; %Positive inf
   end
   sample_count = sample_count + 1;
   ii = ii+1;
end
C = best.C;
best.maxdist = maxdist;
best.pointsel = pointsel;
best.maxiter = maxiter;
best.number_of_iterations = ii-1;