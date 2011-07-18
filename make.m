clear functions

%Compile C function 
%TODO: cross platform (or even distro) support

%mex CC=g++ CXX=g++ LD=g++ -cxx matchRectifiedSimpleCV.c -I/usr/include/opencv2 -lopencv_core -lopencv_calib3d
%mex CC=g++ CXX=g++ LD=g++ -cxx findChessboardCornersCV.cpp -I/usr/include/opencv2 -lopencv_core -lopencv_calib3d -lopencv_imgproc

%libmv stuff


%Make sure libmv is in path
%mex CC=g++ CXX=g++ LD=g++ -cxx libmvTest.cpp -I/home/buq2/src/libmv-matthias/libmv/src -I/home/buq2/src/libmv-matthias/libmv/src/third_party/eigen -L/home/buq2/src/libmv-matthias/libmv/lib -ltracking -lsimple_pipeline
mex CC=g++ CXX=g++ LD=g++ -cxx libmvTest.cpp -I/home/buq2/src/libmv-matthias/libmv/src -I/home/buq2/src/libmv-matthias/libmv/src/third_party/eigen -L/home/buq2/src/libmv-matthias/libmv/lib -lsimple_pipeline
%libmv_path = '/home/buq2/src/libmv-matthias/libmv/lib';
%ldpath = getenv('LD_LIBRARY_PATH');
%if isempty(strfind(ldpath,'libmv/lib'))
%    %Add to path
%    disp('Adding libmv to LD_LIBRARY_PATH')
%    setenv('LD_LIBRARY_PATH',[getenv('LD_LIBRARY_PATH') ':' libmv_path])
%end