function [xs Xs usedFrames] = findChessboardCornersVideo(fname,boardSize,invertColors,tryFrames)
%Find chessboard corners from video
%Assumes that corners are at the beginning of the video (1/5 of the length
%of the video)
%Requires mmread by Micah Richert
%
%Matti Jukola 2011.07.22

if nargin < 2
    boardSize = [15 15];
end
if nargin < 3
    invertColors = 1;
end

boardSize = double(boardSize);
invertColors = double(invertColors);
info = mmread(fname,0); %Read only info, no frames

%Try to find number of frames
if nargin < 4
    if info.nrFramesTotal == 0
        error('mmread can not obtain number of frames')
    end
    
    tryFrames = round(linspace(1,-info.nrFramesTotal/6,20));
end

xs = {};
Xs = {};
usedFrames = [];


for ii = 1:numel(tryFrames)
    [xs Xs usedFrames] = processFrame(fname,invertColors,boardSize,tryFrames(ii),xs,Xs,usedFrames);
end

for ii = 1:numel(usedFrames)-1
    anchorFrame = usedFrames(ii);
    
    numFails = 0;
    for jj = anchorFrame+1:2:usedFrames(ii+1)
        [xs Xs usedFrames success] = processFrame(fname,invertColors,boardSize,jj,xs,Xs,usedFrames);
        if success
            numFails = 0;
        else
            numFails = numFails+1;
            if numFails >= 3
                break;
            end
        end
    end
end

return


function [xs Xs usedFrames success] = processFrame(fname,invertColors,boardSize,frameNum,xs,Xs,usedFrames)
frame = mmread(fname,frameNum);
imagesc(frame.frames.cdata);
drawnow

if invertColors == 1
    img = 255-frame.frames.cdata;
else
    img = frame.frames.cdata;
end

[points success realPoints] = CVfindChessboardCorners(img,boardSize,0);
if success
    hold on
    plotp(points)
    hold off
    drawnow;
    
    num = numel(xs)+1;
    xs{num} = points;
    Xs{num} = realPoints;
    usedFrames(num) = frameNum;
end
return

