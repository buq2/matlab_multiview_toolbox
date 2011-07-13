function outparam = makePoptim(inputparam,optimparam)
%This function is used to optimize camera matrices, calibration matrices
%3D points etc.
%
%Inputs:
%     Struct inputparam:
%      .x      - Image points (cell array, one cell for each image)
%      .x_correspond 
%              - Correspondances between inputparam.x
%                
%      
%     Struct optimparam:
%      .method - 'bundle','calibration','position'
%                          Preset values for optimization
%  