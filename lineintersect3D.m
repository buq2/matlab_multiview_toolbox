function p = lineintersect3D(p1,p2,useplot)
%Calculates point 'p' which is closest to lines formed by point pairs 'p1'
%'p2'. 
%
%Input: 
%      p1 = [x1_1 y1_1 z1_1;...]
%      p2 = [x2_1 y2_1 z2_1;...]
%      useplot = Should result be plotted
%Output:
%      p = [x y z]
%
%Algorithm forms two 3D planes from each 3D line (intersection of these two
%planes define the line) and then calculates point in spece which minimizes
%distance to these planes.
%There might be better (faster, more stabile) algorithm, but this should still suffice.
%
% Example:
% lineintersect3D([0 0 0;0 0 0],[0 0 1;0 1 0],true)
% lineintersect3D(rand(3,3),rand(3,3),true)
% lineintersect3D([1 2 3; 5 4 3; 2 3 1],rand(3,3).*2,true)
%
%Matti Jukola 2010.07.08
if nargin < 3
    useplot = false;
end

mat = zeros(size(p1,1)*2,4);
for ii = 1:size(p1,1)
   l = [p1(ii,:);p2(ii,:)];
   k1 = [l; rand(1,3)];
   crossvec = cross(k1(1,:)-k1(3,:),k1(2,:)-k1(3,:));
   k2 = [l; k1(3,:)+crossvec];
   [U S V] = svd([k1 ones(3,1)],false);
   k1 = V(:,end)';
   [U S V] = svd([k2 ones(3,1)],false);
   k2 = V(:,end)';
   mat((ii-1)*2+1:ii*2,:) = [k1;k2]; 
end

[U S V] = svd(mat,false);
res = V(:,end);
res = res./res(4);

p = res;

if useplot
   figure
   plot3([p1(:,1) p2(:,1)]',[p1(:,2) p2(:,2)]',[p1(:,3) p2(:,3)]')
   hold on
   plot3(p(1),p(2),p(3),'r.');
   hold off
end

