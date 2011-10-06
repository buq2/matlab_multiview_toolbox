#include "mex.h"
#include "opencv2/calib3d/calib3d.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/contrib/contrib.hpp"

void usage()
{
    mexPrintf(
    "Calculates dispariy using OpenCVs block matching algorithm\n"
    );
}

void mexFunction(int        nlhs,        /*(NumLeftHandSide) Number of arguments in left side of '=' (number of output arguments)*/
                 mxArray    *plhs[],     /*(PointerLeftHandSide) Pointers to output data*/
                 int        nrhs,        /*(NumRightHandSide) Number of input arguments*/
                 const mxArray  *prhs[]) /*(PointerRightHandSide) Pointers to input data*/
{
    //
    // Some MATLAB error checking
    //
    
    if (nrhs < 2) {
        //Not enough inputs
        usage();
        mexErrMsgTxt("Not enough input parameters.\n");
    }

    if (mxGetClassID(prhs[0]) != mxUINT8_CLASS || mxGetClassID(prhs[1]) != mxUINT8_CLASS) {
        usage();
        mexErrMsgTxt("Both input images must be uint8.\n");
    }

    const mwSize *dimsImg1 = mxGetDimensions(prhs[0]);
    const mwSize *dimsImg2 = mxGetDimensions(prhs[1]);
    mwSize numDims = mxGetNumberOfDimensions(prhs[0]);
    if (mxGetNumberOfDimensions(prhs[0]) != numDims) {
        usage();
        mexErrMsgTxt("Both input images must be same size.\n");
    }

    if (numDims < 2 || numDims > 3) {
        usage();
        mexErrMsgTxt("Input images must be either 2D matrices or RGb images (3D array with 3 layers).\n");
    }

    for (unsigned int ii = 0; ii < numDims; ++ii) {
        if (dimsImg1[ii] != dimsImg2[ii]) {
            usage();
            mexErrMsgTxt("Both input images must be same size.\n");
        }
        if (ii == 2 && (dimsImg1[ii] == 2 || dimsImg1[ii] > 3)) {
            usage();
            mexErrMsgTxt("Input images must be wither 2D matrices or RGb images (3D array with 3 layers).\n");
        }
    }

    if (nlhs != 1) {
        usage();
        mexPrintf("No outputs\n");
    }

    //
    // Copy image data to OpenCV structures
    //
    

    unsigned char *data1 = (unsigned char*)mxGetData(prhs[0]);
    unsigned char *data2 = (unsigned char*)mxGetData(prhs[1]);

    int channels = 0;
    if (numDims == 3) {
        channels = dimsImg1[2];
    } else {
        channels = 1;
    }

    int mHeight = dimsImg1[0]; //In MATLAB indecing
    int mWidth = dimsImg2[1];

    cv::Mat img1;
    cv::Mat img2;
    //if (channels == 1) {
    //NOTE: Always uses 1 channel
        img1 = cv::Mat(mWidth,mHeight,CV_8UC1,data1);
        img2 = cv::Mat(mWidth,mHeight,CV_8UC1,data2);
    //} else { //3 channels
    //    img1 = cv::Mat(mWidth,mHeight,CV_8UC3,data1);
    //    img2 = cv::Mat(mWidth,mHeight,CV_8UC3,data2);
    //}

    //Or fetch images from files
    //cv::Mat img1 = cv::imread("left.jpg", 0); //Try 1 if fails
    //cv::Mat img2 = cv::imread("right.jpg", 0);

    //Output
    cv::Mat disp;
    
    //See https://code.ros.org/trac/opencv/browser/trunk/opencv/samples/cpp/stereo_match.cpp
    //http://opencv.willowgarage.com/documentation/cpp/calib3d_camera_calibration_and_3d_reconstruction.html
    //http://opencv.willowgarage.com/documentation/cpp/camera_calibration_and_3d_reconstruction.html#stereosgbm
        
    //Basic info about the imagess
    cv::Size img_size = img1.size();        
    int cn = img1.channels();

    //Create stereo block matching object
    cv::StereoSGBM sgbm;
        
    //And fill the parameters
    sgbm.preFilterCap = 63;
    sgbm.SADWindowSize = 13;
    sgbm.P1 = 8*cn*sgbm.SADWindowSize*sgbm.SADWindowSize;
    sgbm.P2 = 32*cn*sgbm.SADWindowSize*sgbm.SADWindowSize;
    sgbm.minDisparity = -10;
    sgbm.numberOfDisparities = 400; //((img_size.width/8) + 15) & -16;
    sgbm.uniquenessRatio = 10;
    sgbm.speckleWindowSize = 100;
    sgbm.speckleRange = 32;
    sgbm.disp12MaxDiff = 1;
    sgbm.fullDP = 0;
        
    //Actual block matching
    sgbm(img1, img2, disp);
        
    //Get output size (same as input)
    cv::Size outsize = disp.size();
    int width = outsize.width;
    int height = outsize.height;
        
    //And pointer to result
    uchar *data = disp.data;
        
    
    //Create MATLAB array and copy data to this memory location
    mwSize dims_out[2] = {width,height};
    int type = disp.type();
    mxArray *out_array = NULL;
    out_array = mxCreateNumericArray(2, dims_out, mxINT16_CLASS, mxREAL);
    memcpy(mxGetData(out_array), data, width*height*2);
    plhs[0] = out_array;

}
