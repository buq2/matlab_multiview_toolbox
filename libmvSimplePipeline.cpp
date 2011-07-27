#include "mex.h"

#include "libmv/detector/detector.h"
#include "libmv/detector/detector_factory.h"
#include "libmv/image/image.h"
#include "libmv/correspondence/feature.h"
#include "libmv/base/vector.h"

#include <cstring>
#include <vector>

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

    if (nrhs >= 1) {
        //Not enough inputs
        usage();
        mexErrMsgTxt("Wrong nuber of input parameters.\n");
    }

    const int numImgs = nrhs;

    for (int ii = 0; ii < numImgs; ++ii) {
      if (mxGetClassID(prhs[ii]) != mxSINGLE_CLASS) {
        usage();
        mexErrMsgTxt("Input images must be float.\n");
      }
    }

    const mwSize *dimsImg1 = mxGetDimensions(prhs[0]);
    mwSize numDims = mxGetNumberOfDimensions(prhs[0]);

    if (numDims < 2) {
      usage();
      mexErrMsgTxt("Input images must same 2D.\n");
    }

    for (int ii = 1; ii < numImgs; ++ii) {
      if (mxGetNumberOfDimensions(prhs[ii]) != numDims) {
        usage();
        mexErrMsgTxt("Input images must same size.\n");
      }

      const mwSize *dimsImgjj = mxGetDimensions(prhs[ii]);
      for (int jj = 0; jj < numDims; ++jj) {
        if (dimsImg1[jj] != dimsImgjj[jj]) {
          usage();
          mexErrMsgTxt("Input images must same size.\n");
        }
      }
    }

    if (nlhs != 1) {
        usage();
        mexErrMsgTxt("Wrong number of outputs\n");
    }

    //
    // Get image data
    //

    float **dataImg = (float**)mxMalloc(sizeof(float*)*numImgs);
    for (int ii = 0; ii < numImgs; ++ii) {
      dataImg[ii] = (float*)mxGetData(prhs[ii]);
    }

    int mHeight = dimsImg1[0]; //In MATLAB indexing
    int mWidth = dimsImg1[1];
    int height = mWidth;
    int width = mHeight;
    int channels = 1; //Normally 2D image
    if (numDims > 2) {
        channels = dimsImg1[2];
    }

    //
    // Create libmv images
    //

    std::vector<libmv::FloatImage> images;
    for (int ii = 0; ii < numImgs; ++ii) {
      images.push_back(libmv::FloatImage(height,width));
      memcpy(images.front().Data(), dataImg[ii], width*height);
    }

    //
    // Create other libmv objects
    //

//TODO

    //
    // Call libmv function
    //

    //Construct detector object
    libmv::detector::Detector *det = libmv::detector::detectorFactory(libmv::detector::STAR_DETECTOR); //SURF_DETECTOR, FAST_LIMITED_DETECTOR, STAR_DETECTOR

    if (det == NULL) {
        mexErrMsgTxt("detector factory returned NULL: Unknown detector type");
    }

    //Create array for features
    libmv::vector<libmv::Feature *> features;

    //Pointer for additional data
    libmv::detector::DetectorData *detData = NULL;

    //Call detector function
    det->Detect(img1,&features,&detData);

    //
    //Convert output to point feature
    //
    libmv::vector<libmv::PointFeature *> pointFeatures;
    for (int ii = 0; ii < features.size(); ++ii) {
        libmv::PointFeature *feat = static_cast<libmv::PointFeature*>(features[ii]);
        pointFeatures.push_back(feat);
        features[ii] = NULL;
    }

    //
    // Copy features to MATLAB
    //
    //Reserve space for output
    mwSize dims_out1[2] = {3,pointFeatures.size()}; //Homogenous
    plhs[0] = mxCreateNumericArray(2, dims_out1, mxDOUBLE_CLASS, mxREAL);

    double *dataOut1 = (double*)mxGetData(plhs[0]);
    for (unsigned int ii = 0; ii < pointFeatures.size(); ++ii) {
        dataOut1[ii*3 + 0] = (double)pointFeatures[ii]->y(); //MATLAB coordinates
        dataOut1[ii*3 + 1] = (double)pointFeatures[ii]->x();
        dataOut1[ii*3 + 2] = 1.0f;
    }

    //
    // Free libmv data
    //
    for (int ii = 0; ii < pointFeatures.size(); ++ii) {
        delete pointFeatures[ii];
        pointFeatures[ii] = NULL;
    }
    delete detData;

    cleanup:
    mxFree(dataImg); //Only direct pointers to matlab data
}
