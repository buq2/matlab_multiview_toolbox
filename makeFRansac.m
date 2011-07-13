function [F best] = makeFRansac(x1,x2,maxdist,distmethod)
%Calculates fundamental matrix F from two point correspondance groups x1 
%and x2 using random sample consensus.
%
%Matti Jukola 2010
%
%   HZ Algorithm 11.4 p.291
maxiter = 1000;
pointsel = 8;
nump = size(x1,2);
if nargin < 3
    %maxdist = 1.5; %Maximun 1.5 pixel reprojection error
    maxdist = 0.001; %Sampson distance
end
if nargin < 4
    distmethod = 'sampson';
end

if ~all(size(x1)==size(x2))
    error('Inputs must be same size')
end
if size(x1,2) < pointsel
    error('Too few input points')
end

%For low nump this lowers maximum number of iterations
maxiter = min(maxiter,nchoosek(nump+1,pointsel)); 

%Best found F
best.F = NaN(3);
best.inliers = -Inf; %How well this F performs
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
   
   F = makeF(x1(:,idxs),x2(:,idxs));
   
   if isempty(F)
       continue
   end
   e = 1;
   for jj = 1:size(F,3)
       f = F(:,:,jj);
       f = f./f(end); %F(end) must be 1? (2010.07.22)
       d = calculateFdist(f,x1,x2,distmethod);
       idx = abs(d) < maxdist;
       inliers = sum(idx);
       inliers_std = std(abs(d(idx)));
       e_ = 1-inliers/nump; %Algo 4.5
       if e_ < e %For each F, calculate only for best
           e = e_;
       end
       if inliers > best.inliers || inliers == best.inliers && inliers_std < best.inliers_std
           best.inliers = inliers;
           best.inliers_std = inliers_std;
           best.F = f;
       end
   end
   N = log(1-minprob)/log(1-(1-e)^pointsel);
   if isinf(N)
      N = Inf; %Positive inf
   end
   sample_count = sample_count + 1;
   ii = ii+1;
end
F = best.F;
best.maxdist = maxdist;
best.pointsel = pointsel;
best.maxiter = maxiter;
best.number_of_iterations = ii-1;