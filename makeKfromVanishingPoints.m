function K = makeKfromVanishingPoints(v,zero_skew,square_pixels)
%Calcualtes internal camera parameters in matrix K from 
%five orthogonal vanishing points pairs [v1 v2].
%
%Inputs:  v - cell array of vanishing point pairs (each vanishing point is 3x1
%             vector, each cell consist of two vanishing points in a
%             3x2 matrix)
%Outputs: K - Internal parameters, upper triangular matrix
%
%Liebowitz & Zisserman 1998 - Combining Scene and Auto-calibration Constraints
%HZ Table 8.1 p.224
%HZ Algorithm 8.2 p.225 Computing K from scne and internal constraints
%
%Matti Jukola 2010.11.12 / 2010.12.22

warning('Not working / implemented / checked')

if numel(v) < 5-max(zero_skew,square_pixels*2)
   error('At least five vanishing points are needed or zero_skew or square pixels must be assumend') 
end

w = makewfromConstraints(v, [], [], zero_skew, square_pixels);
K = makeKfromw(w);