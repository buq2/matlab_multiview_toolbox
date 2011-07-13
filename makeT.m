function T = makeT(x1,x2,x3,method)
%Compute trifocal tensor from three point correspondances across 3 images
%There should be at least 7 point correspondances
%
%Method = 1 
%   HZ2 Algorithm 16.1 p.394 (Normalized linear algorithm)
if nargin < 4
    method = 1;
end

%Set x{1,2,3}^3 to 1
x1 = wnorm(x1);
x2 = wnorm(x2);
x3 = wnorm(x3);

if size(x1,2) == 6
    %HZ Algorithm 20.1 p.511 for six point trifocal tensor calculation
    error('Not implemented')
end

%HZ Algorithm 16.1 p.394 (Normalized linear algorithm)
%i) and ii) Normalize points
[x1 H1] = normalizePoints(x1);
[x2 H2] = normalizePoints(x2);
[x3 H3] = normalizePoints(x3);

%iii) Compute trifocal tensor
nump = size(x1,2);
A = zeros(nump*4,27); %4 equations from each point correspondance
%We are using equation (16.2) from HZ p. 393
%j=m=3
row_end = 0;
idx_T = [0 9 18];
for ii = 1:2 %i
    for ll = 1:2 %l
        row_start = row_end+1;
        row_end = row_start+nump-1;
        
        %Last element of T_k (x^k*x'^i*x''^l*T_k^33)
        %Sign of result can be changed by switching ll and ii
        A(row_start:row_end,9+idx_T) = bsxfun(@times,x1',x2(ii,:)'.*x3(ll,:)');
        %(-x^k*x''^l*T_k^i3)
        A(row_start:row_end,ii+6+idx_T) = bsxfun(@times,x1',-x3(ll,:)');
        %(-x^k*x'^iT_k^3l
        A(row_start:row_end,(ll-1)*3+3+idx_T) = bsxfun(@times,x1',-x2(ii,:)');
        %(x^k*T_k^il)
        A(row_start:row_end,(ll-1)*3+ii+idx_T) = x1';
    end
end
[U,S,V] = svd(A,false);
T = reshape(V(:,end),3,3,3);

if method == 2
    %HZ Algorithm 16.2 p.394 (Algorithm minimizing algebraic error)
    %Steps i) and ii) has been already completed
    %Compute epipoles e' (e2) and e'' (e3)
    [e2 e3] = makeEpipolesFromT(T);
    E = zeros(27,18);
end

%Denormalization
%Precompute 
H2 = inv(H2);
H3 = inv(H3)';
Tprecomp = T;
for ii = 1:3
   Tprecomp(:,:,ii) = H2*Tprecomp(:,:,ii)*H3;
end
for ii = 1:3
    T(:,:,ii) = H1(1,ii)*Tprecomp(:,:,1) + H1(2,ii)*Tprecomp(:,:,2) + H1(3,ii)*Tprecomp(:,:,3);
end