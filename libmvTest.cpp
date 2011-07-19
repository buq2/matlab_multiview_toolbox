#include "mex.h"

#include "libmv/simple_pipeline/detect.h"
#include "libmv/simple_pipeline/pipeline.h"

#include <cstring>

void usage()
{
    mexPrintf(
    "libmv test"
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
    
    if (nrhs != 1) {
        //Not enough inputs
        usage();
        mexErrMsgTxt("Wrong nuber of input parameters.\n");
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

    if (nlhs != 1) {
        usage();
        mexErrMsgTxt("Wrong number of outputs\n");
    }

    //
    // Get image data
    //

    unsigned char *data1 = (unsigned char*)mxGetData(prhs[0]);
    int mHeight = dimsImg1[0]; //In MATLAB indexing
    int mWidth = dimsImg1[1];
    int height = mWidth;
    int width = mHeight;

    //
    // Call libmv function
    //

    std::vector<libmv::Corner> corners = libmv::Detect(data1, width,
                                                     height, width);

    //Reserve space for output
    mwSize dims_out1[2] = {3,corners.size()}; //Homogenous
    plhs[0] = mxCreateNumericArray(2, dims_out1, mxDOUBLE_CLASS, mxREAL);

    unsigned int idx = 0;
    double *dataOut1 = (double*)mxGetData(plhs[0]);
    for (unsigned int ii = 0; ii < corners.size(); ++ii) {
        dataOut1[idx*3 + 0] = (double)corners.at(ii).x;
        dataOut1[idx*3 + 1] = (double)corners.at(ii).y;
        dataOut1[idx*3 + 2] = 1.0f;
        idx += 1;
    }   
}
