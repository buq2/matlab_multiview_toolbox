#include "mex.h"
#include "libfreenect.h" 
#include <vector>
#include <cmath>
#include <limits> //NaN
#include <pthread.h>

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
    "        accel - Raw accelaration data for each frame\n"
    );
}

//Kinect device (physical device)
freenect_device *kinectDevice = NULL;
//Freenect library context
freenect_context *freenectContext = NULL;
//Number of rgb frames captured
int framesCapturedRgb = 0;
//Number of depth frames captured
int framesCapturedDepth = 0;
//Number of frames to be captured
int framesToBeCaptured = 0;
//Pointers to MATLAB output data
double *data_depth = NULL;
uint8_t *data_rgb = NULL;
double *data_accel = NULL;

//Video constants
const int width = 640;
const int height = 480;
const int channels = 3;

//Have we received valid vide/depth?
bool validDepthReceived = false;
bool validRgbReceived = false;

//Simple check to make sure that depth buffer contains actual data
bool isValidDepthBuffer(void* depthBuf)
{
    uint16_t* depth = static_cast<uint16_t*>(depthBuf);
    size_t numElem = width*height;
    for(size_t ii = 0 ; ii < numElem ; ++ii) {
        if (depth[ii] != 0) {
            return true;
        }
    }
    return false;
}

//Simple check to make sure that rgb buffer contains actual data
bool isValidRgbBuffer(void* rgbBuf)
{
    uint8_t* rgb = static_cast<uint8_t*>(rgbBuf);
    size_t layer = width*height;
    size_t numElems = layer*3;
    for(size_t ii = 0 ; ii < numElems ; ++ii) {
        if (rgb[ii] != 0) {
            return true;
        }
    }
    return false;
}

// Do not call directly even in child
void VideoCallback(freenect_device *kinectDeviceCaller, void* rgbBuf, uint32_t timestamp)
{
    //Have we already received valid rgb data?
    if (!validRgbReceived) {
        validRgbReceived = isValidRgbBuffer(rgbBuf);
        if (!validRgbReceived) {
            return; //Rgb data not yet valid. Wait for next buffer
        }
    }

    //We also must wait for valid depth
    if (!validDepthReceived) {
        return; //Wait till depth is ready
    }

    //Do not try to capture more frames than needed
    if (framesCapturedRgb >= framesToBeCaptured) {
        return;
    }
    uint8_t* rgb = static_cast<uint8_t*>(rgbBuf);

    //size_t numBytes = freenect_get_current_depth_mode(device).bytes;
    //size_t numElems = numBytes;
    size_t layer = width*height;
    size_t numElems = layer*3;
    for (size_t ii = 0; ii < numElems; ++ii) {
        data_rgb[numElems*framesCapturedRgb + ii/3 + ii%3*layer] = rgb[ii];
    }
    
    ++framesCapturedRgb;
};
    
// Do not call directly even in child
void DepthCallback(freenect_device *kinectDeviceCaller, void* depthBuf, uint32_t timestamp)
{
    //Have we already received valid rgb data?
    if (!validDepthReceived) {
        validDepthReceived = isValidDepthBuffer(depthBuf);
        return; //RGB must be captured first
        //if (!validDepthReceived) {
        //    return; //Rgb data not yet valid. Wait for next buffer
        //}
    }

    //We also must wait for valid depth
    if (framesCapturedRgb==0) {
        return; //Wait till depth is ready
    }

    //Do not try to capture more frames than needed
    if (framesCapturedDepth >= framesToBeCaptured) {
        return;
    }

    //Get the acceleration state
    double *datacol = &data_accel[3*framesCapturedDepth];
    freenect_raw_tilt_state *tiltstateptr = freenect_get_tilt_state(kinectDeviceCaller);
    freenect_get_mks_accel(tiltstateptr, datacol, datacol+1, datacol+2);
        
    //Get depth data
    uint16_t* depth = static_cast<uint16_t*>(depthBuf);
    size_t numElem = width*height;
    
    for(size_t ii = 0 ; ii < numElem ; ++ii) {
        data_depth[numElem*framesCapturedDepth + ii] = depth[ii];
    }
        
    ++framesCapturedDepth;
}

//Returns how many frames have been captured
int capturedFrames()
{
    return std::min(framesCapturedRgb,framesCapturedDepth);
}

//Additional processing (update acceleration values)
void *process(void *data)
{
    int currentFrame = 0;
    //While images need to be captured
    while ((currentFrame = capturedFrames()) < framesToBeCaptured) {
        //Send blocking request to update tilt state
        if(freenect_update_tilt_state(kinectDevice) != 0) {
            //We might be trying to update too often
        }
    }

    //Terminate thread
    thread_exit:
    pthread_exit(NULL);
}

void mexFunction(int        nlhs,        /*(NumLeftHandSide) Number of arguments in left side of '=' (number of output arguments)*/
                 mxArray    *plhs[],     /*(PointerLeftHandSide) Pointers to output data*/
                 int        nrhs,        /*(NumRightHandSide) Number of input arguments*/
                 const mxArray  *prhs[]) /*(PointerRightHandSide) Pointers to input data*/
{
    //Initialize globals
    freenectContext = NULL;
    kinectDevice = NULL;
    framesCapturedRgb = 0;
    framesCapturedDepth = 0;
    framesToBeCaptured = 0;
    data_depth = NULL;
    data_rgb = NULL;
    data_accel = NULL;
    validDepthReceived = false;
    validRgbReceived = false;

    //Error checking for inputs and outputs
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

    //Get number of frames to be captured
    framesToBeCaptured = *((double*)mxGetData(prhs[0]));

    if (nlhs != 3) {
        usage();
        mexPrintf("There must be three outputs\n");
    }

    //Create output arrays
    mwSize dims_out_depth[3] = {width,height,framesToBeCaptured};
    mwSize dims_out_rgb[4] = {width,height,3,framesToBeCaptured};
    mwSize dims_out_accel[2] = {3,framesToBeCaptured};
    mxArray *out_rgb = mxCreateNumericArray(4, dims_out_rgb, mxUINT8_CLASS, mxREAL);
    mxArray *out_depth = mxCreateNumericArray(3, dims_out_depth, mxDOUBLE_CLASS, mxREAL);
    mxArray *out_accel = mxCreateNumericArray(2, dims_out_accel, mxDOUBLE_CLASS, mxREAL);
    plhs[0] = out_depth;
    plhs[1] = out_rgb;
    plhs[2] = out_accel;

    data_rgb = (uint8_t*)mxGetData(out_rgb);
    data_depth = (double*)mxGetData(out_depth);
    data_accel = (double*)mxGetData(out_accel);
    
    //Initialize freenect library
    if (freenect_init(&freenectContext, NULL) < 0) {
        mexErrMsgTxt("Cannot initialize freenect library");
    }

    //We claim both the motor and camera devices, since this class exposes both.
    //It does not support audio, so we do not claim it.
    freenect_select_subdevices(freenectContext, static_cast<freenect_device_flags>(FREENECT_DEVICE_MOTOR | FREENECT_DEVICE_CAMERA));

    //Try to open device
    //Open device 0
    if(freenect_open_device(freenectContext, &kinectDevice, 0) < 0) { 
        mexErrMsgTxt("Cannot open Kinect");
    }

    //We would like to use these video output formats
    freenect_video_format requested_format_rgb(FREENECT_VIDEO_RGB);
    freenect_depth_format requested_format_depth(FREENECT_DEPTH_11BIT);

    //Set video modes and callbacks
    freenect_set_video_mode(kinectDevice, freenect_find_video_mode(FREENECT_RESOLUTION_MEDIUM, requested_format_rgb));
    freenect_set_depth_mode(kinectDevice, freenect_find_depth_mode(FREENECT_RESOLUTION_MEDIUM, requested_format_depth));
    freenect_set_depth_callback(kinectDevice, DepthCallback);
    freenect_set_video_callback(kinectDevice, VideoCallback);

    //Open video and depth capturing
    if(freenect_start_video(kinectDevice) < 0) {
        mexErrMsgTxt("Cannot start RGB video");
    }

    if(freenect_start_depth(kinectDevice) < 0) {
        mexErrMsgTxt("Cannot start depth");
    }

    //Two processing threads, one at "process" updating acceleration
    //and one here (main thread) processing events
    pthread_t thread;
    int rc = pthread_create(&thread, NULL, process, (void*)&thread);
    if (rc) {
        mexErrMsgTxt("problem with return code from pthread_create()");
    }
    
    int currentFrame = 0;
    //While still some images need to be captured
    while ((currentFrame = capturedFrames()) < framesToBeCaptured) {
        //Process USB events and images
        if(freenect_process_events(freenectContext) < 0) {
            mexPrintf("Cannot process freenect events\n");
        }
    }

    //Wait till acceleration updating thread stops
    void *status;
    pthread_join(thread, &status);

    //Stop video and depth capturing
    if(freenect_stop_video(kinectDevice) < 0) {
        mexErrMsgTxt("Cannot stop RGB callback");
    }

    if(freenect_stop_depth(kinectDevice) < 0) {
        mexErrMsgTxt("Cannot stop depth callback");
    }

    //Close USB device
    if(freenect_close_device(kinectDevice) < 0) {
        mexErrMsgTxt("Closing of the Kinect failed");
    }

    //Uninit freenect
    if(freenect_shutdown < 0) {
        mexErrMsgTxt("Freenect shutdown failed");
    }

    //Permute outputs (otherwise images seem to be trasposed)
    mwSize permute1_vec_size[1] = {3};
    mxArray *permute1_in_params[2] = {out_depth,mxCreateNumericArray(1, permute1_vec_size, mxDOUBLE_CLASS, mxREAL)};
    double *data_permute1_vec = (double*)mxGetData(permute1_in_params[1]);
    data_permute1_vec[0] = 2;
    data_permute1_vec[1] = 1;
    data_permute1_vec[2] = 3;
    mexCallMATLAB(1, &plhs[0], 2, permute1_in_params, "permute");

    mwSize permute2_vec_size[1] = {4};
    mxArray *permute2_in_params[2] = {out_rgb,mxCreateNumericArray(1, permute2_vec_size, mxDOUBLE_CLASS, mxREAL)};
    double *data_permute2_vec = (double*)mxGetData(permute2_in_params[1]);
    data_permute2_vec[0] = 2;
    data_permute2_vec[1] = 1;
    data_permute2_vec[2] = 3;
    data_permute2_vec[3] = 4;
    mexCallMATLAB(1, &plhs[1], 2, permute2_in_params, "permute");

    //pthread_exit should never be called from main thread when using MATLAB
    //as it causes MATLAB to exit ("crash")
    //pthread_exit(NULL);
}
