function x = convertToHom(x,type)
%Converts [x;y] or [x;y;z] coordinates to homogenous [x;y;1] or [x;y;z;1]
% or convert planar [x;y] or [x;y;w] to 3D [x;y;0;1] when type = 'planar'
%
%Matti Jukola 2010

if nargin < 2
    type = '';
end

if iscell(x)
    for ii = 1:numel(x)
        x{ii} = convertToHom(x{ii});
    end
    return
end

if strcmp(type,'')
    x = [x;ones(1,size(x,2))];
elseif strcmp(type,'planar') && size(x,1) == 3
    x = [x(1:2,:);zeros(1,size(x,2));x(3,:)];
elseif strcmp(type,'planar') && size(x,1) == 2
    x = [x;zeros(1,size(x,2));ones(1,size(x,2))];
end