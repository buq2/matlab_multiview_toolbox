function w = makewfromH(H,zero_skew,square_pixels)
%Calcualtes image of absolute conic from 
%plane homographys H (at least three homographies are needed)
%
%Inputs:  H - cell array of plane homographies. Each cell is 3x3 matrix
%Outputs: w - Image of absolute conic
%
%Ma et. al - An Invitation to 3-D Vision pp. 203-204
%HZ Example 8.18 p.211
%HZ Table 8.1 p.224
%HZ Algorithm 8.2 p.225
%
%Matti Jukola 2010.11.12 / 2010.12.22

if nargin < 2
    zero_skew = false;
end
if nargin < 3
    square_pixels = false;
end

if numel(H) < 3 && ~(zeros_skew || square_pixels)
   error('At least three homographys are needed when there is no assumed about zero skew or square pixels'); 
elseif numel(H) < 2
   error('At least two homographys are needed when there we assume zero skew or square pixels'); 
end

w = makewfromConstraints([], [], H, zero_skew, square_pixels);


