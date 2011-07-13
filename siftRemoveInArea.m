function [a b] = siftRemoveInArea(a,b,forbitten)
idx = inpolygon(a(1,:),a(2,:),forbitten(:,1),forbitten(:,2));
a(:,idx) = [];
b(:,idx) = [];