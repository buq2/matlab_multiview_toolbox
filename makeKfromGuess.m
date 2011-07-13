function K = makeKfromGuess(size_of_image, focal_length_in_mm)
%Try to make guess of calibration matrix K from size of the image.
%If focal length in millimeters is give, this will also be taken into
%account, otherwise focal length 50 will be used as a guess. This function
%is more of an example how to make good guess of calibration matrix than
%the abosulte truth which should always be used.
%
%Inputs:
%      size_of_image      - 2- or 3-vector [y x] in pixels
%      focal_length_in_mm - Focal lenght in millimeters (optional, default
%                             50)
%Outputs:
%      K                   - Guess of calibration matrix
%
%Matti Jukola 2011.05.29

if nargin < 1
    %Very rough guess using shape of Nikon D300 image sensor resized to
    %1.5mp
    size_of_image = round([2848 4288]/sqrt(12212224)*sqrt(1.5e6));
end

if nargin < 2
    focal_length_in_mm = 50;
end

%Assume sensor width of 15mm ("Four thirds" has width 17.3mm, "1/2.5""
%5.76mm, "APS-C" 22.2mm, "Full frame" 36mm and many mobile cameras even
%smaller).
sensor_width = 15;

%Sensor width in pixels
sensor_width_px = size_of_image(2);

%Assuming square pixels, length of the pixel in millimeters
sensor_res = sensor_width./sensor_width_px;

%Guess of focal length in pixels
%In MASKS p. 395 f is given as size_of_image(2)*k where k is "usually
%between 0.5 and 2".
f = 1./sensor_res*focal_length_in_mm;

K = [f 0 size_of_image(2)/2;
     0 f size_of_image(1)/2;
     0 0 1];