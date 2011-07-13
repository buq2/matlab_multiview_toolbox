function p = lineintersect2D(p1,p2,useplot)
%Calculates point 'p' which is closest to lines formed by point pairs 'p1'
%'p2'.
%
%Inputs: 
%      p1 = [x1_1 y1_1;...] (note nx2 matrix)
%           OR imline handles 
%           OR Implicit 2D lines (a*x+b*y+c*w = 0) as 3xn matrix
%           OR Explicit 2D lines (y=k*x+t) as 2xn matrix
%      p2 = [x2_1 y2_1;...] OR [] if imline handles, implicit 2D lines
%                      or explicit 2d lines were used as first argument
%      useplot = If true and point pairs or imlines were used, result will
%                be plotted.
%Outputs:
%      p = [x y 1]' (Homogenous coordinates)
%
%Algorithm:
%      Minimize dot product between 'p' (point being searched) and
%      Implicit lines formed by p1 and p2 .
%
% Example:
% lineintersect2D([0 0;0 0],[0 1;1 0],true)
% lineintersect2D(rand(3,2),rand(3,2),true)
% lineintersect2D([1 2; 5 4; 2 3],rand(3,2).*2,true)
%
%Matti Jukola 2010.07.08
%2011.02.02 - Added support for implicit and explicit 2D lines
%
%There might be something fishy about this function

if nargin < 3
    useplot = false;
end

%Save input type for later use
input_type = 'point_pairs';
if isa(p1(1),'imline')
    input_type = 'imline';
elseif (nargin < 2 || isempty(p2)) && size(p1,1) == 3
    input_type = 'implicit';
elseif (nargin < 2 || isempty(p2)) && size(p1,1) == 2
    input_type = 'explicit';
end

%Input contains imline handles, convert them to implicit lines
if strcmp(input_type,'imline')
    tmp_lines = p1;
    p1 = zeros(numel(tmp_lines),3);
    
    if useplot
        %For plotting we need xlims
        xlims = zeros(numel(tmp_lines),3);
    end
    
    for ii = 1:numel(tmp_lines)
        pos = tmp_lines(ii).getPosition();
        
        if useplot
            xlims(:,ii) = pos(:,1);
            if all(xlims(:,ii) == [0 0]')
                xlims(:,ii) = pos(:,2);
            end
        end
        
        p1(ii,:) = makeLine2DFromPoints2D(pos(1,:),pos(2,:));
    end
elseif strcmp(input_type,'point_pairs')
    if useplot
        xlims = [p1(:,1)';p2(:,1)'];
    end
    p1 = makeLine2DFromPoints2D(p1',p2');
end

%Actual algorithm
%Set a^2+b^2 = 1
d = sqrt(sum(p1(1:2,:).^2));
p1 = bsxfun(@rdivide,p1,d);
[U S V] = svd(p1',false);
p = V(:,end);
p = (p(1:2)./p(3))';


if useplot && exist('xlims','var')
   figure
   hold on
   for ii = 1:size(p1,2)
       drawLine(p1(:,ii),xlims(:,ii));
   end
   plot(p(1),p(2),'r.');
   hold off
end

