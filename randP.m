function P = randP()
%Generate random camera matrix which has realistic features, such
%as focal length and principal point.

%Pixel sizes in micrometers
%6.0 -> Some Aptina sensors (MT9V024IA7XTR for example)
%5.5 -> Nikon D300
%4.3 -> Canon 550D
%2.2 -> Many Aptina sensors
%1.4 -> Many Aptina Sensors
pixel_sizes = [6.0 5.5 2.2 1.4];

%Effective focal lengths (in mm)
focal_lengths = [200 105 70 50 25 6];

%Sensor sizes in pixel
%Nikon D300 = 4,288 × 2,848
%MT9V024MT9V024 = 752H x 480V
%MT9T111D00STC = 2048x1536
%MT9P031 = 2,592H x 1,944V
%MT9H004 = 4928H x 3280V
%Canon 550D = 5184 x 3456
sensor_sizes = [4288 752 2048 2592 4928 5184
                2848 480 1536 1944 3280 3456];
            
%Maximum error on principal point location compared to sensor center
err_princp = 0.02; 

%Maximum skewness multiplier
err_skew = 0.01;

%Maximum focal length error
err_focal = 0.03;

pixsize = pixel_sizes(randi(numel(pixel_sizes)));
focal = focal_lengths(randi(numel(focal_lengths)));
sensor = sensor_sizes(:,randi(size(sensor_sizes,2)));

focal_in_pix = focal*1000/pixsize;

r = rand(3,3)*2-1;
K = [focal_in_pix 0 sensor(1)/2;
     0 focal_in_pix sensor(2)/2;
     0 0 1];
 
K(1,1) = K(1,1)+K(1,1)*r(1,1)*err_focal;
K(2,2) = K(2,2)+K(2,2)*r(2,2)*err_focal;
K(1,2) = K(1,1)*r(1,2)*err_skew;
K(1,3) = K(1,3)+K(1,3)*err_princp;
K(2,3) = K(2,3)+K(2,3)*err_princp;

R = eye(3);
C = zeros(3,1);
%R = rodrigues(rand(3,1)*pi*2);
%C = [0 0 1]'*1000;

P = K*[R -R*C(1:3)];