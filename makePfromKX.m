function P = makePfromKX(x,X,K)
%Experimental
%
%Calculates camera pose when calibration matrix K is known and we have
%at least 3 know 3D points. May return multiple Ps.
%
%Inputs:
%      x - Projected points (image points) 3xn
%      X - Known 3D points 4xn
%      K - Calibration matrix
%
%Output:
%      P - Camera matrix P = [R -RC] = [R T]
%
%(for 3 points)
%Fischler, Bolles - Random Sample Consensus: A Paradigm for Model Fitting
%        with Applications to Image Analysis and Automated Cartography
%
%(3 points and  >=4 points)
%Quan, Lan - Linear N-Point Camera Pose Determination
%
%Matti Jukola 2011.10.10

if size(X,2) == 3
    %Three point algorithm
    X = wnorm(X);
    x = wnorm(x);
    
    A_point = X(1:3,1);
    B_point = X(1:3,2);
    C_point = X(1:3,3);
    a_point = x(:,1);
    b_point = x(:,2);
    c_point = x(:,3);
    
    Rab = sqrt(sum((A_point-B_point).^2));
    Rac = sqrt(sum((A_point-C_point).^2));
    Rbc = sqrt(sum((B_point-C_point).^2));
    cosphi_ab = calculateCosPhi(a_point,b_point,K);
    cosphi_ac = calculateCosPhi(a_point,c_point,K);
    cosphi_bc = calculateCosPhi(b_point,c_point,K);
    
    K1 = Rbc^2/Rac^2;
    K2 = Rbc^2/Rab^2;
    
    G4 = (K1*K2-K1-K2)^2 ...
        -4*K1*K2*cosphi_bc^2;
    G3 = 4*(K1*K2-K1-K2)*K2*(1-K1)...
        *cosphi_ab+4*K1*cosphi_bc*((K1*K2...
        +K2-K1)*cosphi_ac ...
        +2*K2*cosphi_ab*cosphi_bc);
    G2 = (2*K2*(1-K1)*cosphi_ab)^2 ...
        +2*(K1*K2+K1-K2)*(K1*K2-K1 ...
        -K2) + 4*K1*((K1-K2)*(cosphi_bc^2) ...
        +(1-K2)*K1*(cosphi_ac^2) ...
        -2*K2*(1+K1)*cosphi_ab*cosphi_ac ...
        *cosphi_bc);
    G1 = 4*(K1*K2+K1-K2)*K2*(1-K1) ...
        *cosphi_ab+4*K1*((K1*K2-K1 ...
        +K2)*cosphi_ac*cosphi_bc ...
        +2*K1*K2*cosphi_ab*(cosphi_ac^2));
    G0 = (K1*K2+K1-K2)^2-4*(K1^2)*K2 ...
        *(cosphi_ac^2);
    
    x = roots([G4 G3 G2 G1 G0]);
    
    a = Rab./sqrt(x.^2-2*x*cosphi_ab+1);
    b = a.*x;
    m = 1-K1;
    p = 2*(K1*cosphi_ac-x.*cosphi_bc);
    q = x.^2-K1;
    m_ = 1;
    p_ = 2*(-x.*cosphi_bc);
    q_ = (x.^2*(1-K2)+2*x*K2*cosphi_ab-K2);
    
    %Rest of the code might have some error regarding how final 'y' is
    %constructed from 'y1', 'y2' and 'y3'. Also checking for imaginary parts
    %should be more strict.
    
    %Quite big numerical errors, for this reason we are suing single eps
    %instead of double eps.
    mask = (m_.*q-m.*q_).^2 < eps('single');
    
    y1 = (p_.*q-p.*q_)./(m.*q_-m_.*q);
    y1(mask) = [];
    %a1 and b1 are related to y1
    a1 = a(~mask);
    b1 = b(~mask);
    
    %Take out imaginary parts
    trash = imag(y1).^2 > eps('single');
    y1(trash) = [];
    a1(trash) = [];
    b1(trash) = [];
    y1 = real(y1);
    
    tmp = sqrt(cosphi_ac.^2+(Rac.^2-a.^2)./a.^2);
    y2 = cosphi_ac-tmp;
    y3 = cosphi_ac+tmp;
    
    %Remove those determined by mask
    y2(~mask) = [];
    y3(~mask) = [];
    a2 = a(mask);
    b2 = b(mask);
    
    %Now there might still be few values with imaginary parts
    trash = imag(y2).^2 > eps('single');
    y2(trash) = [];
    a3 = a2;
    b3 = b2;
    a2(trash) = [];
    b2(trash) = [];
    
    trash = imag(y3).^2 > eps('single');
    y3(trash) = [];
    a3(trash) = [];
    b3(trash) = [];
    
    %There also might be duplicates
    y2 = unique(real(y2));
    if numel(y2) < numel(a2)
        a2 = a2(1);
        b2 = b2(1);
    end
    y3 = unique(real(y3));
    if numel(y3) < numel(a3)
        a3 = a3(1);
        b3 = b3(1);
    end
    
    y = [y1;y2;y3];
    a = [a1;a2;a3];
    b = [b1;b2;b3];
    
    c = y.*a;
    
    finalcheck = y<0;
    a(finalcheck) = [];
    b(finalcheck) = [];
    c(finalcheck) = [];
    
    a = real(a);
    b = real(b);
    c = real(c);
    
    %a, b and c are lengths of the 'legs'
    %Now we need to find L (or as in other place in this package C (camera
    %center))
    
    for ii = 1:numel(a)
        
        %Calculate angle LAB
        %law of cosines
        %c^2 = a^2 + b^2 -2*a*b*cos(phi)
        %Now c = b, a=a and b=Rab
        coslab = (b(ii)^2-a(ii)^2-Rab^2)/(-2*a(ii)*Rab);
        
        %Vector projection: projected_point = (|a|cos(phi))*b where a is the
        %point being projected and b is unit vector
        %|a| = a, b = (B-A)/norm(B-A)
        Qab = a(ii)*coslab*(B_point-A_point)/norm(B_point-A_point) + A_point;
        
        %Define plane P1 which has normal (B_point-A_point) and which goes trough
        %Q
        %http://en.wikipedia.org/wiki/Plane_(geometry)#Definition_with_a_point_and_a_normal_vector
        n = B_point-A_point;
        P1 = makePlaneFromnX([n;1],[Qab;1]);
        
        %Second plane P2
        coslac = (c(ii)^2-a(ii)^2-Rac^2)/(-2*a(ii)*Rac);
        Qac = a(ii)*coslac*(C_point-A_point)/norm(C_point-A_point) + A_point;
        n = C_point-A_point;
        P2 = makePlaneFromnX([n;1],[Qac;1]);
        
        %Third plane P3
        P3 = makePlaneFromX([A_point;1],[B_point;1], [C_point;1]);
        
        %Calculate intersection point of all planes
        R = wnorm(makeXfromPlanes(P1,P2,P3));
        R = R(1:3);
        
        %Length RA
        Rar = norm(R-A_point);
        
        %Compute lenght RL. Angle LRA is 90 degrees. Use Pythagoras
        Rlr = sqrt(a(ii)^2 - Rar^2);
        
        %Compute vector perpendicular to P3
        n = cross((B_point-A_point),(C_point-A_point));
        %Scale
        nscale = n/norm(n)*Rlr;
        
        L = R+nscale
        if any(abs(imag(L))>0)
            continue;
        end
        
    end
end
