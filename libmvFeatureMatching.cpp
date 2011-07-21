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

/*
    if (dimsData1[1] != dimsData2[1]) {
        usage();
        mexErrMsgTxt("Input matrices must be same size\n");
    }
*/
    if (nlhs != 1) {
        usage();
        mexErrMsgTxt("Wrong number of outputs\n");
    }

    //
    // Get data
    //

    unsigned char *data1 = (unsigned char*)mxGetData(prhs[0]);
    unsigned char *data2 = (unsigned char*)mxGetData(prhs[1]);
    int mRow = dimsData1[0]; //In MATLAB indexing
    int mCol = dimsData1[1];

    //
    // Create libmv data
    //

/*
    libmv::FeatureSet features1;
    libmv::FeatureSet features2;
    libmv::FeatureSet::Iterator<libmv::PointFeature> it1 = features1.Insert<libmv::PointFeature>(libmv::PointFeature(data1[0],data1[1]));
    libmv::FeatureSet::Iterator<libmv::PointFeature> it2 = features1.Insert<libmv::PointFeature>(libmv::PointFeature(data2[0],data2[1]));
    for (unsigned int ii = 1; ii < mCol; ++ii) {
        it1 = features1.Insert<libmv::PointFeature>(libmv::PointFeature(data1[ii*3 + 0],data1[ii*3 + 1]));
        it2 = features1.Insert<libmv::PointFeature>(libmv::PointFeature(data2[ii*3 + 0],data2[ii*3 + 1]));
    }
*/
    FeatureSet features1;
    FeatureSet features2;


    for (unsigned int ii = 0; ii < mCol; ++ii) {
        libmv::PointFeature p1(data1[ii*3 + 0],data1[ii*3 + 1]);
        KeypointFeature kp1;
        kp1.descriptor = libmv::descriptor::VecfDescriptor(p1.coords);
        features1.features.push_back(kp1);

        libmv::PointFeature p2(data2[ii*3 + 0],data2[ii*3 + 1]);
        KeypointFeature kp2;
        kp2.descriptor = libmv::descriptor::VecfDescriptor(p2.coords);
        features2.features.push_back(kp2);
    }
    
    libmv::Matches matches;
    FindSymmetricCandidateMatches_FLANN(features1,features2,&matches);

    mexPrintf("%d - %d\n",matches.NumTracks(),matches.NumImages());
}
