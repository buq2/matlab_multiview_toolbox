function [xy xyr startpoints] = generateGrid(H,reffun,giveHtoreffun)
if nargin < 3
    giveHtoreffun = false;
end
if ~giveHtoreffun
    %Refining function given does not support H -> make sure that
    %function still supports two arguments
    reffun = @(p,H)(reffun(p));
end
maxnump = 100;
xy = NaN(2,maxnump);
xyr = NaN(2,maxnump);

%Start by generating grid around (0,0)
s.center = [0 0];
s.H = H;
s.parent = NaN;
s.minp = NaN;
s.maxp = NaN;
startpoints = repmat(s,[100 1]);

%All visited real world coordinates
visited = {sparse(0),sparse(0),sparse(0),sparse(0)};

%Number of points found
pfound = 0;
%Number of startpoints used
sused = 0;
%Number of startpoints generated
sgen = 1;

%Next searchable areas
pnext = [3 0 0 -3;0 -3 3 0];

while sused < sgen && pfound < maxnump %While not all generated points have been traversed
    current = sused+1;
    s = startpoints(current);    
    [rp pp] = genGR(s.center,s.H);
    found = 0;
    for ii = 1:size(rp,2) %for all points
        tst = reffun(pp(:,ii),inv(s.H));
        if ~isempty(tst) && ~any(isnan(tst)) %Add found point to list of points
           found = found+1; 
           pfound = pfound+1;
           xy(:,pfound) = tst(:);
           xyr(:,pfound) = rp(:,ii);
        end
    end
    
    %Now we need to add points to our list
    %We should add points only if a least onw point was found
    %if less than 5 points were found, use also previous points from
    %parent. If parent.points + found points < 5 -> do not add any points
    addNext = false;
    if found >= 5
        addNext = true;
        s.minp = pfound-found+1;
        s.maxp = s.minp+found-1;
        %We can easily generate new H from found points
        %s.H = makeH([xy(:,s.minp:s.maxp); ones(1,s.maxp-s.minp+1)],...
        %           [xyr(:,s.minp:s.maxp); ones(1,s.maxp-s.minp+1)]);
        s.H = makeH([xyr(:,s.minp:s.maxp); ones(1,s.maxp-s.minp+1)],...
                    [xy(:,s.minp:s.maxp); ones(1,s.maxp-s.minp+1)]);
    elseif found > 2
        addNext = true;
        s.minp = pfound-found+1;
        s.maxp = s.minp+found-1;
        %We need to add parents points
        x1 = [xy(:,s.minp:s.maxp) xy(:,startpoints(s.parent).minp:startpoints(s.parent).maxp)];
        x1 = [x1; ones(1,numel(x1)/2)];
        x2 = [xyr(:,s.minp:s.maxp) xyr(:,startpoints(s.parent).minp:startpoints(s.parent).maxp)];
        x2 = [x2; ones(1,numel(x2)/2)];
        %s.H = makeH(x1,x2);
        s.H = makeH(x2,x1);
    end
    
    if (addNext)
       for ii = 1:size(pnext,2)
           next = s.center+pnext(:,ii)';
           vis = getVisited(visited,next);
           if isnan(vis)
               continue; %already processed
           elseif vis == 0 %not added
               %Copy information from parent
               ss = s;
               ss.center = next;
               ss.parent = current;
               ss.minp = NaN;
               ss.maxp = NaN;
               
               %Add to list
               sgen = sgen+1;
               startpoints(sgen) = ss;
               
               %Set as 'added'
               visited = setVisited(visited,next,current);
           else
              %Already added, should we change H? 
           end
       end       
    end
    
    %We have used this point
    sused = sused+1; 
    visited = setVisited(visited,s.center,NaN);
    startpoints(current) = s;
end
xy = xy(:,1:pfound);
xyr = xyr(:,1:pfound);
startpoints = startpoints(1:current);
   
return

%Generates 9 points around x,y
function [xyr xyp] = genGR(xy,H)
[X Y] = meshgrid(xy(1)-1:xy(1)+1,xy(2)-1:xy(2)+1);
xyr = [X(:) Y(:)]';
xyp = wnorm(H*[xyr;ones(1,numel(xyr)/2)]);
xyp = xyp(1:2,:);
return

function ret = getVisited(visited,xy)
idx = ((xy(1) < 0) + (xy(2) < 0)*2)+1;
xy = abs(xy)+1;
if xy(1) <= size(visited{idx},1) && xy(2) <= size(visited{idx},2)
   ret = visited{idx}(xy(1),xy(2));
else
   ret = 0; 
end
return

function visited = setVisited(visited,xy,val)
idx = ((xy(1) < 0) + (xy(2) < 0)*2)+1;
xy = abs(xy)+1;
visited{idx}(xy(1),xy(2)) = val;
return


