function [X crosspoints] = randXfromPmulti(P,nump,minmaxdist)
%Generate random 3D-points which can be seen by cameras P
%
%Distribution of points is not guaranteed
%Function is experimental and might get into a infinite loop

numplanes = numel(P)*4;
encplanes = zeros(4,numplanes); %Enclosing planes

num = 1;
Cs = [];
for ii = 1:numel(P)
    encplanes(:,num) = P{ii}(1,:)'; %x-axis plane
    num = num+1;
    
    encplanes(:,num) = P{ii}(2,:)'; %y-axis plane
    num = num+1;
    
    %Decompose camera matrix to get paramters for creating other planes
    [K R C] = decomposeP(P{ii});
    C = wnorm(C);
    Cs(:,ii) = C;
    
    %Image plane size
    sizeimg = [K(1,3) K(2,3)]'*2; %[x y]'
    sizeimg(abs(sizeimg)<eps) = 1; %Force to have at least 1 pixel.
    
    %Create one test point which is at the camera principal axes (inside cone)
    Xtest = pinv(P{ii})*convertToHom(sizeimg/2);

    encplanes(:,num) = makePlaneFromX(C,pinv(P{ii})*[0 sizeimg(2) 1]',pinv(P{ii})*[sizeimg(1) sizeimg(2) 1]');
    if dot(encplanes(:,num),Xtest) < 0
        encplanes(:,num) = -encplanes(:,num);
    end
    num = num+1;
    
    encplanes(:,num) = makePlaneFromX(C,pinv(P{ii})*[sizeimg(1) 0 1]',pinv(P{ii})*[sizeimg(1) sizeimg(2) 1]');
    if dot(encplanes(:,num),Xtest) < 0
        encplanes(:,num) = -encplanes(:,num);
    end
    num = num+1;
end

%Add minimum and maximum planes
if nargin >= 3 %minmaxdist
    for ii = 1:numel(P)
        %Get pricipal point
        [K R C] = decomposeP(P{ii});
        pp = [K(1,3);K(2,3);1];
        
        %Reproject to 3D
        PP = wnorm(pinv(P{ii})*pp);
        
        %Normalize to unit length
        nnorm = PP-C;
        nnorm(4) = 1;
        nnorm(1:3) = nnorm(1:3)/norm(nnorm);
        
        %Get points on near and far plane
        nearpoint = C;
        nearpoint(1:3) = nearpoint(1:3)+nnorm(1:3)*minmaxdist(1);
        
        plane = makePlaneFromnX(nnorm,nearpoint);
        if dot(C,plane) > 0
            plane = -plane;
        end
        encplanes = [encplanes plane];
        
        farpoint = C;
        farpoint(1:3) = farpoint(1:3)+nnorm(1:3)*minmaxdist(2);
        
        plane = makePlaneFromnX(nnorm,farpoint);
        if dot(C,plane) < 0
            plane = -plane;
        end
        encplanes = [encplanes plane];
    end
end

numplanes = size(encplanes,2);

crosspoints = [];
for ii = 1:numplanes-2
    for jj = ii+1:numplanes-1
        for kk = jj+1:numplanes
            crosspoints = [crosspoints makeXfromPlanes(encplanes(:,ii),encplanes(:,jj),encplanes(:,kk))];
        end
    end
end

%Remove infs, nans and points very far away
crosspoints = wnorm(crosspoints);
d = sqrt(sum(wnorm(crosspoints).^2));
idx = any(isinf(crosspoints) | isnan(crosspoints)) | d>10^13;
crosspoints(:,idx) = [];



%Remove all but one camera center
for ii = 1:numel(P)    
    d = bsxfun(@minus,crosspoints,Cs(ii));
    d = sqrt(sum(d.^2));
    
    idx = d < eps('single');
    if numel(idx > 1)
        crosspoints(:,idx(2:end)) = [];
    end
end



%Remove all cross points which are outside of allowed area
%crosspoints = removeOutside(encplanes,crosspoints);

mx = [min(crosspoints(1,:)) max(crosspoints(1,:))];
my = [min(crosspoints(2,:)) max(crosspoints(2,:))];
mz = [min(crosspoints(3,:)) max(crosspoints(3,:))];
mmin = [mx(1);my(1);mz(1)];
mmax = [mx(2);my(2);mz(2)];


maxtries = 100;
X = [];
num = 0;
while size(X,2) < nump
    tmp = [rand(3,nump);ones(1,nump)];
    tmp(1:3,:) = bsxfun(@times,tmp(1:3,:),(mmax-mmin));
    tmp(1:3,:) = bsxfun(@plus,tmp(1:3,:),mmin);
    
    tmp2 = removeOutside(encplanes,tmp);
    
    X = [X tmp2];
    num = num+1;
    if num >= maxtries
        warning('Number of maximum tries exceeded')
        break;
    end
end
return

function X = removeOutside(encplanes,X)
for ii = 1:size(encplanes,2)
    d = sum(bsxfun(@times,X,encplanes(:,ii)));
    X(:,d<0) = [];
end
return



