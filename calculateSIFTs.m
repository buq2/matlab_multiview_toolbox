function [infos features matches scores imgIdx] = calculateSIFTs(imgs,vl_shift_varargin,vl_ubcmatch_varargin)
%Calculates point correspondaces between all input images using SIFT (vlFeat)
%
%Inputs:
%      imgs                 - Cell array of images from which all SIFT and mathces
%                             will be calculated.
%                             Or cell array of filenames.
%      vl_shift_varargin    - (opt) Function arguments for function 'vl_sift'
%      vl_ubcmatch_varargin - (opt) Function arguments for function 'vl_ubcmatch'
%Outputs:
%      infos     - First outputs of 'vl_sift'
%      features  - Second outputs of 'vl_sift'
%      matches   - First outputs of 'vl_ubcmatch'. Only calculated if
%                    nargout > 2
%      scores    - second outputs of 'vl_ubcmatch'
%      imgIdx    - Index number of images used for matches and scores,
%                    2xnumel(matches) matrix.
%
%Matti Jukola 2011.02.23, 2011.07.14

if nargin < 2
    vl_shift_varargin = {};
end
if nargin < 3
    vl_ubcmatch_varargin = {};
end

infos = cell(numel(imgs),1);
features = cell(numel(imgs),1);
matches = cell(ceil((numel(imgs)-1)^2/2+numel(imgs)/2),1);
scores = cell(ceil((numel(imgs)-1)^2/2+numel(imgs)/2),1);
imgIdx = zeros(2,ceil((numel(imgs)-1)^2/2+numel(imgs)/2));

h = waitbar(0,'Calculating features');
for ii = 1:numel(imgs)
    if ischar(imgs{ii}) && exist(imgs{ii},'file')
        img = imread(imgs{ii});
        [infos{ii} features{ii}] = vl_sift(single(rgb2gray(img)),vl_shift_varargin{:});
        clear img
    else
        [infos{ii} features{ii}] = vl_sift(single(rgb2gray(imgs{ii})),vl_shift_varargin{:});
    end
    waitbar(ii/numel(imgs),h)
end

waitbar(0,h,'Calculating matches')
if nargout > 2
    num = 1;
    for ii = 1:numel(imgs)-1
        for jj = ii+1:numel(imgs)
            [matches{num} scores{num}] = vl_ubcmatch(features{ii},features{jj},vl_ubcmatch_varargin{:});
            imgIdx(:,num) = [ii,jj]';
            num = num+1;
            waitbar(num/numel(scores),h);
        end
    end
    imgIdx(:,num:end) = [];
    scores(num:end) = [];
    matches(num:end) = [];
end
delete(h)

