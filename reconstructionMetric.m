function [H omega] = reconstructionMetric(method)
%Output: 
%      H      - 4x4 transformation matrix which transforms from affine
%               reconstruction to metric recontrusction
%      omega  - Absolute conic
%Menetelmät:
%1) Tunnettu kalibrointi K. p- 273
%2) Katoamispisteet. p. 273
%3) Suora rekonstruktio tunnetuista pisteistä p. 275