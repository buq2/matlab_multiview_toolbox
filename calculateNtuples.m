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
%Matti Jukola 2011.05.28 2011.07.14

%If tuple pairs are not give, use them all
if nargin < 3
    imgTuples = imgIdxAll;
end

%Find image indeces we should be used
%For example if we started with imgTuples = [1 2; 2 3; 2 5]'
%imgs would be [1 2 3 5]'
imgs = sort(unique(imgTuples(:)));

%Reserve space for matches
%Collect only those matches (related to imgTuples) we are using
matches = cell(size(imgTuples,2),1);
for ii = 1:numel(matches)
    %Find index of 'matches' cell which relates to imgTuple with index 'ii'
    %It should not matter which way the tuple is given: [1 2]' and [2 1]' 
    %should produce same result
    idx = find(imgIdxAll(1,:) == imgTuples(1,ii) & imgIdxAll(2,:) == imgTuples(2,ii));
    if isempty(idx)
        idx = find(imgIdxAll(1,:) == imgTuples(2,ii) & imgIdxAll(2,:) == imgTuples(1,ii));
        imgTuples(:,ii) = flipud(imgTuples(:,ii)); %Reverse order (smaller on top)
    end
    matches{ii} = matchesAll{idx};
end

tst = [];
%Loop till we drop
while true
    %For each distinct image
    for ii_img = 1:numel(imgs)
        img = imgs(ii_img);
        
        %Unfortunately we don't know the size of the matches (this could be
        %precalculated, but would make the code more tedious).
        setidxs = [];
        whichones = []; 
        sets = {};
        num = 1;
        
        %For each match combination
        %TODO: replace with vectorized code
        for ii_matches = 1:numel(matches)
            %If match with index 'ii_matches' is related to image 'ii_img'
            if any(imgTuples(:,ii_matches) == img)
                %Was image 'ii_img' in the first row of imgTuples and matches{ii_matches}?
                isfirst = imgTuples(1,ii_matches) == img;
                
                %Remember how this image is related to this subset (subset of 'sets')
                whichones(num) = isfirst; %#ok (grows in a loop)
                setidxs(num) = ii_matches; %#ok (grows in a loop)
                
                %Collect this 'match' (subset of 'matches') to smaller set named 'sets'
                %'sets' will contain all the 'matches' which are related to
                %image with index 'ii_img'
                
                %If 'ii_img' was on on the first row
                if isfirst
                    sets{num} = matches{ii_matches}(1,:);
                else
                    %Take second col which corresponds to 'ii_img'
                    sets{num} = matches{ii_matches}(2,:);
                end
                
                %We found one more set which is related to image 'ii_img'
                num = num+1;
            end
        end
        
        %If only one set, no need to remove outliers as there is none
        if numel(sets) == 1
            continue
        end      
        
        %Find multi intersect between the sets 
        %As 'sets' contains only point indeces related to 'ii_img' we try to
        %find only those point indeces which appear in all match tuples
        %(subset of 'matches').
        %Result ('idx') will be cell array size of 'sets' containing 
        %indeces related to 'sets' so that if we index each cell ii of 'sets'
        %with idx{ii} we will get same point indeces
        idx = multiintersect(sets);
        
        %For each selected subset of 'matches', remove outlier points
        for ii_set = 1:numel(idx)
            m = matches{setidxs(ii_set)};
            matches{setidxs(ii_set)} = m(:,idx{ii_set});
        end
    end
    
    %We have gone trough each image
    
    %Calculate how many point pairs are left in matches
    tst2 = zeros(size(matches));
    for ii = 1:numel(tst2)
        tst2(ii) = numel(matches{ii});
    end
    
    %Do we have same number of points as previously (if we do, then we did
    %not remove any points -> only point correspondances are left -> we can
    %stop).
    if isempty(tst) || ~all(tst == tst2)
        tst = tst2;
    else
        break;
    end
end

%Now we know the total number of correspondance points, and even the
%correspondace points. Only problem will be how to get all the points from
%different cells in same order.

finalMatches = zeros(numel(imgs),size(matches{1},2));

%We solve this by sorting all the points according to smallest index image
%(imgs(1)), after this we will recursively/iteratively sort all the other image point
%indeces.

%After points have been sorted, how must the order be changed so that the
%points are in correct order
orderFromSorted = cell(1,numel(imgs));

%For first image this order is always 1:size(finalMatches,2)
orderFromSorted{1} = 1:size(finalMatches,2);

%We also know the order in which first images points should be (sorted)
idx = find(imgTuples(1,:) == imgs(1),1,'first');
if isempty(idx)
    idx = find(imgTuples(2,:) == imgs(1));
    finalMatches(1,:) = sort(matches{idx}(2,:));
else
    finalMatches(1,:) = sort(matches{idx}(1,:));
end

%Now we can do quite slow loop in which go trough all images, try to find
%pair for this image which is already sorted, and then sort this images
%points according to it.
found = false(size(orderFromSorted));
oldFound = found;
while true
    %For all images
    for ii_img = 1:numel(imgs)
        %Have we already sorted this image indeces?
        if ~isempty(orderFromSorted{ii_img})
            %Already sorted, next image
            continue
        end
        
        %Get the actual image "identifier"
        img = imgs(ii_img);
        
        %Find point tuples which are related to this image
        tupleidx = imgTuples(1,:) == img | imgTuples(2,:) == img;
        tupleidx = find(tupleidx); %Indeces, not logical any more
        
        %For each of these tuples
        for ii_tuple = tupleidx
            %Is this first or second image
            isFirst = imgTuples(1,ii_tuple) == img;
            
            if isFirst
                img2 = imgTuples(2,ii_tuple);
            else
                img2 = imgTuples(1,ii_tuple);
            end
            
            %Is the second image already in sorted order?
            if ~isempty(orderFromSorted{imgs==img2})
                %Yes it is sorted, now we can sort this image
                if isFirst
                    [tmp otherSortedOrder] = sort(matches{ii_tuple}(2,:));
                else
                    [tmp otherSortedOrder] = sort(matches{ii_tuple}(1,:));
                end
                
                %This is the indexing how we should save this images
                %indeces from this match to finalMatches. But this is not 
                %order how to save sorted indeces.
                howToOrder = otherSortedOrder(orderFromSorted{imgs==img2});
                
                if isFirst
                    match = matches{ii_tuple}(1,:);
                    finalMatches(ii_img,:) = match(howToOrder);
                else
                    match = matches{ii_tuple}(2,:);
                    finalMatches(ii_img,:) = match(howToOrder);
                end
                
                [tmp sortedMatch] = sort(match);
                
                %Now we can calculate how sorted order should be changed so
                %that we accomplish the correct order
                thisOrderFromSorted = zeros(size(sortedMatch));
                thisOrderFromSorted(sortedMatch) = howToOrder;
                
                %Save how change order from sorted.
                orderFromSorted{ii_img} = thisOrderFromSorted;
            end
        end
    end   
    
    for ii = 1:numel(orderFromSorted)
        found(ii) = ~isempty(orderFromSorted{ii});
    end
    
    %Are we stuck?    
    if all(found==oldFound)
        error('No way to order the indeces. Change imgTuples?')
    end
    
    if sum(found) == numel(found)
        %All found
        break
    else
        oldFound = found;
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