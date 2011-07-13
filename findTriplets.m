function [x1s x2s x3s tripletidxs] = findTriplets(imgIdx, infos, matchIdx)
%Finds triplets from point correspondances found using SIFT
%See 'calculateSIFTs' and 'makeFfromSIFTs' for more information.
%
%Inputs:
%      imgIdx    - Index numbers of images used for matches and scores,
%                    2xnumel(matches) matrix.
%                    (from calculateSIFTs)
%      infos     - First outputs of 'vl_sift' (cell array)
%                    (from calculateSIFTs)
%      matchIdx  - Indeces of points (matches(1:2,:)) used for calculating
%                    Fs{ii} 
%                    (from makeFfromSIFTSs)
%Outputs:
%
%Matti Jukola 2011.02.24

minImgIdx = min(imgIdx(:));
maxImgIdx = max(imgIdx(:));

x1s = {};
x2s = {};
x3s = {};
tripletidxs = zeros(3,(maxImgIdx-minImgIdx-1)^2/3);

num = 1;
for ii = 1:maxImgIdx-2
    for jj = ii+1:maxImgIdx-1
        %Search correct img_pairs for first two image
        for kk = 1:numel(imgIdx)
            %Correct match for first two images
            if all(imgIdx(:,kk) == [ii jj]')
                pairid = kk; %Can be used to wetch matches from first two images
                break;
            end
        end
        
        %Matches of first two images
        midx = matchIdx{pairid};
        
        %for kk = pairid+1:size(imgIdx,2)
        for kk = 1:size(imgIdx,2)
            %Find new pair where first image is 'ii' but second image is
            %not 'jj'            
            if imgIdx(1,kk) == ii && imgIdx(2,kk) ~= jj
                %Matches between images 'jj' and 'kk'
                %We take indeces of image 'jj'
                midx_tst = matchIdx{kk}(1,:);
                
                %Check which of these indeces match with 'ii','jj' -pair
                %Indeces should be in sorted order for merging with the
                %indeces from 'jj' (not quite sure if they have to be
                %sorted at
                %this stage. But just in case until whole function works
                %correctly).
                idx3 = ismember(midx_tst,midx(1,:));
                idx3 = find(idx3);
                
                
                x1idx = matchIdx{kk}(1,idx3);
                [x1idx sortidx] = sort(x1idx);
                idx3 = idx3(sortidx);
                x3idx = matchIdx{kk}(2,idx3);
                
                %Indeces must be selected in sorted order
                idx2 = ismember(midx(1,:),midx_tst(1,idx3));
                idx2 = find(idx2);
                x1idx_tst = matchIdx{pairid}(1,idx2);
                [x1idx_tst sortidx] = sort(x1idx_tst);
                idx2 = idx2(sortidx);
                x2idx = matchIdx{pairid}(2,idx2);
                
                if numel(x2idx) ~= numel(x1idx)
                    disp('keke')
                end
                
                for kk2 = kk+1:size(imgIdx,2)
                    if imgIdx(1,kk2) == jj && imgIdx(2,kk2) == imgIdx(2,kk)
                        %Matches between images 'ii' and 'kk2'
                        %We take indeces of image 'jj'
                        midx_tst = matchIdx{kk2}(1,:);
                        
                        %Check which of these indeces match with 'ii','jj' -pair
                        idx3 = ismember(midx_tst,midx(2,:));
                        
                        x3idx = [x3idx matchIdx{kk2}(2,idx3)];
                        x2idx = [x2idx matchIdx{kk2}(1,idx3)];
                        
                        idx1 = ismember(midx(2,:),midx_tst(1,idx3));
                        idx1 = find(idx1);
                        x2idx_tst = matchIdx{pairid}(2,idx1);
                        [x2idx_tst sortidx] = sort(x2idx_tst);
                        idx1 = idx1(sortidx);
                        x1idx = [x1idx matchIdx{pairid}(1,idx1)];
                        
                        if numel(x1idx) ~= numel(x2idx)
                            disp('keke')
                        end
                        
                        %x1idx = unique(x1idx);
                        %x2idx = unique(x2idx);
                        %x3idx = unique(x3idx);
%                         [tmp idx1] = unique(x1idx);
%                         [tmp idx2] = unique(x2idx);
%                         [tmp idx3] = unique(x3idx);
%                         idx = unique([idx1 idx2 idx3]);
%                         x1idxt = x1idx(idx);
%                         x2idxt = x2idx(idx);
%                         x3idxt = x3idx(idx);
                        
                        x3 = infos{imgIdx(2,kk)}(1:2,x3idx);
                        x3 = convertToHom(x3);
                        
                        x2 = infos{imgIdx(1,kk2)}(1:2,x2idx);
                        x2 = convertToHom(x2);
                        
                        x1 = infos{imgIdx(1,kk)}(1:2,x1idx);
                        x1 = convertToHom(x1);
                        
                        x1s{num} = x1;
                        x2s{num} = x2;
                        x3s{num} = x3;
                        
                        tripletidxs(:,num) = [imgIdx(1,pairid) imgIdx(1,kk2) imgIdx(2,kk)]';
                        
                        num = num+1;
                        break
                    end
                end                
            end
        end
    end
end

x1s(num:end) = [];
x2s(num:end) = [];
x3s(num:end) = [];
tripletidxs(:,num:end) = [];