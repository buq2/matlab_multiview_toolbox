function [T best] = makeTRansac(x1,x2,x3,maxdist,precalculateF)
%Calculates trifocal tensor T from three point correspondance groups x1, x2
%and x3 using random sample consensus.
%
%Inputs:
%      x1, x2, x3    - Three sets of points
%      maxdist       - Maximum distance of reprojection error
%      precalculateF - If true, remove those points which have bad fit
%                        when fit is calculated between two images using
%                        fundamental matrix. Default 'false' as usually
%                        points at this stage have already been paired
%                        using fundamental matrices.
%
%Matti Jukola 2010.12.21, 2011.05.28
%
%HZ Algorithm 16.4 p.401

if nargin < 4
    maxdist = 10; %Maximun x pixel reprojection error
end
if nargin < 5
    precalculateF = false;
end

maxiter = 1000;
pointsel = 7;

if ~all(size(x1)==size(x2) & size(x2)==size(x3))
    error('Inputs must be same size')
end
if size(x1,2) < pointsel
    error('Too few input points')
end

if precalculateF
    %ii) Two view correspondances
    F1 = makeFRansac(x1,x2);
    F2 = makeFRansac(x2,x3);
    d1 = calculateFdist(F1,x1,x2);
    d2 = calculateFdist(F2,x2,x3);
    
    %iii) Join the two view match sets
    idx = d1<maxdist & d2<maxdist;
    x1 = x1(:,idx);
    x2 = x2(:,idx);
    x3 = x3(:,idx);
end

nump = size(x1,2);
if size(x1,2) < pointsel
   warning('Too few correspondances after joining two view match sets') 
   T = [];
   best = [];
   return
end

%For low nump this lowers maximum number of iterations
s = warning('off', 'MATLAB:nchoosek:LargeCoefficient');
maxiter = min(maxiter,nchoosek(nump+1,pointsel)); 
warning(s);

%Best found T
best.T = NaN(3,3,3);
best.inliers = -Inf; %How well this F performs
best.inliers_std = Inf;

N = Inf; % Algorithm 4.5 p.121
minprob = 0.99;
sample_count = 0;

ii = 1; %Number of iterations
while ii <= maxiter && N > sample_count %Algo 4.5
    %iv) a) Select (unique) random points
    idxs = randi(nump,pointsel,1);
    while numel(unique(idxs)) ~= pointsel
        idxs = randi(nump,pointsel,1);
    end
    
    %iv) a) And calculate T for these points
    T = makeT(x1(:,idxs),x2(:,idxs),x3(:,idxs));
    if isempty(T)
        continue
    end
    e = 1;
    for jj = 1:size(T,5)
        t = T(:,:,:,jj);
        t = t./t(end); %T(end) must be 1?
        d = calculateTdist(t,x1,x2,x3,'reprojection');
        idx = abs(d) < maxdist;
        inliers = sum(idx);
        %inliers_dist = sum(d(idx));
        inliers_std = std(d(idx));
        e_ = 1-inliers/nump; %Algo 4.5
        if e_ < e %For each F, calculate only for best
            e = e_;
        end
        if inliers > best.inliers || inliers == best.inliers && inliers_std < best.inliers_std
            best.inliers = inliers;
            best.inliers_std = inliers_std;
            best.T = t;
        end
    end
    N = log(1-minprob)/log(1-(1-e)^pointsel);
    if isinf(N)
        N = Inf; %Positive inf
    end
    sample_count = sample_count + 1;
    ii = ii+1;
end
T = best.T;
best.maxdist = maxdist;
best.pointsel = pointsel;
best.maxiter = maxiter;
best.number_of_iterations = ii-1;