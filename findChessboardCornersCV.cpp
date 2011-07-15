// Find chessboard corners:
//			int found = cvFindChessboardCorners( image, board_sz, corners,
//				&corner_count, CV_CALIB_CB_ADAPTIVE_THRESH | CV_CALIB_CB_FILTER_QUADS );

//			// Get subpixel accuracy on those corners
//			cvCvtColor( image, gray_image, CV_BGR2GRAY );
//			cvFindCornerSubPix( gray_image, corners, corner_count, cvSize( 11, 11 ), 
//				cvSize( -1, -1 ), cvTermCriteria( CV_TERMCRIT_EPS+CV_TERMCRIT_ITER, 30, 0.1 ));

#include "mex.h"
#include "opencv2/calib3d/calib3d.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/contrib/contrib.hpp"
#include "opencv2/imgproc/imgproc_c.h"

void usage()
{
    mexPrintf(
    "Finds chessboard corners using OpenCV\n"
    "Calibration board MUST have white boarders, invert colors if needed.\n"
    "\n"
    "Inputs:\n"
    "       img - (uint8) image from which the corners are searched. Only first channel will be used.\n"
    "       boardSize - (double) Size of calibration board in squares (default [15 15]).\n"
    "       automInvert - (double) If set to 1, and no points are found, colors are inverted and we try to find the points again (default 0).\n"
    "\n"
    "Outputs:\n"
    "       points - Homogenous corner coordinates.\n"
    "       success - Was the search fully succesfull.\n"
    "       realPoints - If search was successfull, contains real world coordinates of the board. Square is 1 unit x 1 unit.\n"
    "                     H = makeH(points,realPoints); wnorm(H*points)-realPoints ~= 0\n"
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
    
    if (nrhs != 1 && nrhs != 2 && nrhs != 3) {
        //Not enough inputs
        usage();
        mexErrMsgTxt("Wrong nuber of input parameters.\n");
    }

    if (nrhs >= 2 && mxGetNumberOfElements(prhs[1]) != 2) {
        usage();
        mexErrMsgTxt("'boardSize' input must be 2 vector.\n");
    }

    if (nrhs >= 3 && mxGetNumberOfElements(prhs[2]) != 1) {
        usage();
        mexErrMsgTxt("'automInvert' input must be scalar (0 or 1).\n");
    }

    if (nrhs >= 2 && mxGetClassID(prhs[1]) != mxDOUBLE_CLASS) {
        usage();
        mexErrMsgTxt("'boardSize' must be double.\n");
    }

    if (nrhs >= 3 && mxGetClassID(prhs[2]) != mxDOUBLE_CLASS) {
        usage();
        mexErrMsgTxt("'automInvert' must be double.\n");
    }

    if (mxGetClassID(prhs[0]) != mxUINT8_CLASS) {
        usage();
        mexErrMsgTxt("Input image must be uint8.\n");
    }

    const mwSize *dimsImg1 = mxGetDimensions(prhs[0]);
    mwSize numDims = mxGetNumberOfDimensions(prhs[0]);

    if (numDims < 2 || numDims > 3) {
        usage();
        mexErrMsgTxt("Input image must be either 2D matrix or RGb image (3D array with 3 layers).\n");
    }

    if (numDims == 3 && (dimsImg1[2] == 2 || dimsImg1[2] > 3)) {
        usage();
        mexErrMsgTxt("Input image must be either 2D matrix or RGb image (3D array with 3 layers).\n");
    }

    if (nlhs != 1 && nlhs != 2 && nlhs != 3) {
        usage();
        mexErrMsgTxt("Wrong number of outputs\n");
    }

    //
    // Copy image data to OpenCV structures
    //

    unsigned char *data1 = (unsigned char*)mxGetData(prhs[0]);
    int mHeight = dimsImg1[0]; //In MATLAB indexing
    int mWidth = dimsImg1[1];

    //No copying needed if only header is created
    IplImage* img1 = cvCreateImageHeader(cvSize(mHeight,mWidth),
                    IPL_DEPTH_8U, 1 ); //Use only first layer
    img1->imageData = (char*)data1; //Set data

    //Default board size is 15x15 squares
    int board_w = 15; // Board width in squares
    int board_h = 15; // Board height

    //If board size is give as input
    if (nrhs >= 2) {
        double *boardSizeData = (double*)mxGetData(prhs[1]);
        board_w = (int)boardSizeData[0];
        board_h = (int)boardSizeData[1];
    }
    int board_n = board_w * board_h; //Number of squares
    cv::Size board_sz = cv::Size( board_w, board_h );

    //Reserve space for found corners
    CvPoint2D32f* corners = new CvPoint2D32f[ board_n*10 ]; //Just in case 10 times more points
    int cornerCount = 0;
    int correct = cvFindChessboardCorners(img1, board_sz, corners, &cornerCount, CV_CALIB_CB_ADAPTIVE_THRESH);//CV_CALIB_CB_ADAPTIVE_THRESH,CV_CALIB_CB_FILTER_QUADS

    //Do we neet to invert colors?
    bool colorsInverted = false;
    if (cornerCount == 0 && nrhs >= 3 && *((double*)mxGetData(prhs[2])) == 1.0) {
        //Invert colors
        colorsInverted = true;
        img1->imageData = (char*)new unsigned char[mHeight*mWidth];
        for (int ii = 0; ii < mHeight*mWidth;++ii) {
            unsigned char tmp = 255-data1[ii];
            img1->imageData[ii] = *((char*)&tmp);
        }
        correct = cvFindChessboardCorners(img1, board_sz, corners, &cornerCount, CV_CALIB_CB_ADAPTIVE_THRESH);//CV_CALIB_CB_ADAPTIVE_THRESH,CV_CALIB_CB_FILTER_QUADS
    }

    //Find sub pixel coordinates
    cvFindCornerSubPix(img1, corners, cornerCount, cvSize(11,11), cvSize(-1,-1),cvTermCriteria( CV_TERMCRIT_ITER | CV_TERMCRIT_EPS, 20, 0.03 ));

    //Create output array
    mwSize dims_out[2] = {3,cornerCount}; //Homogenous
    mxArray *out_array = mxCreateNumericArray(2, dims_out, mxSINGLE_CLASS, mxREAL);
    plhs[0] = out_array;

    //Rearrange output
    float *outptr = (float*)mxGetData(out_array);
    for (int ii = 0; ii < cornerCount; ++ii) {
        outptr[ii*3 + 0] = corners[ii].y;
        outptr[ii*3 + 1] = corners[ii].x;
        outptr[ii*3 + 2] = 1.0f;
    }

    //Do we need to output if the search was successfull?
    if (nlhs > 1) {
        mwSize dims_out2[1] = {1};
        plhs[1] = mxCreateNumericArray(1, dims_out2, mxLOGICAL_CLASS, mxREAL);
        *((bool*)mxGetData(plhs[1])) = correct;
    }

    //Do we want real coordinates?
    if (nlhs > 2) {
        mwSize dims_out3[2] = {3,cornerCount*correct};
        plhs[2] = mxCreateNumericArray(2, dims_out3, mxSINGLE_CLASS, mxREAL);
        if (correct) {
            float *outData3 = (float*)mxGetData(plhs[2]);
            int idx = 0;
            for (int jj = 0; jj < board_h; ++jj) {
                for (int ii = 0; ii < board_w; ++ii) {
                    outData3[idx*3 + 0] = (float)ii;
                    outData3[idx*3 + 1] = (float)jj;
                    outData3[idx*3 + 2] = 1.0f;
                    idx += 1;
                }
            }
        }
    }

    //Cleanup
    delete[] corners;
    if (colorsInverted) {
        delete[] img1->imageData;
    }
}
