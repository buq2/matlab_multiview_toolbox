function [P X] = fixPXSign(P,X,x)
%Makes sure that in w*x=P*X, w>0 or in other words that points X are
%in front of camera P (camera and points X might be multiplied by -1)
%
%NOTE: Does not make any checks if solution is possible.
%
%HZ2. p.526
%vgg_signsPX_from_x.m by HZ
%
%Matti Jukola 2010

error('Not tested, probably does not work')

%If inputs are cells, fix for each camera
if iscell(P) && iscell(x)
   for ii = 1:numel(P)
      [P{ii} X] = fixCameraXSign(P{ii},X,x{ii}); 
   end
   return
end

%Check if P should be multiplied by -1 using first point in array
w = P(end,:)*X(:,1).*x(end,1);
P = sign(w)*P;

%Check if any of the Xs should be multiplied by -1
w = sign(P(end,:)*X.*x(end,:));
X = bsxfun(@times,X,sign(w));
