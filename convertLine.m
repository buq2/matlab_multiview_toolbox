function l = convertLine(l)
%Converts line from Explicit 2D line (y=k*x+t) presented as [k t]'
%to Implicit 2D (a*x+b*y+c*w = 0) presented as [a b c]' and vice versa.
%
%Inputs:
%      l - Line, either 2xn matrix or 3xn matrix
%Outpus:
%      l - Line, either 3xn matrix or 2xn matrix
%
%Note: When converting from 3xn presentation to 2xn presentation function
%      does not check if original line is vertical (b=0). If line is vertical
%      this will cause both k and t to become Inf (as they are divided with
%      0).
%
%Matti Jukola 2011.02.02

if numel(l) == 2 || numel(l) == 3
    l = l(:);   
end

if size(l,1) == 2
    l = [l(1,:);-ones(1,size(l,2));l(2,:)];
elseif size(l,1) == 3
    l = [l(1,:)./-l(2,:);l(3,:)./-l(2,:)];
else
    error('Multiple lines should be in 2xn or 3xn matrix')
end