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
              "Libmv matching test. Can be used to find closest points, or most similar feature vectors. Use code below to test (2D points)\n\n"
    "\tp1 = rand(2,100);\n"
    "\tp2 = rand(2,100);\n"
    "\tidx = libmvFeatureMatchingFLANN(single(p1),single(p2));\n"
    "\tplot(p1(1,:),p1(2,:),'b.');\n"
    "\thold on\n"
    "\tplot(p2(1,:),p2(2,:),'r.');\n"
    "\tplot([p1(1,idx(1,:));p2(1,idx(2,:))],[p1(2,idx(1,:));p2(2,idx(2,:))]);\n"
    "\thold off\n"
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

    if (mxGetClassID(prhs[0]) != mxSINGLE_CLASS || mxGetClassID(prhs[0]) != mxSINGLE_CLASS) {
        usage();
        mexErrMsgTxt("Input points must be single.\n");
    }

    const mwSize *dimsData1 = mxGetDimensions(prhs[0]);
    mwSize numDims1 = mxGetNumberOfDimensions(prhs[0]);

    const mwSize *dimsData2 = mxGetDimensions(prhs[1]);
    mwSize numDims2 = mxGetNumberOfDimensions(prhs[1]);

    if (numDims1 != 2 || numDims2 != 2) {
        usage();
        mexErrMsgTxt("Input data must be mxn 2D matrix\n");
    }

    if (nlhs != 1) {
        usage();
        mexErrMsgTxt("Wrong number of outputs\n");
    }

    //
    // Get data
    //

    float *data1 = (float*)mxGetData(prhs[0]);
    float *data2 = (float*)mxGetData(prhs[1]);
    int mRow = dimsData1[0]; //In MATLAB indexing

    int mCol1 = dimsData1[1]; //Number of points in set 1
    int mCol2 = dimsData2[1]; //Number of points in set 2

    //
    // Create libmv data
    //

    libmv::vector<int> indices;
    libmv::vector<int> indicesReverse;
    libmv::vector<float> distances;
    libmv::vector<float> distancesReverse;

    int NN = 1;
    FLANN_Data dataA={data1,mCol1,mRow};
    FLANN_Data dataB={data2,mCol2,mRow};

    //See documentation of FindSymmetricCandidateMatches_FLANN
    bool breturn = FLANN_Wrapper_KDTREE(dataA, dataB, &indices, &distances, NN)
                && FLANN_Wrapper_KDTREE(dataB, dataA, &indicesReverse,
                   &distancesReverse, NN);

    libmv::vector<int> successFull;
    if (breturn) {
      //TODO(pmoulon) clear previous matches.
      int max_track_number = 0;
      for (size_t i = 0; i < indices.size(); ++i) {
        // Add the matche only if we have a symetric result.
        if (i == indicesReverse[indices[i]])  {
          successFull.push_back(i);
        }
      }
    } else  {
      mexPrintf("FLANN error");
    }

    mwSize dims_out1[2] = {2, successFull.size()};
    plhs[0] = mxCreateNumericArray(2, dims_out1, mxDOUBLE_CLASS, mxREAL);

    double *outdata1 = (double*)mxGetData(plhs[0]);
    for (unsigned int ii = 0; ii < successFull.size(); ++ii) {
        outdata1[ii*2 + 0] = successFull[ii]+1;
        outdata1[ii*2 + 1] = indices[successFull[ii]]+1;
    }

}
