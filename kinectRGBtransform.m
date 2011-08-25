function [rgb invalidColor] = kinectRGBtransform(rgb,X,Y,Z,K_rgb, radial_rgb, tangential_rgb, T)
%Map RGB image to known XYZ coordinates when calibration is known.
if nargin < 5
    %Use precomputed from TUT sensor
    K_rgb = reshape([5.2264754445438268e+02, 0., 3.1898233378335067e+02, 0.,5.2281923529567291e+02, 2.4004311532231731e+02, 0., 0., 1.],[3 3])';
    distortion_rgb = [2.6500366608125003e-01, -9.3179278499705598e-01,-9.5362199394449711e-04, 1.0121010318791741e-03,1.1227544625552663e+00];
    radial_rgb = distortion_rgb([1 2 5]);
    tangential_rgb = distortion_rgb([3 4]);
    R = reshape([9.9994855279432382e-01, -9.2814542247140770e-03, 4.0922331326492334e-03, 9.2385810989796761e-03, 9.9990350964648000e-01, 1.0374006744223806e-02, -4.1881241403509571e-03, -1.0335666602893243e-02,9.9993781487253441e-01],[3 3])';
    T = [2.4158781090188233e-02, -2.5259041391054410e-03,2.5188423349242228e-03]';
end

rgb_ud = undistortImage(rgb,K_rgb,radial_rgb,tangential_rgb);

%See: http://nicolas.burrus.name/index.php/Research/KinectCalibration
%Should we use calibration R somewhere in here?
colorPosX = ((X-T(1)) * K_rgb(1,1) ./ (Z+T(3))) + K_rgb(1,3);
colorPosY = ((Y-T(2)) * K_rgb(2,2) ./ (Z+T(3))) + K_rgb(2,3);

w = 640;
h = 480;

invalidColor = colorPosX<0 | colorPosY<0 | colorPosX>w-1 | colorPosY>h-1;
colorPosX(invalidColor) = 0;
colorPosY(invalidColor) = 0;

[pixX pixY] = meshgrid(0:w-1,0:h-1);
R = uint8(interp2(pixX,pixY, single(rgb_ud(:,:,1)), colorPosX(:,:), colorPosY(:,:)));
G = uint8(interp2(pixX,pixY, single(rgb_ud(:,:,2)), colorPosX(:,:), colorPosY(:,:)));
B = uint8(interp2(pixX,pixY, single(rgb_ud(:,:,3)), colorPosX(:,:), colorPosY(:,:)));

rgb = cat(3,R,G,B);