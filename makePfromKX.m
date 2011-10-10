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
    
    A_point = X(:,1);
    B_point = X(:,2);
    C_point = X(:,3);
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
end
