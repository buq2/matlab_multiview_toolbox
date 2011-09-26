function K = makeKfromw(w,method)
%Calculates cameras internal parameters from absolute conic w (omega)
%or from image of the absolute conic (DIAC) w* (omega*)
%
%Matti Jukola 2010.11.13

if nargin < 2
    error('Method must be specified! (method=1 -> w=absolute conic, method=2 -> w=image of absolute conic')
end

if method == 1
    %inv(K).'inv(K) = w
    %(e.g w is absolute conic)
    %Directly using Cholesky factorization
    try
        K = inv(chol(w));
    catch
        %Sometimes w is not positive definite, in these cases multiplying w
        %with -1 might help
        K =  inv(chol(-w));
    end
    K = K./K(end);
elseif method == 2
    %K*K' = w
    %(e.g w is image of absolute conic (w*)
    %
    %From 
    %http://homepages.inf.ed.ac.uk/rbf/CVonline/LOCAL_COPIES/FUSIELLO3/node4.html#SECTION00043000000000000000
    %This seems to be The Cholesky–Banachiewicz and Cholesky–Crout algorithm
    %see: http://en.wikipedia.org/wiki/Cholesky_decomposition#The_Cholesky.E2.80.93Banachiewicz_and_Cholesky.E2.80.93Crout_algorithms
    
    %Assumes that w(3,3) = 1!
    w = w./w(end); %Normalization must be done!
    
    k1 = w(1);
    k2 = w(1,2);
    k3 = w(1,3);
    k4 = w(2,2);
    k5 = w(2,3);
    
    K = [sqrt(k1-k3^2-(k2-k3*k5)^2/(k4-k5^2)) (k2-k3*k5)/sqrt(k4-k5^2) k3;
         0                                   sqrt(k4-k5^2)            k5;
         0                                   0                        1];
elseif method == 3
    %K*K' = w
    w = inv(w);
    K = makeKfromw(w,1);
elseif method == 4
    %inv(K*K') = w
    w = inv(w);
    K = makeKfromw(w,2);
else
    error('Unknown method')
end