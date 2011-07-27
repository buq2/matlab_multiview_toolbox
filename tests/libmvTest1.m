%Read two consecutive frames, search features, compare features (only
%distance compared)
fname = '/media/raid/DATA/data_raw/tracking_video/MVI_0654.MOV';
info = mmread(fname,0);
numFrames = -info.nrFramesTotal;

num = 0;
for ii = 1000:numFrames    
    num = num+1;
    data = mmread(fname,ii);
    img1 = data.frames.cdata;
    
    points = libmvDetector(img1);
    
    imagesc(img1);
    
    if num == 1;
        prevPoints = points;
        drawnow
        continue
    end
    
    
    [mPoints mPrevPoints] = libmvFeatureMatching(points,prevPoints);
    
    hold on
    plot([mPoints(1,:);mPrevPoints(1,:)],[mPoints(2,:);mPrevPoints(2,:)])
    plot(mPoints(1,:),mPoints(2,:),'b.')
    plot(mPrevPoints(1,:),mPrevPoints(2,:),'r.')
    hold off
    
    drawnow
    
    prevPoints = points;
end
%% Test descriptors
fname = '/media/raid/DATA/data_raw/tracking_video/MVI_0654.MOV';
ii = 1;
info = mmread(fname,0);
numFrames = -info.nrFramesTotal;
data = mmread(fname,ii);
img1 = data.frames.cdata;
points = libmvDetector(img1);

tic
fe = libmvDescriptor(img1,points(1:2,:));
toc
%% Test FLANN
p1 = rand(2,100);
p2 = rand(2,100);
idx = libmvFeatureMatchingFLANN(single(p1),single(p2));
plot(p1(1,:),p1(2,:),'b.');
hold on
plot(p2(1,:),p2(2,:),'r.');
plot([p1(1,idx(1,:));p2(1,idx(2,:))],[p1(2,idx(1,:));p2(2,idx(2,:))]);
hold off

%% Test detector, descriptor and FLANN
fname = '/media/raid/DATA/data_raw/tracking_video/MVI_0654.MOV';
ii = 1;
jj = 12;
data = mmread(fname,ii);
img1 = data.frames.cdata;
data = mmread(fname,jj);
img2 = data.frames.cdata;
p1 = libmvDetector(img1);
p2 = libmvDetector(img2);

feat1 = libmvDescriptor(img1,p1(1:2,:));
feat2 = libmvDescriptor(img2,p2(1:2,:));
feat1 = single(feat1);
feat2 = single(feat2);

idx = libmvFeatureMatchingFLANN(feat1,feat2);

plotCorrespondance(img1,img2,p1(:,idx(1,:)),p2(:,idx(2,:)));






