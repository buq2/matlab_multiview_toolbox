function p = lineintersect2Dpairwise(l,limit)
%For each possible line pair in l, calculate intersection p
%
%Inputs:
%      l     - Implicit lines
%      limit - [minY minX maxY maxX] Minimum and maximum allowed point
%              values (others will not be returned).
%Outputs:
%      p - Homogenous points
%
%Matti Jukola 2011.02.02

num = size(l,2);
p = NaN(3,num*num/2+num/2);

num = 0;
for ii = 1:size(l,2)-1
    for jj = ii+1:size(l,2)
        num = num+1;
        p_tmp = cross(l(:,ii),l(:,jj));
        if nargin > 1
            p_tmp = wnorm(p_tmp);
            if p_tmp(1) < limit(2) || p_tmp(1) > limit(4) || p_tmp(2) < limit(1) || p_tmp(2) > limit(3)
               continue 
            end
        end
        p(:,num) = p_tmp;
    end
end

p(:,isnan(p(1,:))) = [];