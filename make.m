%Compile C function 
%TODO: cross platform (or even distro) support

mex CC=g++ CXX=g++ LD=g++ -cxx matchRectifiedSimpleCV.c -I/usr/include/opencv2 -lopencv_core -lopencv_calib3d
mex CC=g++ CXX=g++ LD=g++ -cxx findChessboardCornersCV.cpp -I/usr/include/opencv2 -lopencv_core -lopencv_calib3d -lopencv_imgproc