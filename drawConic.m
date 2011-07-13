function h = drawConic(C,x)
%HZ2 2.2.3, (2.1), (2.2) and (2.3) p.30
%Not very well tested
%Matti Jukola 2010
if all(size(C) == [3 3])
    %Change to vector form
    C = [C(1,1) C(1,2)*2 C(2,2) C(1,3)*2 C(2,3)*2 C(3,3)];
end

x = x(:);
c = C(1).*x.^2+C(4).*x+C(end);
a = C(3);
b = C(2).*x;
%y = roots([a.*ones(size(b)) b c]);
y = NaN(numel(x),2);
for ii = 1:numel(x)
    res = roots([a b(ii) c(ii)]);
    res(res ~= real(res)) = [];
    if numel(res) == 1
        y(ii,:) = [res NaN];
    elseif numel(res) == 2
        y(ii,:) = res(:)';
    end
end
%y = (-b+sqrt(b.^2-4.*a.*c))/(2.*a);
%y = [y;NaN;(-b-sqrt(b.^2-4.*a.*c))/(2.*a)];
%x = [x;NaN;x];

h = line(x,y,'color',[1 0 0]);

% for ii = 1:10:numel(x)
%     l = C*[x(ii) y(ii) 1]';
%     l = l./l(3);
%     h = [h;drawLine([x(ii)-1 x(ii)+1],l(1),l(2),l(3))];
% end