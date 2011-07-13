function out = subpxlCross_validate(xy, H, g,minlim)
out = subpxlCross(xy, H, g);
if ~isempty(out) && ~any(isnan(out))
   p = round(out);
   if g(p(2),p(1)) < minlim
       out = [];
   end
end