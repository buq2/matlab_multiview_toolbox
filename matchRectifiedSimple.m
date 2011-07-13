function [sifts testvals origins] = matchRectifiedSimple(img1,img2,winsize,jumpsize,maxsift)
%Uses block matching on rectified images to find pixel neighborhood sifts
%
%Matti Jukola 2011.02.20

if nargin < 3 
    winsize = [8 8];
end
if nargin < 4
    jumpsize = [4 4];
end
if nargin < 5
    maxsift = Inf;
end

if numel(winsize) == 1;winsize = [winsize winsize];end
if numel(jumpsize) == 1;jumpsize = [jumpsize jumpsize];end

s = size(img1);
if numel(s) == 2
    s = [s 1];
end

%Preprocessing for normalized cross correlation
str = 'valid';
m1 = winsize(2); 
n1 = winsize(1);
N = m1*n1*size(img1,3);
% Convolution kernels for calculating sums
win1 = ones(m1,1);
win2 = ones(1,n1); 

%Permutes images for faster row access
img1 = single(permute(img1,[2 1 3])); 
img2 = single(permute(img2,[2 1 3]));

sy = sum(convn(convn(img1,win1,str),win2,str),3);
syy = sum(convn(convn(img1.^2,win1,str),win2,str),3);
sx = sum(convn(convn(img2,win1,str),win2,str),3);
sxx = sum(convn(convn(img2.^2,win1,str),win2,str),3);

outsize = round([s(1)./(jumpsize(1)+1)+1 s(2)./(jumpsize(2)+1)+1]);
sifts = zeros(outsize);
origins = zeros([outsize 2]);
testvals = zeros(outsize);

halfwindow = winsize/2;

out_row = 1;
out_col = 1;

for row_ii = 1:jumpsize(1):s(1)-winsize(1)
    out_col = 1;
    for col_ii = 1:jumpsize(2):s(2)-winsize(2)
        simg1 = img1(col_ii:col_ii+winsize(2)-1,row_ii:row_ii+winsize(1)-1,:);
        simg1(:) = simg1(end:-1:1);%Rotate all dimensions for convn
          
        minpos = max(col_ii-maxsift,1);
        maxpos = min(col_ii+maxsift,s(2)-winsize(2)+1);
                
        sy_ = sy(col_ii,row_ii);
        syy_ = syy(col_ii,row_ii);
               
        %Following line is same as 'convn'.
        sxy = convnc(img2(minpos:maxpos+winsize(2)-1,row_ii:row_ii+winsize(1)-1,:),simg1,'valid');
        
        sx_ = sx(minpos:maxpos,row_ii);
        sxx_ = sxx(minpos:maxpos,row_ii);
        
        cxy = (sxy-(sx_./N).*sy_)./sqrt((sxx_-sx_.^2./N).*(syy_-sy_.^2./N));
        
        [bestval bestsift] = max(cxy);
        
        sifts(out_row,out_col) = minpos - col_ii + bestsift - 1;
        origins(out_row,out_col,:) = [row_ii,col_ii]+halfwindow;
        testvals(out_row,out_col) = bestval;
        
        out_col = out_col + 1;
    end
    out_row = out_row + 1;
end

