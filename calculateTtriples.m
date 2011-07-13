function matches_img1_img2_img3 = calculateTtriples(matches_img1_img2, matches_img1_img3, matches_img2_img3)
%Calculates trifocal tensors point triplets from point pair lists between
%three images.
%
%Inputs:
%     matches_img1_img2 - 2xn1 matrix of point identifiers between images 1
%                           and 2. For example [5 8; 2 9; ...]' meaning
%                           point 5 from image 1 and point 8 from image 2
%                           are pairs, point 2 and point 9 are pairs...
%     matches_img1_img3 - 2xn2 Same as above but for images 1 and 3
%     matches_img2_img3 - 2xn3 Same as above but for images 2 and 3
%
%Outputs:
%     matches_img1_img2_img3 - 3xn matrix of point identifiers between
%                                all three images.
%
%Matti Jukola 2011.05.28

%Renaiming variables
matches_ii_jj = matches_img1_img2;
matches_ii_kk = matches_img1_img3;
matches_jj_kk = matches_img2_img3;

%Between matches ii->jj and ii->kk
[tmp ii_jj ii_kk] = intersect(matches_ii_jj(1,:),matches_ii_kk(1,:));
matches_ii_jj = matches_ii_jj(:,ii_jj);
matches_ii_kk = matches_ii_kk(:,ii_kk);

%Between matches jj->kk and jj->ii
[tmp jj_kk jj_ii] = intersect(matches_jj_kk(1,:),matches_ii_jj(2,:));
matches_jj_kk = matches_jj_kk(:,jj_kk);
matches_ii_jj = matches_ii_jj(:,jj_ii);

%Between matches kk->jj and kk->ii
[tmp kk_jj kk_ii] = intersect(matches_jj_kk(2,:),matches_ii_kk(2,:));
matches_jj_kk = matches_jj_kk(:,kk_jj);
matches_ii_kk = matches_ii_kk(:,kk_ii);

tst = [numel(matches_ii_jj(1,:)) numel(matches_ii_kk(1,:)) numel(matches_jj_kk(1,:))];

while true
    [tmp ii_jj ii_kk] = intersect(matches_ii_jj(1,:),matches_ii_kk(1,:));
    matches_ii_jj = matches_ii_jj(:,ii_jj);
    matches_ii_kk = matches_ii_kk(:,ii_kk);
    
    %Between matches jj->kk and jj->ii
    [tmp jj_kk jj_ii] = intersect(matches_jj_kk(1,:),matches_ii_jj(2,:));
    matches_jj_kk = matches_jj_kk(:,jj_kk);
    matches_ii_jj = matches_ii_jj(:,jj_ii);
    
    %Between matches kk->jj and kk->ii
    [tmp kk_jj kk_ii] = intersect(matches_jj_kk(2,:),matches_ii_kk(2,:));
    matches_jj_kk = matches_jj_kk(:,kk_jj);
    matches_ii_kk = matches_ii_kk(:,kk_ii);
    
    tst2 = [numel(matches_ii_jj(1,:)) numel(matches_ii_kk(1,:)) numel(matches_jj_kk(1,:))];
    if all(tst2 == tst)
        break
    end
    tst = tst2;
end

%Sort according to first image
[tmp idx] = sort(matches_ii_jj(1,:));
matches_ii_jj = matches_ii_jj(:,idx);
[tmp idx] = sort(matches_ii_kk(1,:));
matches_ii_kk = matches_ii_kk(:,idx);
%matches_jj_kk can not be used any more
clear matches_jj_kk

matches_img1_img2_img3 = [matches_ii_jj(1,:);matches_ii_jj(2,:);matches_ii_kk(2,:)];



