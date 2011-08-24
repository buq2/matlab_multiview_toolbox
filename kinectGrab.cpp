#include "mex.h"
#include "libfreenect.h"
#include <vector>
//#include <boost/thread/mutex.hpp>
#include <cmath>

void usage()
{
    mexPrintf(
    "Returns depth and RGB data from Kinect using libfreenect\n"
    "\n"
    "Inputs:\n"
    "       numFrames - Number of frames to grab (double)\n"
    "\n"
    "Outputs:\n"
    "        depth - Depth data\n"
    "        rgb   - RGB data\n"
    );
}

std::vector<uint8_t> m_buffer_depth;
std::vector<uint8_t> m_buffer_video;
std::vector<uint16_t> m_gamma(2048);
//boost::mutex mutex_frames;
int got_frames_rgb = 0;
int got_frames_depth = 0;
int max_frames_ = 10;
double *data_depth = NULL;
double *data_rgb = NULL;

const int width = 640;
const int height = 480;
const int channels = 3;




// Do not call directly even in child
void VideoCallback(freenect_device *m_dev, void* _rgb, uint32_t timestamp) {
    if (got_frames_rgb >= max_frames_) {
        return;
    }
    uint8_t* rgb = static_cast<uint8_t*>(_rgb);

    //size_t numBytes = freenect_get_current_depth_mode(m_dev).bytes;
    //size_t numElems = numBytes;
    size_t layer = width*height;
    size_t numElems = layer*3;
    for (size_t ii = 0; ii < numElems; ++ii) {
        data_rgb[numElems*got_frames_rgb + ii/3 + ii%3*layer] = rgb[ii];
    }
    
    ++got_frames_rgb;
};
    
// Do not call directly even in child
void DepthCallback(freenect_device *dev, void* _depth, uint32_t timestamp) {
    if (got_frames_depth >= max_frames_) {
        return;
    }
    
    uint16_t* depth = static_cast<uint16_t*>(_depth);
    size_t numElem = width*height;
    
    for(size_t ii = 0 ; ii < numElem ; ++ii) {
        double pval = m_gamma[depth[ii]];
        data_depth[numElem*got_frames_depth + ii] = pval;
    }
    
    ++got_frames_depth;
}

int capturedFrames() {
    return std::min(got_frames_rgb,got_frames_depth);
}

void mexFunction(int        nlhs,        /*(NumLeftHandSide) Number of arguments in left side of '=' (number of output arguments)*/
                 mxArray    *plhs[],     /*(PointerLeftHandSide) Pointers to output data*/
                 int        nrhs,        /*(NumRightHandSide) Number of input arguments*/
                 const mxArray  *prhs[]) /*(PointerRightHandSide) Pointers to input data*/
{

    if (nrhs < 1) {
        //Not enough inputs
        usage();
        mexErrMsgTxt("Not enough input parameters.\n");
    }

    if (mxGetClassID(prhs[0]) != mxDOUBLE_CLASS) {
        usage();
        mexErrMsgTxt("Number of frames to grap (argument 1) must be double precision scalar.\n");
    }

    if (mxGetNumberOfElements(prhs[0]) != 1) {
        usage();
        mexErrMsgTxt("Number of frames must be scalar\n");
    }

    max_frames_ = *((double*)mxGetData(prhs[0]));

    if (nlhs != 2) {
        usage();
        mexPrintf("There must be two outputs\n");
    }

    //Create output arrays
    

    mwSize dims_out_depth[3] = {width,height,max_frames_};
    mwSize dims_out_rgb[4] = {width,height,3,max_frames_};
    mxArray *out_rgb = mxCreateNumericArray(4, dims_out_rgb, mxDOUBLE_CLASS, mxREAL);
    mxArray *out_depth = mxCreateNumericArray(3, dims_out_depth, mxDOUBLE_CLASS, mxREAL);
    plhs[0] = out_depth;
    plhs[1] = out_rgb;

    data_rgb = (double*)mxGetData(out_rgb);
    data_depth = (double*)mxGetData(out_depth);

    //Initialize freenect library
    freenect_context *m_ctx;
    if (freenect_init(&m_ctx, NULL) < 0) {
        mexErrMsgTxt("Cannot initialize freenect library");
    }

    // We claim both the motor and camera devices, since this class exposes both.
    // It does not support audio, so we do not claim it.
    freenect_select_subdevices(m_ctx, static_cast<freenect_device_flags>(FREENECT_DEVICE_MOTOR | FREENECT_DEVICE_CAMERA));

    //Initialize buffers
    m_buffer_depth = std::vector<uint8_t>(freenect_find_video_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_VIDEO_RGB).bytes);
    m_buffer_video = std::vector<uint8_t>(freenect_find_depth_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_DEPTH_11BIT).bytes);

    //Initialize depth
    for( unsigned int i = 0 ; i < 2048 ; i++) {
        float v = i/2048.0;
        v = std::pow(v, 3)* 6;
        m_gamma[i] = v*6*256;
    }

    //Try to open device
    freenect_device *m_dev;

    if(freenect_open_device(m_ctx, &m_dev, 0) < 0) { //Open device 0
        mexErrMsgTxt("Cannot open Kinect");
    }
    
    freenect_set_video_mode(m_dev, freenect_find_video_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_VIDEO_RGB));
    freenect_set_depth_mode(m_dev, freenect_find_depth_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_DEPTH_11BIT));
    freenect_set_depth_callback(m_dev, DepthCallback);
    freenect_set_video_callback(m_dev, VideoCallback);

    freenect_video_format requested_format(FREENECT_VIDEO_RGB);
    
    if(freenect_start_video(m_dev) < 0) {
        mexErrMsgTxt("Cannot start RGB callback");
    }

    if(freenect_start_depth(m_dev) < 0) {
        mexErrMsgTxt("Cannot start depth callback");
    }

    
    while (capturedFrames() < max_frames_) {
        //mexPrintf("Waiting...\n");
        if(freenect_process_events(m_ctx) < 0) {
            mexPrintf("Cannot process freenect events");
        }
    }

    if(freenect_stop_video(m_dev) < 0) {
        mexErrMsgTxt("Cannot stop RGB callback");
    }

    if(freenect_stop_depth(m_dev) < 0) {
        mexErrMsgTxt("Cannot stop depth callback");
    }

    if(freenect_close_device(m_dev) < 0) {
        mexErrMsgTxt("Kinect closing failed");
    }

    if(freenect_shutdown < 0) {
        mexErrMsgTxt("Freenect shutdown failed");
    }
}


