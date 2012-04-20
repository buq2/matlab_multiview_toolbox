function ang = calculateAngleBetweenLines(l1,l2)
%Calculates angle between two implicit lines l_1 and l_2, l_i = a*x+b*y+c = 0
%such that the angle is always between -pi/2 and pi/2
%
%Input:
%     l1 - Implicit lines 3xn array
%     l2 - Second lines
%
%Output:
%     ang - Angle between lines l1 and l2 in radians
%
%NOTE: Might not handle vertical lines
%
%Based on: http://www.tpub.com/math2/5.htm
%
%Matti Jukola 2012-04-20

%Convert lines to slope factors
k1 = -l1(1,:)./l1(2,:);
k2 = -l2(1,:)./l2(2,:);

ks = sort([k1;k2]);

ang = atan((ks(2,:)-ks(1,:))/(1+prod(ks)));

%Try to handle vertical lines
vertidx1 = isinf(k1);
vertidx2 = isinf(k2);
paralines = vertidx1 & vertidx2;
vertidx1(paralines) = false;
vertidx2(paralines) = false;

%If both lines are vertical, angle is zero
ang(paralines) = 0;
%If one of the lines is vertical, angle is directly the slope factor of the
%other line
ang(vertidx1) = atan(k2);
ang(vertidx2) = atan(k1);


