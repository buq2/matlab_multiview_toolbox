function [H best] = makeHRansac(x1,x2,maxdist)
%Calculates homography matrix H from two point correspondance groups x1 
%and x2 using random sample consensus.
%
%Matti Jukola 2010.12.20
%
%HZ Algorithm 4.4 p.118

maxiter = 10000;
pointsel = 4;
nump = size(x1,2);
if nargin < 3
    maxdist = 2; %Maximun 2 pixel reprojection error
end
maxdist = maxdist^2; %As we don't later take squareroot

if ~all(size(x1)==size(x2))
    error('Inputs must be same size')
end
if size(x1,2) < pointsel
    error('Too few input points')
end

%For low nump this lowers maximum number of iterations
s = warning('off', 'MATLAB:nchoosek:LargeCoefficient');
maxiter = min(maxiter,nchoosek(nump+1,pointsel)); 
warning(s); 

%Best found H
best.H = NaN(3);
best.inliers = -Inf; %How well this C performs
best.inliers_std = -Inf;

N = Inf; % Algorithm 4.5 p.121
minprob = 0.99;
sample_count = 0;

x1 = wnorm(x1);
x2 = wnorm(x2);

%Workaround for missing randi (at least in r2007b with only few toolboxes)
if ~exist('randi','builtin')
    randi = @(maxval,size1,size2)round(rand(size1,size2)*(maxval-1))+1;
else
    %Seems like we have to redefine the randi, MATLAB might be confused
    %about the r2007b fix.
    randi = @(varargin)builtin('randi',varargin{:});
end

ii = 1; %Number of iterations
while ii <= maxiter && N > sample_count %Algo 4.5
   idxs = randi(nump,pointsel,1);
   while numel(unique(idxs)) ~= pointsel
       idxs = randi(nump,pointsel,1);
   end
   
   H = makeH(x1(:,idxs),x2(:,idxs));
   if isempty(H)
       continue
   end
   H = H./H(end); %TODO: is this necessary?
     
   x2_ = wnorm(H*x1);
   d = sum((x2(1:2,:)-x2_(1:2,:)).^2,1);
   
   idx = abs(d) < maxdist;
   inliers = sum(idx);
   inliers_std = std(abs(d(idx)));
   e = 1-inliers/nump; %Algo 4.5
   if inliers > best.inliers || inliers == best.inliers && inliers_std < best.inliers_std
       best.inliers = inliers;
       best.inliers_std = inliers_std;
       best.H = H;
   end
   N = log(1-minprob)/log(1-(1-e)^pointsel);
   if isinf(N)
      N = Inf; %Positive inf
   end
   sample_count = sample_count + 1;
   ii = ii+1;
end
H = best.H;
best.maxdist = maxdist;
best.pointsel = pointsel;
best.maxiter = maxiter;
best.number_of_iterations = ii-1;