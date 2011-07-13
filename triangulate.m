function X = triangulate(F,x1,x2,method)
%Method 1 == Linear triangulation method (HZ p. 312)
%Method 2 == Linear + Sampson approximation (HZ p. 315)
%Method 3 == Optimal solution
%Method 4 == Optimal + Sampson
%
%Matti Jukola 2010

warning('This function needs more testing')

if nargin < 4
    method = 2;
end

%Reserve memory
X = ones(4,size(x1,2));
x1 = wnorm(x1); %To real coordinates
x2 = wnorm(x2);

if any(method == [2 4])
    %Correct point position using sampson approximation (HZ p. 315)
    %After that normal computation
    for ii = 1:size(x1,2)
        %Sampson approximation (HZ p. 315)
        xy1 = x1(:,ii);
        xy2 = x2(:,ii);
        X_ = [xy1(1:2); xy2(1:2)];
        X_ = X_ - xy2'*F*xy1 / (dot(F(1,:),xy1)^2 + dot(F(2,:),xy1)^2 + dot(F(1,:),xy2)^2 + dot(F(2,:),xy2)^2) * [dot(F(:,1),xy2)^2; dot(F(:,2),xy2)^2; dot(F(:,1),xy1)^2; dot(F(:,2),xy1)^2];
        x1(1:2,ii) = X_(1:2);
        x2(1:2,ii) = X_(3:4);
    end
end

if any(method == [1 2])
    %Linear triangulation method (HZ p. 312)
    P1 = [eye(3) zeros(3,1)];
    P2 = makePfromF(F);
    for ii = 1:size(x1,2)
        xy1 = x1(:,ii);
        xy2 = x2(:,ii);
        A = [xy1(1)*P1(3,:) - P1(1,:);...
             xy1(2)*P1(3,:) - P1(2,:);...
             xy2(1)*P2(3,:) - P2(1,:);...
             xy2(2)*P2(3,:) - P2(2,:)];
        [U S V] = svd(A);
        %X(:,ii) = V(:,end);
        X(:,ii) = V(:,end);
    end
end

if any(method == [3 4])
    %Else use...
    %Optimal triangulation algorithm
    %HZ p. 318
    warning('Optimal triangulation algorithm is not fully tested, see NOTE: in code');
    
    %Cost function HZ (12.5) p. 317
    s = @(t,f,f_,a,b,c,d)(t.^2./(1+f^2*t^2)+(c.*t+d).^2./((a.*t+b)^2+f_^2*(c.*t+d).^2));
    %Other projection matrix is already known
    P1 = [eye(3) zeros(3,1)];
    
    %For each point
    for ii = 1:size(x1,2)
        %Get points being triangulated
        xy1 = x1(1:2,ii);
        xy2 = x2(1:2,ii);
        
        %(i) Translation matrices
        T1 = eye(3); T1(1:2,end) = -xy1; %T
        T2 = eye(3); T2(1:2,end) = -xy2; %T'
        
        %(ii) Calculate new F
        F_ = inv(T1)'*F*inv(T2);
        
        %(iii) Calculate right and left epipole
        [U S V] = svd(F_);
        e = V(:,end); %Right epipole (Right null vector)
        e_ = U(:,end); %Left epipole (Left null vector)
        %Normalize (multiply by a scale) such that e(1)^2+e(2)^2 = 1
        e = e./sqrt((e(1)^2+e(2)^2));
        e_ = e_./sqrt((e_(1)^2+e_(2)^2));
        
        %(iv) Form rotation matrices (R*e = [1 0 e(3)]' and same for R_ and r_)
        R = diag([e(1) e(1) 1]); R(2,1) = -e(2); R(1,2) = e(2);
        R_ = diag([e_(1) e_(1) 1]); R_(2,1) = -e_(2); R_(1,2) = e_(2);
        
        %(v) Replace F
        F_ = R_*F*R'; %(Has same for as F in HZ (12.3))
        
        %(vi)
        f = e(3); f_ = e_(3); a = F_(2,2); b = F_(2,3); c = F_(3,2); d = F_(3,3);
        
        %(vii) And solve polynom
        
        %syms f f_ a b c d t
        %g = t*((a*t+b)^2+f_^2*(c*t+d)^2)^2 - (a*d-b*c)*(1+f^2*t^2)^2*(a*t+b)*(c*t+d)
        %subs(g,[Sf Sf_ Sa Sb Sc Sd],[f f_ a b c d])
        %collcet(g,t) ("simplified" manually or using collect(g,t))
        %or
        %collect(expand(g),t)
        %or  in every loop
        %syms Sf Sf_ Sa Sb Sc Sd St
        %g = St*((Sa*St+Sb)^2+Sf_^2*(Sc*St+Sd)^2)^2 - (Sa*Sd-Sb*Sc)*(1+Sf^2*St^2)^2*(Sa*St+Sb)*(Sc*St+Sd)
        %     poly = [-a*c*f^4*(a*d - b*c) ...
        %             (a^4 + 2*a^2*c^2*f_^2 - a^2*d^2*f^4 + b^2*c^2*f^4 + c^4*f_^4)...
        %             (4*a^3*b - 2*a^2*c*d*f^2 + 4*a^2*c*d*f_^2 + 2*a*b*c^2*f^2 + 4*a*b*c^2*f_^2 - a*b*d^2*f^4 + b^2*c*d*f^4 + 4*c^3*d*f_^4)...
        %             2*(3*a^2*b^2 - a^2*d^2*f^2 + a^2*d^2*f_^2 + 4*a*b*c*d*f_^2 + b^2*c^2*f^2 + b^2*c^2*f_^2 + 3*c^2*d^2*f_^4)...
        %             (4*a*b^3 - a^2*c*d + a*b*c^2 - 2*a*b*d^2*f^2 + 4*a*b*d^2*f_^2 + 2*b^2*c*d*f^2 + 4*b^2*c*d*f_^2 + 4*c*d^3*f_^4)...
        %             (b^4 - a^2*d^2 + b^2*c^2 + 2*b^2*d^2*f_^2 + d^4*f_^4)-a*b*d^2 ...
        %             b^2*c*d];
        %     poly = [-(a*d - b*c)*a*c*f^4
        %         (-((a*d*f^4 + b*c*f^4)*(a*d - b*c) - (a^2 + c^2*f_^2)^2))
        %         (-((b*d*f^4 + 2*a*c*f^2)*(a*d - b*c) - 2*(a^2 + c^2*f_^2)*(2*c*d*f_^2 + 2*a*b)))
        %         ((2*(a^2 + c^2*f_^2)*(b^2 + d^2*f_^2) - (2*a*d*f^2 + 2*b*c*f^2)*(a*d - b*c) + (2*c*d*f_^2 + 2*a*b)^2))
        %         (-((2*b*d*f^2 + a*c)*(a*d - b*c) - 2*(b^2 + d^2*f_^2)*(2*c*d*f_^2 + 2*a*b)))
        %         (((b^2 + d^2*f_^2)^2 - (a*d + b*c)*(a*d - b*c)))
        %         (-b*d*(a*d - b*c))];
        poly = [(a*b*c^2*f^4 - a^2*c*d*f^4)
            (a^4 + 2*a^2*c^2*f_^2 - a^2*d^2*f^4 + b^2*c^2*f^4 + c^4*f_^4)
            (4*a^3*b - 2*a^2*c*d*f^2 + 4*a^2*c*d*f_^2 + 2*a*b*c^2*f^2 + 4*a*b*c^2*f_^2 - a*b*d^2*f^4 + b^2*c*d*f^4 + 4*c^3*d*f_^4)
            (6*a^2*b^2 - 2*a^2*d^2*f^2 + 2*a^2*d^2*f_^2 + 8*a*b*c*d*f_^2 + 2*b^2*c^2*f^2 + 2*b^2*c^2*f_^2 + 6*c^2*d^2*f_^4)
            (4*a*b^3 - a^2*c*d + a*b*c^2 - 2*a*b*d^2*f^2 + 4*a*b*d^2*f_^2 + 2*b^2*c*d*f^2 + 4*b^2*c*d*f_^2 + 4*c*d^3*f_^4)
            (b^4 - a^2*d^2 + b^2*c^2 + 2*b^2*d^2*f_^2 + d^4*f_^4)
            (- a*b*d^2 + b^2*c*d)];
        t = roots(poly);
        
        %t = t(t == real(t)); %Use only real roots
        t = real(t); %Use real parts of roots
        
        %Solve roots
        for t_ii = 1:numel(t)
            t(t_ii) = fzero(@(t)polysolve(poly,t),t(t_ii));
        end
        
        %(viii) Evaluate at real root points
        s_vals = zeros(size(t));
        for t_ii = 1:numel(s_vals)
            s_vals(t_ii) = s(t(t_ii),f,f_,a,b,c,d);
        end
        %Also evaluate t = Inf
        s_inf = 1/f^2+c^2/(a^2+f_^2*c^2);
        %Select minimum
        [t_min_val t_min] = min(s_vals);
        t_min = t(t_min);
        if (t_min_val > s_inf)
            t_min_val = s_inf;
            t_min = Inf;
        end
        
        %(ix) Evaluate the two lines
        l = [t_min*f,1,-t_min]';
        l_ = F_*[0;t_min;1];
        %And find points xhat and x_hat
        xhat = [-l(1)*l(3); -l(2)*l(3); l(1)^2+l(2)^2];
        x_hat = [-l_(1)*l_(3); -l_(2)*l_(3); l_(1)^2+l_(2)^2];
        
        %(x) Transfer back to original coordinates
        xhat = wnorm(inv(T1)*R'*xhat);
        x_hat = wnorm(inv(T2)*R_'*x_hat);
        
        
        %(xi) Find X
        %Using Homgenous method (DLT)
        %We need P, it can be computed from F (TODO: check if right F is used)
        %TODO: add point normalization
        %P2 = makePfromF(F_);
        P2 = makePfromF(F);
        A = [xhat(1)*P1(3,:) - P1(1,:);...
            xhat(2)*P1(3,:) - P1(2,:);...
            x_hat(1)*P2(3,:) - P2(1,:);...
            x_hat(2)*P2(3,:) - P2(2,:)];
        [U S V] = svd(A);
        X(:,ii) = V(:,end);
    end
end
return

function out = polysolve(poly,t)
out = polyval(poly,t);
return
















































