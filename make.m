clear functions

%Compile C function 
%TODO: cross platform (or even distro) support

%mex CC=g++ CXX=g++ LD=g++ -cxx CVmatchRectifiedSimple.c -I/usr/include/opencv2 -lopencv_core -lopencv_calib3d
%mex CC=g++ CXX=g++ LD=g++ -cxx CVfindChessboardCorners.cpp -I/usr/include/opencv2 -lopencv_core -lopencv_calib3d -lopencv_imgproc


%
%% libmv stuff
%

%mex CC=g++ CXX=g++ LD=g++ -cxx libmvDetector.cpp -I/home/buq2/src/libmv/src -I/home/buq2/src/libmv/src/third_party/eigen -L/home/buq2/src/libmv/lib -ldetector
%mex CC=g++ CXX=g++ LD=g++ -cxx libmvFeatureMatchingFLANN.cpp -I/home/buq2/src/libmv/src -I/home/buq2/src/libmv/src/third_party/glog/src -I/home/buq2/src/libmv/src/third_party/eigen -L/home/buq2/src/libmv/lib -lcorrespondence -lflann
%mex CC=g++ CXX=g++ LD=g++ -cxx libmvDescriptor.cpp -I/home/buq2/src/libmv/src -I/home/buq2/src/libmv/src/third_party/eigen -L/home/buq2/src/libmv/lib -ldescriptor -lcorrespondence

mex CC=g++ CXX=g++ LD=g++ -cxx libmvSimplePipeline.cpp -I/home/buq2/src/libmv/src -I/home/buq2/src/libmv/src/third_party/glog/src -I/home/buq2/src/libmv/src/third_party/eigen -L/home/buq2/src/libmv/lib -lcorrespondence -lflann

%% Kinect stuff

mex kinectGrab.cpp -I/usr/include/libfreenect -lfreenect -lboost_thread