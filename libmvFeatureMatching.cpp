#include "mex.h"

#include "libmv/correspondence/feature_matching_FLANN.h"
#include "libmv/correspondence/feature.h"
#include "libmv/correspondence/feature_matching.h"
//#include "libmv/correspondence/feature_set.h"
#include "libmv/base/vector.h"
#include "libmv/logging/logging.h"


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

    if (mxGetClassID(prhs[0]) != mxDOUBLE_CLASS || mxGetClassID(prhs[0]) != mxDOUBLE_CLASS) {
        usage();
        mexErrMsgTxt("Input points must be double.\n");
    }

    const mwSize *dimsData1 = mxGetDimensions(prhs[0]);
    mwSize numDims1 = mxGetNumberOfDimensions(prhs[0]);

    const mwSize *dimsData2 = mxGetDimensions(prhs[1]);
    mwSize numDims2 = mxGetNumberOfDimensions(prhs[1]);

    if (numDims1 != 2 || numDims2 != 2 || dimsData1[0] != 3 || dimsData1[0] != 3) {
        usage();
        mexErrMsgTxt("Input data must be 3xn 2D matrix\n");
    }

    if (nlhs != 2) {
        usage();
        mexErrMsgTxt("Wrong number of outputs\n");
    }

    //
    // Get data
    //

    unsigned char *data1 = (unsigned char*)mxGetData(prhs[0]);
    unsigned char *data2 = (unsigned char*)mxGetData(prhs[1]);
    int mRow = dimsData1[0]; //In MATLAB indexing

    int mCol1 = dimsData1[1]; //Number of points in set 1
    int mCol2 = dimsData2[1]; //Number of points in set 2

    //
    // Create libmv data
    //

    //Points are stored in two feature sets. Feature sets
    //can be used to store points, feature descriptors etc.
    FeatureSet features1;
    FeatureSet features2;

    //Convert both homogenous point sets to FeatureSets
    for (unsigned int ii = 0; ii < mCol1; ++ii) {
        //Normalize (wnorm)
        double w = data1[ii*3+2];

        //First create sinle point (this step could be replaced by just creating .coords)
        libmv::PointFeature p1(data1[ii*3 + 0]/w,data1[ii*3 + 1]/w);

        //As FeatureSets camparisons (matching) is done using feature descriptors
        //we convert the point coordinates (x,y) to descriptor
        KeypointFeature kp1;
        kp1.descriptor = libmv::descriptor::VecfDescriptor(p1.coords);

        //Now we add this descriptor of single point to feature set
        features1.features.push_back(kp1);
    }

    //Exactly same thing for second points
    for (unsigned int ii = 0; ii < mCol2; ++ii) {
        double w = data2[ii*3+2];
        libmv::PointFeature p2(data2[ii*3 + 0]/w,data2[ii*3 + 1]/w);
        KeypointFeature kp2;
        kp2.descriptor = libmv::descriptor::VecfDescriptor(p2.coords);
        features2.features.push_back(kp2);
    }

    //Result will be in Matches
    libmv::Matches matches;

    //See documentation of FindSymmetricCandidateMatches_FLANN
    //Basically for each point (p1) in set 1, finds closest point from set 2 (p2) and checks if
    //p1 is closest point from set 1 for p2, if true, add to matches
    FindSymmetricCandidateMatches_FLANN(features1,features2,&matches);

    //matches.NumTracks() will be number of point matches after removing (part of the) outliers
    //Unfortunately, at the time of writing of this function. Original index numbers of the features can not be determined
    //(would require addition of 'tag' or 'idx' to KeypointFeature
    mwSize dims_out1[3] = {3, matches.NumTracks()};
    plhs[0] = mxCreateNumericArray(2, dims_out1, mxDOUBLE_CLASS, mxREAL);
    plhs[1] = mxCreateNumericArray(2, dims_out1, mxDOUBLE_CLASS, mxREAL);

    double *outdata1 = (double*)mxGetData(plhs[0]);
    double *outdata2 = (double*)mxGetData(plhs[1]);
    for (unsigned int ii = 0; ii < dims_out1[1]; ++ii) {
        const libmv::Feature *f1 = matches.Get(0,ii); //From img id 0
        const libmv::Feature *f2 = matches.Get(1,ii); //From img id 1

        KeypointFeature *kp1 = (KeypointFeature*)f1;
        KeypointFeature *kp2 = (KeypointFeature*)f2;

        outdata1[ii*3 + 0] = kp1->descriptor.coords(0);
        outdata1[ii*3 + 1] = kp1->descriptor.coords(1);
        outdata1[ii*3 + 2] = 1.0; //Normalized

        outdata2[ii*3 + 0] = kp2->descriptor.coords(0);
        outdata2[ii*3 + 1] = kp2->descriptor.coords(1);
        outdata2[ii*3 + 2] = 1.0; //Normalized
    }

}
