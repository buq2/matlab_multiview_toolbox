function best = ransacSelect(xy,img)
if nargin < 2
    imgTst = false;
else
    imgTst = true; 
end

num_initial = 7; %How many closest points are tested
num_sel = 4; %How many points (+center point) are used to calculate transform
maxdist = 30;

best.res = 0;
best.center = NaN(3,1);
best.nbors = NaN(3,num_sel);
best.H = NaN(3,3);

%After selecting num_initial closest points, we must form all permutations
%of these points and try all orderings of these points (perm_points)
sel_perm_points = nchoosek(1:num_initial,num_sel);

%Create 'real' world coordinates
rxyw = [0  0  1; %Center
        0  1  1;
        1  0  1;
        0 -1  1;
       -1  0  1]';

numpoints = numel(xy)/2;
sel_final_points = zeros(num_sel+1,3);
xyw = [xy ones(numpoints,1)];
points = zeros(num_initial,3);
for ii = 1:numpoints 
    center = xyw(ii,:); %Center point
    %d = ipdm(center(1:2),[xy(1:ii-1,:) ; xy(ii+1:end,:)],'Subset','SmallestFew','Limit',num_initial,'Result','Structure');
    d = ipdm_closestfew_squared(center(1:2), [xy(1:ii-1,:) ; xy(ii+1:end,:)], num_initial);
    %d = ipdm_closestfew_squared_small_lim(center(1:2), [xy(1:ii-1,:) ; xy(ii+1:end,:)], num_initial);
    %Make sure thath points are little bit spread up (not very close to 
    %each other
    if max(d.distance) < 15^2
        continue
    end
    
    k = d.columnindex;
    k(k>=ii) = k(k>=ii)+1;
    points_tmp = xyw(k,:); %Closest points
    sel_final_points(1,:) = center; %These points will be used to form transformation
    
    %Sort points by angle
    tmp = bsxfun(@minus,points_tmp(:,1:2),center(1:2));
    [all_angles idx] = sort(atan2(tmp(:,2),tmp(:,1)));
    
    %Calculate doubled angles
    all_angles = all_angles*2;
    ax = cos(all_angles);
    ay = sin(all_angles);
    ang = atan2(ay,ax)/2;
    
    points(:,:) = points_tmp(idx,:);
    
    for jj = 1:size(sel_perm_points,1) %Go trough all sets of possible point combinations
        %Each angle must have equal opposite one (negative/positive)
        ang2 = ang(sel_perm_points(jj,:));
        if any([abs(ang2(1)-ang2(3)) abs(ang2(2)-ang2(4))] > 15/180*pi) %max 15 asteen heitto
           continue;
        end
               
        %Select points around the center
        sel_final_points(2:end,:) = points(sel_perm_points(jj,:),:); %This set of points will be used to form transformations
        
        %Make sure that we have little variation on points
        if ~any(sel_final_points(:,1)-sel_final_points(1,1)) || ~any(sel_final_points(:,2)-sel_final_points(1,2))
            continue
        end
        
        %Make trasform from pixel coordinates to real world coordinates
        H = makeH(sel_final_points',rxyw);
        
        %Now we can transform pixel coordinates and test what kind of grid
        %they form (or any)
        %Use only few closest points
        tp = wnorm(H*points');
        
        %Make sure that this is some kind of grid
        %if (max(tp(1,:)) < 3.5 && min(tp(1,:)) < -3.5 && max(sum(abs(tp(1:2,:)-round(tp(1:2,:))))) < 0.25)
        if max(sum(abs(tp(1:2,:)-round(tp(1:2,:))))) < 1 %Simple and fast check
            %Make sure that distance between points is at least 0.9 units
            %dd = ipdm(tp(1:2,:)','Subset','NearestNeighbor','Result','Structure');
            dd = ipdm_nearest_squared(tp(1:2,:));
            if min(dd.distance) > 0.9^2 && max(dd.distance) < 1.5^2
                %Check how well this transform performs for all points
                %Transform all points
                tp_all = wnorm(H*xyw');
                %Points should be close to grid points
                err = sum(abs(tp_all(1:2,:)-round(tp_all(1:2,:))));
                idx = err < 1;
                %Points should not be close to other points
                %ddd = ipdm(tp_all(1:2,:)','Subset','NearestNeighbor','Result','Structure');
                ddd = ipdm_nearest_squared(tp_all(1:2,:));
                idx = idx' & ddd.distance > 0.8^2 & ddd.distance < 1.8^2;
                %Calibration platter is not huge, remove too far away
                %points
                dist_center = sqrt(sum(tp_all(1:2,:)'.^2,2));
                idx = idx & dist_center < maxdist^2;
                
                %Calculate performance (there is better ways to calculate
                %performance)
                res = sum(idx)-sum(err(idx));
                
                %Save results if best
                if res > best.res
                    %If image is provided, check that variance of the image
                    %is some what constant near the edges of the squares.
                    %If it is not, we might have selected diagonal
                    if imgTst
                        testWinHalf = 2;
                        testPLocation = [0 0.5 1;0 -0.5 1; 0.5 0 1; -0.5 0 1]';
                        tstP = round(wnorm(inv(H)*testPLocation));
                        tstVars = zeros(4,1);
                        for tstPii = 1:size(tstP,2)
                            tstI = img(tstP(2,tstPii)-testWinHalf:tstP(2,tstPii)+testWinHalf,...
                                tstP(1,tstPii)-testWinHalf:tstP(1,tstPii)+testWinHalf);
                            tstVars(tstPii) = var(tstI(:));
                        end
                    end
                    if ~imgTst || max(tstVars)/min(tstVars) < 50
                        best.res = res;
                        best.center = center';
                        best.nbors = sel_final_points(2:end,:)';
                        best.H = H;
                    end
                end
           end
        end
    end
end
return

function s = ipdm_closestfew_squared(p1,p2,limit)
distance = sum(bsxfun(@minus,p2,p1).^2,2);
[distance idx] = sort(distance(:));
s.distance = distance(1:limit);
s.columnindex = idx(1:limit);
return

function s = ipdm_closestfew_squared_small_lim(p1,p2,limit)
distance = sum(bsxfun(@minus,p2,p1).^2,2);
s.distance = Inf(limit,1);
s.columnindex = zeros(limit,1);
%for ii = 1:limit
%    [s.distance(ii) s.columnindex(ii)] = min(distance(:));
%    distance(s.columnindex(ii)) = Inf;
%end
m = Inf;
idx = 1;
for ii = 1:numel(distance)
    if distance(ii) < m
        s.distance(idx) = distance(ii);
        s.columnindex(idx) = ii;
        [m idx] = max(s.distance);
    end
end
return

function s = ipdm_nearest_squared(p)
p = p';
n = size(p,1);
distance = sum(bsxfun(@minus,reshape(p,[n 1 2]) ,reshape(p,[1 n 2])).^2,3);
ind = 1:length(distance);
ind = ind + (ind-1).*length(distance);
distance(ind) = Inf;
[s.distance s.columnindex] = min(distance,[],2);
return

