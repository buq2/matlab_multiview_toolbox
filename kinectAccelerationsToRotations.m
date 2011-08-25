function R = kinectAccelerationsToRotations(accel)
%Computes Kinect orientation from acceleration sensor readings.
%
%Inputs:
%      accel - 3xn matrix of acceleration sensor readings from kinectGrab.
%
%Outputs:
%      R     - 4x4xn matrix of rotation matrices.
%
%Example:
%
% [depth rgb accel] = kinectGrab(1);
% R = kinectAccelerationsToRotations(accel);
% [X Y Z invalidDepth] = kinectDepthToXYZ(depth);
% dat = [X(:) Y(:) Z(:) ones(numel(X),1)]';
% dat = inv(R)*dat; %Back to "normal" coordinates
% X(:) = dat(1,:);
% Y(:) = dat(2,:);
% Z(:) = dat(3,:);
% X(invalidDepth) = NaN;
% Y(invalidDepth) = NaN;
% Z(invalidDepth) = NaN;
% surf(X,Z,Y,'edgecolor','none','FaceColor','texturemap','cdata',Z) %Easier to look at when permuted
% set(gca,'xdir','reverse')

numvec = size(accel,2);
accelVec = bsxfun(@rdivide,accel,sqrt(sum(accel.^2)));
accelVec(2,:) = -accelVec(2,:);
%Lets use accelVec as 'up-vector'
%Create right and forward vectors
%Right vector can be chosen freely
upVec = accelVec;
rightVec = zeros(size(accelVec));
%rightVec(3,:) = 1; %Roll toimii
rightVec(3,:) = 1;
forVec = zeros(size(accelVec));
for ii = 1:numvec
    forVec(:,ii) = cross(upVec(:,ii),rightVec(:,ii));
    forVec = bsxfun(@rdivide,forVec,sqrt(sum(forVec.^2)));
    
    %Now we need to calculate new right vector
    rightVec(:,ii) = wnorm(cross(forVec(:,ii), upVec(:,ii)));
    rightVec = bsxfun(@rdivide,rightVec,sqrt(sum(rightVec.^2)));
end

R = zeros(4,4,numvec);

%Calculate 3D pose
for ii = 1:numvec
    up = upVec(:,ii);
    right = rightVec(:,ii);
    forward = forVec(:,ii);
    
    R(:,:,ii) = [forward up right zeros(3,1);zeros(1,3) 1]';
end

