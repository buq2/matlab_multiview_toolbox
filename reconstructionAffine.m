function [H pi_inf] = reconstructionAffine(method)
%Output: 
%      H      - 4x4 transformation matrix which transforms from projective
%               reconstruction to affine recontrusction
%      pi_inf - Plane at infinity
%Menetelmät:
%1) Yhdensuuntaiset viivat (3 paria / 3 leikkauspistettä inf. planella) p. 269
%2) Viivojen pituuksien suhde p. 270