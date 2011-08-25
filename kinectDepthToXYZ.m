function [X Y Z invalidDepth] = kinectDepthToXYZ(depth, K_depth, radial_depth, tangential_depth, depth_base_and_offset)
%Converts depth map to XYZ coordinates when calibration is known.

if nargin < 2
    %Use precomputed from TUT sensor
    K_depth = reshape([5.8680160380538359e+02, 0., 3.0852862818515104e+02, 0., 5.8765587998528531e+02, 2.3483705083973686e+02, 0., 0., 1.],[3 3])';
    distortion_depth = [-1.3543579586687302e-01, 6.4945176104838909e-01, -1.9691140916813683e-03, -2.6837429982855118e-03, -1.0090299717545017e+00];
    radial_depth = distortion_depth([1 2 5]);
    tangential_depth = distortion_depth([3 4]);
    depth_base_and_offset = [7.84662664e-02, 1.07061072e+03];
end

%Magic number 2047 marks invalid pixels
invalidDepth = depth == 2^11-1;

%Distort both depth and invalid map
depth_ud = undistortImage(depth,K_depth,radial_depth,tangential_depth);
invalid_ud = undistortImage(single(invalidDepth),K_depth,radial_depth,tangential_depth);

%Mark all pixels that were near invalid pixels as invalids
invalidDepth = invalid_ud ~= 0;

%Calculate real depth. See: http://www.ros.org/wiki/kinect_calibration/technical
realDepth = depth_base_and_offset(1)*mean([K_depth(1,1),K_depth(2,2)]) ./ (1/8 * (depth_base_and_offset(2) - depth_ud));

%See: http://nicolas.burrus.name/index.php/Research/KinectCalibration
w = 640;
h = 480;
[pixX pixY] = meshgrid(0:w-1,0:h-1);
X = bsxfun(@times,(pixX - K_depth(1,3))/K_depth(1,1), realDepth);
Y = bsxfun(@times,(pixY - K_depth(2,3))/K_depth(2,2), realDepth);
Z = realDepth;