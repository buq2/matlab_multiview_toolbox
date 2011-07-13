function P2 = makePfromF(F,method)
%Second canonical camera from fundamental matrix F
%First camera P (P1*X = x) is [eye(3) zeros(3,1)] (P = [I|0])
%e' is left null-vector of F 
%
%Matti Jukola 2010, 2011.01.30
%
%HZ2 9.2.4 p.245 and 9.14 p.256
if nargin < 2
    method = 1;
end

e_ = makeEpipoles(F'); %Left epipole (left null vector)

%These normalizations are probably not needed, but in my opinion they
%give in pratical applications little bit nicer P:s (values closer to
%1). Removing these might affect some algorithms.
e_ = wnorm(e_);
F = F./F(end);

if method == 1
    %HZ2 p.246 (with length 1 baseline)
    %Pollefeys - Visual 3D Modeling from Images p. 42
    
    %Basic formula, produces always the same P2
    
    %Without length 1 normalization
    P2 = [makeSkew(e_)*F e_]; %P'
elseif method == 2
    %HZ2 Result 9.15 p.256
    %Pollefeys - Visual 3D Modeling from Images p. 42 (with randomization)
    
    %Non singular M, but P2 has random elements
    mult = rand;
    while mult == 0
        mult = rand;
    end
    
    %If everything is randomized
    P2 = [makeSkew(e_)*F+e_*rand(1,3) e_*mult]; %P'
end