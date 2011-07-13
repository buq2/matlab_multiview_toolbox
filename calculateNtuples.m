function [finalMatches imgs] = calculateNtuples(imgIdxAll,matchesAll,imgTuples)
%Finds point tuples (pairs, triples, quadruples, ...) from matched point
%pairs.
%
%Inputs:
%      imgIdxAll  - 2xn matrix of image indeces (identifiers). Tells which 
%                     match 'matchesAll{ii}' belongs to which two images
%                     imgIdxAll(1,ii) and imgIdxAll(2,ii). For example
%                     [1 2;1 3;1 4;2 3;2 4;3 4]' would indentify that we
%                     have four images (1,2,3,4) and 6 matched pairs.
%      matchesAll - 2xn of matches (point indeces) between image pairs. 
%                     Tells which points (point identifiers/indeces) match
%                     between two images.
%      imgTuples  - Which image pairs to use. 2xn1 where n1 < n. If only
%                     part of the imgIdxAll columns should be used. List
%                     them here. If not given all pairs in imgIdxAll will
%                     be used.
%
%Outputs:
%      finalMatches - m1xm2 where m1 is number of distinct images and m2 is
%                       number of matching point tuples. Similar to matchesAll, 
%                       but for all selected images.
%      imgs         - m2x1 vector of image indeces/identifiers corresponding 
%                       to rows in finalMatches.
%                     
%
%Matti Jukola 2011.05.28

if nargin < 3
    imgTuples = imgIdxAll;
end

imgs = sort(unique(imgTuples(:)));
matches = cell(size(imgTuples,2),1);
for ii = 1:numel(matches)
    idx = find(imgIdxAll(1,:) == imgTuples(1,ii) & imgIdxAll(2,:) == imgTuples(2,ii));
    matches{ii} = matchesAll{idx};
end

tst = [];
while true
    for ii_img = 1:numel(imgs)
        setidxs = [];
        whichones = [];
        sets = {};
        num = 1;
        for ii_matches = 1:numel(matches)
            if any(imgTuples(:,ii_matches) == ii_img)
                isfirst = imgTuples(1,ii_matches) == ii_img;
                whichones(num) = isfirst;
                setidxs(num) = ii_matches;
                
                if isfirst
                    sets{num} = matches{ii_matches}(1,:);
                else
                    %Take second col which corresponds to ii_img
                    sets{num} = matches{ii_matches}(2,:);
                end
                
                num = num+1;
            end
        end
        
        idx = multiintersect(sets);
        
        for ii_set = 1:numel(idx)
            m = matches{setidxs(ii_set)};
            matches{setidxs(ii_set)} = m(:,idx{ii_set});
        end
        
    end
    
    tst2 = zeros(size(matches));
    for ii = 1:numel(tst2)
        tst2 = numel(matches{ii});
    end
    if isempty(tst) || ~all(tst == tst2)
        tst = tst2;
    else
        break;
    end
end

finalMatches = zeros(numel(imgs),size(matches{1},2));

%First image must be delt separately
idx = find(imgTuples(1,:) == imgs(1),1,'first');
if isempty(idx)
    idx = find(imgTuples(2,:) == imgs(1));
    tmp = sort(matches{idx}(2,:));
else
    tmp = sort(matches{idx}(1,:));
end
finalMatches(1,:) = tmp;

%For other images
for ii = 2:numel(imgs)
    idx = find(imgTuples(1,:) == imgs(ii) & imgTuples(2,:) == imgs(1),1,'first');
    isfirst = true;
    if isempty(idx)
        isfirst = false;
        idx = find(imgTuples(2,:) == imgs(ii) & imgTuples(1,:) == imgs(1),1,'first');
    end
    
    if isfirst
        [tmp sidx] = sort(matches{idx}(2,:));
        finalMatches(ii,:) = matches{idx}(1,sidx);
        
    else
        [tmp sidx] = sort(matches{idx}(1,:));
        finalMatches(ii,:) = matches{idx}(2,sidx);
    end
end

return

function idx = multiintersect(sets)
idx = cell(numel(sets),1);
valid = sets{1};
for ii = 2:numel(sets)
    valid = intersect(valid,sets{ii});
end
for ii = 1:numel(sets)
    [tmp idx{ii}] = intersect(sets{ii},valid);
end