#include "mex.h"
//#include <cv.h>
//#include <highgui.h>
//#include "cvaux.h" //CV_DISPARITY_BIRCHFIELD
//#include "calib3d.hpp"
#include "opencv2/calib3d/calib3d.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/contrib/contrib.hpp"

void mexFunction(int		nlhs, 		 /*(NumLeftHandSide) Number of arguments in left side of '=' (number of output arguments)*/
                 mxArray	*plhs[],	 /*(PointerLeftHandSide) Pointers to output data*/
                 int		nrhs, 		 /*(NumRightHandSide) Number of input arguments*/
                 const mxArray	*prhs[]) /*(PointerRightHandSide) Pointers to input data*/
{
    if (nrhs > 0) { /*If some input*/
        //See https://code.ros.org/trac/opencv/browser/trunk/opencv/samples/cpp/stereo_match.cpp
        //http://opencv.willowgarage.com/documentation/cpp/calib3d_camera_calibration_and_3d_reconstruction.html
        
        //Fetch images
        cv::Mat img1 = cv::imread("left.jpg", 0); //Try 1 if fails
	    cv::Mat img2 = cv::imread("right.jpg", 0);
        cv::Mat disp;
        
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
	    sgbm.numberOfDisparities = ((img_size.width/8) + 15) & -16;
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
        
        if (nlhs == 1) {
            //Create MATLAB array and copy data to this memory location
            mwSize dims_out[2] = {width,height};
            int type = disp.type();
            mxArray *out_array = NULL;
            out_array = mxCreateNumericArray(2, dims_out, mxINT16_CLASS, mxREAL);
            memcpy(mxGetData(out_array), data, width*height*2);
            plhs[0] = out_array;
        } else {
           mexPrintf("No outputs\n");
        }
    } else {
        mexPrintf("No inputs\n");
    }
}
