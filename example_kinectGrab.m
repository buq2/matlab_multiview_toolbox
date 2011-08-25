K_rgb = reshape([5.2264754445438268e+02, 0., 3.1898233378335067e+02, 0.,5.2281923529567291e+02, 2.4004311532231731e+02, 0., 0., 1.],[3 3])';
distortion_rgb = [2.6500366608125003e-01, -9.3179278499705598e-01,-9.5362199394449711e-04, 1.0121010318791741e-03,1.1227544625552663e+00];
radial_rgb = distortion_rgb([1 2 5]);
tangential_rgb = distortion_rgb([3 4]);
K_depth = reshape([5.8680160380538359e+02, 0., 3.0852862818515104e+02, 0., 5.8765587998528531e+02, 2.3483705083973686e+02, 0., 0., 1.],[3 3])';
distortion_depth = [-1.3543579586687302e-01, 6.4945176104838909e-01, -1.9691140916813683e-03, -2.6837429982855118e-03, -1.0090299717545017e+00];
radial_depth = distortion_depth([1 2 5]);
tangential_depth = distortion_depth([3 4]);
R = reshape([9.9994855279432382e-01, -9.2814542247140770e-03, 4.0922331326492334e-03, 9.2385810989796761e-03, 9.9990350964648000e-01, 1.0374006744223806e-02, -4.1881241403509571e-03, -1.0335666602893243e-02,9.9993781487253441e-01],[3 3])';
T = [2.4158781090188233e-02, -2.5259041391054410e-03,2.5188423349242228e-03]';
depth_base_and_offset = [7.84662664e-02, 1.07061072e+03];
%% Get raw data
numFrames = 50;
[depth rgb accel] = kinectGrab(numFrames);
%%
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
for ii = 1:size(rightVec,2)
    forVec(:,ii) = cross(upVec(:,ii),rightVec(:,ii));
    forVec = bsxfun(@rdivide,forVec,sqrt(sum(forVec.^2)));
    
    %Now we need to calculate new right vector
    rightVec(:,ii) = wnorm(cross(forVec(:,ii), upVec(:,ii)));
    rightVec = bsxfun(@rdivide,rightVec,sqrt(sum(rightVec.^2)));
end


%% Plot raw data
for ii = 1:numFrames
    figure(1)
    imagesc(depth(:,:,ii));
    figure(2)
    imagesc(rgb(:,:,:,ii));
    drawnow
end

%% Calibrate data
%realDepth = depth./2048.*depth_base_and_offset(1)+depth_base_and_offset(2);
%realDepth = (depth * -depth_base_and_offset(1)+depth_base_and_offset(2));
%realDepth = 1.0 ./ (depth * -0.0030711016 + 3.3309495161);
realDepth = depth_base_and_offset(1)*mean([K_depth(1,1),K_depth(2,2)]) / (1/8 * (depth_base_and_offset(2) - depth));
% 202cm, 261
% 261-202
% %%
% 324-241
%
invalidDepth = depth == 2^11-1;

w = 640;
h = 480;
[pixX pixY] = meshgrid(0:w-1,0:h-1);
X = bsxfun(@times,(pixX - K_depth(1,3))/K_depth(1,1), realDepth);
Y = bsxfun(@times,(pixY - K_depth(2,3))/K_depth(2,2), realDepth);
Z = realDepth;

colorPosX = ((X+T(1)) * K_rgb(1,1) ./ (Z+T(3))) + K_rgb(1,3);
colorPosY = ((Y+T(2)) * K_rgb(2,2) ./ (Z+T(3))) + K_rgb(2,3);
colorPosInvalid = colorPosX<1 | colorPosY<1 | colorPosX>w | colorPosY>h | invalidDepth;

X(colorPosInvalid) = NaN;
Y(colorPosInvalid) = NaN;
Z(colorPosInvalid) = NaN;

%%
for ii = 1:5:numFrames
%for ii = 38
    R = interp2(pixX,pixY, single(rgb(:,:,1,ii)), colorPosX(:,:,ii), colorPosY(:,:,ii));
    G = interp2(pixX,pixY, single(rgb(:,:,2,ii)), colorPosX(:,:,ii), colorPosY(:,:,ii));
    B = interp2(pixX,pixY, single(rgb(:,:,3,ii)), colorPosX(:,:,ii), colorPosY(:,:,ii));
    
    R = uint8(R);
    G = uint8(G);
    B = uint8(B);
    
    %Calculate straightening matrix
    up = upVec(:,ii);
    right = rightVec(:,ii);
    forward = forVec(:,ii);
    %Rst = [up right forward zeros(3,1);zeros(1,3) 1];
    %Rst = [-right forward -up zeros(3,1);zeros(1,3) 1];
    
    %Roll toimi
    %Rst = [up -forward -right zeros(3,1);zeros(1,3) 1];
    
    %Roll toimii    
    %Rst = [up -right -forward zeros(3,1);zeros(1,3) 1];
    
    %Ylös alas toimii
    %Rst = [right forward up zeros(3,1);zeros(1,3) 1]';
    
    %Roll toimii, ylös alas toimii?
    Rst = [forward up right   zeros(3,1);zeros(1,3) 1]';
    
   
    x = X(:,:,ii);
    y = Y(:,:,ii);
    z = Z(:,:,ii);
    
    dat = [x(:) y(:) z(:) ones(numel(x),1)]';
    dat = wnorm(inv(Rst)*dat);
    x(:) = -dat(1,:);
    y(:) = dat(3,:);
    z(:) = dat(2,:);
    
    
    surf(x,y,z,cat(3,R,G,B),'edgecolor','none','FaceColor','texturemap');
    %set(gca,'zDir','reverse')
    axis equal
    xlabel('x')
    ylabel('y')
    zlabel('z')
    drawnow
end
%% Remove distortions
ii = 41;
img1 = rgb(:,:,:,ii);
img2 = depth(:,:,ii);

invalidDepth = img2 == 2^11-1;

rgb_ud = undistortImage(img1,K_rgb,radial_rgb,tangential_rgb);
depth_ud = undistortImage(img2,K_depth,radial_depth,tangential_depth);
invalid_ud = undistortImage(single(invalidDepth),K_depth,radial_depth,tangential_depth);

invalidDepth = invalid_ud ~= 0;
realDepth = depth_base_and_offset(1)*mean([K_depth(1,1),K_depth(2,2)]) ./ (1/8 * (depth_base_and_offset(2) - depth_ud));
%realDepth = 1.0 ./ (depth_ud * -0.0030711016 + 3.3309495161);

w = 640;
h = 480;
[pixX pixY] = meshgrid(0:w-1,0:h-1);
X = bsxfun(@times,(pixX - K_depth(1,3))/K_depth(1,1), realDepth);
Y = bsxfun(@times,(pixY - K_depth(2,3))/K_depth(2,2), realDepth);
Z = realDepth;

%colorPosX = ((X+T(1)) * K_rgb(1,1) ./ (Z+T(3))) + K_rgb(1,3);
%colorPosY = ((Y+T(2)) * K_rgb(2,2) ./ (Z+T(3))) + K_rgb(2,3);

colorPosX = ((X-T(1)) * K_rgb(1,1) ./ (Z+T(3))) + K_rgb(1,3);
colorPosY = ((Y-T(2)) * K_rgb(2,2) ./ (Z+T(3))) + K_rgb(2,3);

colorPosInvalid = colorPosX<1 | colorPosY<1 | colorPosX>w | colorPosY>h | invalidDepth;
colorPosX(colorPosInvalid) = 0;
colorPosY(colorPosInvalid) = 0;

X(colorPosInvalid) = NaN;
Y(colorPosInvalid) = NaN;
Z(colorPosInvalid) = NaN;

R = interp2(pixX,pixY, single(rgb_ud(:,:,1)), colorPosX(:,:), colorPosY(:,:));
G = interp2(pixX,pixY, single(rgb_ud(:,:,2)), colorPosX(:,:), colorPosY(:,:));
B = interp2(pixX,pixY, single(rgb_ud(:,:,3)), colorPosX(:,:), colorPosY(:,:));

R = uint8(R);
G = uint8(G);
B = uint8(B);

%Calculate straightening matrix for 3D
up = upVec(:,ii);
right = rightVec(:,ii);
forward = forVec(:,ii);

Rst = [forward up right   zeros(3,1);zeros(1,3) 1]';

x = X(:,:);
y = Y(:,:);
z = Z(:,:);

dat = [x(:) y(:) z(:) ones(numel(x),1)]';
dat = wnorm(inv(Rst)*dat);
x(:) = -dat(1,:);
y(:) = dat(3,:);
z(:) = dat(2,:);


surf(x,y,z,cat(3,R,G,B),'edgecolor','none','FaceColor','texturemap');
%set(gca,'zDir','reverse')
axis equal
xlabel('x')
ylabel('y')
zlabel('z')
drawnow