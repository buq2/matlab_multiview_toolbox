function [xy rel] = makeGrid2(CF,xy,rel,angs,dists,relshifts,hmasksize,prevpoint)
disp(clock)
plot(xy(1),xy(2),'r.')
drawnow
if nargin < 8
    prevpoint = [NaN NaN];
end
%Tallennetaan alkuperäinen piste
velocity = prevpoint-xy;
orgdist = sqrt(sum(velocity.^2));
organgle = atan2(velocity(2),velocity(1));
if orgdist==0
   xy = [];
   return
end
%Haetaan tarkempi piste
xy = round(xy);
xy = refine(CF,xy,hmasksize);
if isempty(xy)
    %Poistutaan jos mentiin yli kuva-alueen
    return
end
velocity = prevpoint-xy;
newdist = sqrt(sum(velocity.^2));
newangle = atan2(velocity(2),velocity(1));

distmult = newdist./orgdist;

anglefix = newangle-organgle;

p = xy(1,:);
r = rel(1,:);
if ~any(isnan(prevpoint))
    angs = angs+anglefix;
    dists = dists.*distmult;
end
for ii = 1:numel(angs)
    a = angs(ii);
    d = dists(ii);
    nextpos = p+[cos(a) sin(a)].*d;
    nextrelpos = r+relshifts(ii,:);
    
    
    go_angs = angs; 
    go_dists = dists; 
    go_relshifts = relshifts; 
    
    remo = ii+mod(ii,2)-mod(ii+1,2);
    if remo < numel(angs)
        go_angs(remo) = [];
        go_dists(remo) = [];
        go_relshifts(remo,:) = [];
    end
    
    [xynew relnew] = makeGrid2(CF,nextpos,nextrelpos,go_angs,go_dists,go_relshifts,hmasksize,p);
    xy = [xy;...
         xynew];
    rel = [rel;...
         relnew];
end
return

function xy = refine(CF,xy,hmasksize)
    imgs = size(CF);
    firstrun = true;
    xi = 0;
    yi = 0;
    while(firstrun || xi ~= 0 && yi ~= 0)
        %Ensin tarkistetään että oma paikka on "kartalla"
        if xy(1)-hmasksize(2) < 1 ||  xy(1)+hmasksize(2) > imgs(2) ...
            || xy(2)-hmasksize(1) < 1 ||  xy(2)+hmasksize(1) > imgs(1)
          xy = [];
          return
        end

        minI = CF(xy(2)-hmasksize(1):xy(2)+hmasksize(1),xy(1)-hmasksize(2):xy(1)+hmasksize(2));
        %figure(2)
        %imagesc(minI);
        %pause
        [yi xi] = find(minI == max(minI(:)));
        xi = xi-hmasksize(2)-1;
        yi = yi-hmasksize(1)-1;
        firstrun = false;
        xy = xy+[xi yi];
    end
return