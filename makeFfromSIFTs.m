function [Fs x1s x2s matchIdx] = makeFfromSIFTs(infos, matches, img_pairs, maxerr)
%Calculates fundamental matrices from SIFT-results.
%See calculateSIFTs for more information about inputs
%
%Inputs:
%      infos     - First outputs of 'vl_sift' (cell array)
%      matches   - First outputs of 'vl_ubcmatch' (cell array)
%      imgIdx    - Index numbers of images used for matches and scores,
%                    2xnumel(matches) matrix.
%      maxerr    - Maximum reprojection errror for each step
%                   [err_ransac err_after_ransac err_final];
%Outpus:
%      Fs        - Fundamental matrices corresponding to 'infos' and
%                    'matches'
%      x1s/x2s   - Points used for calculating fundamental matrix Fs{ii}
%      matchIdx  - Indeces of points (matches(1:2,:)) used for calculating
%                    Fs{ii}
%
%Matti Jukola 2011.02.24

if nargin < 4
    maxerr = [2 1 1];
end

Fs = cell(size(matches));
x1s = cell(size(matches));
x2s = cell(size(matches));
matchIdx = cell(size(matches));

h = waitbar(0,'Calculating fundamental matrices');
for ii = 1:numel(Fs)
    imgnum1 = img_pairs(1,ii);
    imgnum2 = img_pairs(2,ii);
    x1 = convertToHom(infos{imgnum1}(1:2,matches{ii}(1,:)));
    x2 = convertToHom(infos{imgnum2}(1:2,matches{ii}(2,:)));
    
    %Calculate fundamental matrix using RANSAC
    F = makeFRansac(x1,x2,maxerr(1),'reprojection');
    
    %Calculate reprojection error (How many pixels off each point is from
    %  epipolar line)
    d = calculateFdist(F,x1,x2);
    
    %Points with large error should be consider false matches
    didx1 = find(d<maxerr(2));
    x1_ = x1(:,didx1);
    x2_ = x2(:,didx1);
    
    %Using "correct" points, calculate new fundamental matrix
    F = makeF(x1_,x2_);
    
    %Calculate pixel error
    d2 = calculateFdist(F,x1,x2);
    
    %Now choose final point correspondaces
    didx2 = find(d2<maxerr(3));
    x1s{ii} = x1(:,didx2);
    x2s{ii} = x2(:,didx2);
    
    %And calculate final F and 
    Fs{ii} = makeF(x1_,x2_);
    matchIdx{ii} = matches{ii}(1:2,didx2);
    
    waitbar(ii/numel(Fs),h);
end

delete(h)