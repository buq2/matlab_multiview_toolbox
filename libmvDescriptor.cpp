#include "mex.h"

#include "libmv/descriptor/descriptor.h"
#include "libmv/descriptor/descriptor_factory.h"
#include "libmv/descriptor/vector_descriptor.h"
#include "libmv/image/image.h"
#include "libmv/correspondence/feature.h"
#include "libmv/base/vector.h"

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

    if (nrhs != 2) {
        //Not enough inputs
        usage();
        mexErrMsgTxt("Wrong nuber of input parameters.\n");
    }

    if (mxGetClassID(prhs[0]) != mxUINT8_CLASS) {
        usage();
        mexErrMsgTxt("Input image must be uint8.\n");
    }

    if (mxGetClassID(prhs[1]) != mxDOUBLE_CLASS) {
        usage();
        mexErrMsgTxt("Features must be double.\n");
    }

    const mwSize *dimsImg1 = mxGetDimensions(prhs[0]);
    mwSize numDims = mxGetNumberOfDimensions(prhs[0]);

    const mwSize *dimsFeatures = mxGetDimensions(prhs[1]);
    mwSize numDimsFeatures = mxGetNumberOfDimensions(prhs[1]);

    if (dimsFeatures[1] == 0) {
        usage();
        mexErrMsgTxt("There must ne at least one point");
    }

    if (numDims < 2 || numDims > 3 || numDimsFeatures != 2) {
        usage();
        mexErrMsgTxt("Input image must be either 2D matrix or RGb image (3D array with 3 layers). Features must be 2D matrix\n");
    }

    if (dimsFeatures[0] < 2 || dimsFeatures[0] > 4) {
        usage();
        mexErrMsgTxt("Features matrix must have at least two rows (x and y position of feature), but can also have row 3 (rotation, radians) and row 4 (scale)");
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
    int channels = 1; //Normally 2D image
    if (numDims > 2) {
        channels = dimsImg1[2];
    }

    double *dataFeatures = (double*)mxGetData(prhs[1]);
    int mRow = dimsFeatures[0];
    int mCol = dimsFeatures[1];

    //
    // Create libmv image
    //

    //Construct libmv image
    libmv::Image img1(new libmv::ByteImage(height,width,channels));

    //Copy MATLAB image
    memcpy(img1.AsArray3Du()->Data(), data1, width*height);

    //Create array for features
    libmv::vector<libmv::Feature *> features;

    for (unsigned int ii = 0; ii < mCol; ++ii) {
        double x = dataFeatures[ii*mRow + 0];
        double y = dataFeatures[ii*mRow + 1];
        features.push_back(new libmv::PointFeature(x,y));
        if (mRow > 2) {
            static_cast<libmv::PointFeature*>(features[ii])->orientation = dataFeatures[ii*mRow + 2];
            if (mRow > 3) {
                static_cast<libmv::PointFeature*>(features[ii])->scale = dataFeatures[ii*mRow + 3];
            } else {
                static_cast<libmv::PointFeature*>(features[ii])->scale = 1.0;
            }
        } else {
            static_cast<libmv::PointFeature*>(features[ii])->scale = 1.0;
            static_cast<libmv::PointFeature*>(features[ii])->orientation = 0;
        }
    }

    //
    // Call libmv function
    //

    //Construct detector object
    libmv::descriptor::Describer *desc = libmv::descriptor::describerFactory(libmv::descriptor::DAISY_DESCRIBER); //

    if (desc == NULL) {
        mexErrMsgTxt("descriptor factory returned NULL: Unknown descriptor type");
    }

    //Array for output descriptors
    libmv::vector<libmv::descriptor::Descriptor *> descriptors;

    //Pointer for additional data
    libmv::detector::DetectorData *detData = NULL;

    //Call detector function
    desc->Describe(features,img1,detData, &descriptors);

    //
    // Free libmv feature data
    //
    for (int ii = 0; ii < features.size(); ++ii) {
        delete features[ii];
        features[ii] = NULL;
    }

    //
    //Convert output to matrix
    //

    libmv::descriptor::VecfDescriptor *d = NULL;
    for (unsigned int ii = 0; ii < descriptors.size() && d == NULL; ++ii) {
        d = dynamic_cast<libmv::descriptor::VecfDescriptor*>(descriptors[0]);
    }

    if (d == NULL) {
        for (int ii = 0; ii < descriptors.size(); ++ii) {
            delete descriptors[ii];
        }
        mexErrMsgTxt("No descriptors could be created, or descriptors are not VecfDescriptors");
    }

    //Reserve space for output
    //Output will be SIZE_OF_DESCRIPTOR_VECTOR x NUMBER_OF_DESCRIPTORS
    mwSize dims_out1[2] = {d->coords.size(),mCol};
    plhs[0] = mxCreateNumericArray(2, dims_out1, mxDOUBLE_CLASS, mxREAL);

    double *dataOut1 = (double*)mxGetData(plhs[0]);
    for (unsigned int ii = 0; ii < features.size(); ++ii) {
        d = dynamic_cast<libmv::descriptor::VecfDescriptor*>(descriptors[ii]);

        if (d == NULL) {
            //No descriptor, use NaNs
            for (unsigned int jj = 0; jj < dims_out1[0]; ++jj) {
                dataOut1[ii*dims_out1[0] + jj] = mxGetNaN();
            }

            continue;
        }

        //Good descriptor, copy
        for (unsigned int jj = 0; jj < dims_out1[0]; ++jj) {
            dataOut1[ii*dims_out1[0] + jj] = d->coords[jj];
        }
        delete d;
        descriptors[0] = NULL;
    }
}
