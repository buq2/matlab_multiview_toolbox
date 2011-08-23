#include "mex.h"
#include "libfreenect.hpp"
#include <vector>
#include <boost/thread/mutex.hpp>

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


class MyFreenectDevice : public Freenect::FreenectDevice {
public:
    MyFreenectDevice(freenect_context *_ctx, int _index)
        :
        Freenect::FreenectDevice(_ctx, _index),
        m_buffer_depth(freenect_find_video_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_VIDEO_RGB).bytes),
        m_buffer_video(freenect_find_video_mode(FREENECT_RESOLUTION_MEDIUM, FREENECT_VIDEO_RGB).bytes),
        m_gamma(2048),
        got_frames_rgb(0),
        got_frames_depth(0),
        max_frames_(10)
    {
        for( unsigned int i = 0 ; i < 2048 ; i++) {
            float v = i/2048.0;
            v = std::pow(v, 3)* 6;
            m_gamma[i] = v*6*256;
        }
    }

    void setMaxFrames(int numFrames)
    {
        max_frames_ = numFrames;
    }
    
    //~MyFreenectDevice(){}
    // Do not call directly even in child
    void VideoCallback(void* _rgb, uint32_t timestamp) {
        //mexPrintf("New frame RGB\n");
        uint8_t* rgb = static_cast<uint8_t*>(_rgb);
        std::copy(rgb, rgb+getVideoBufferSize(), m_buffer_video.begin());
        boost::mutex::scoped_lock lock(mutex_frames);
        ++got_frames_rgb;
        if (got_frames_rgb >= max_frames_) {
            stopVideo();
        }
    };
    // Do not call directly even in child
    void DepthCallback(void* _depth, uint32_t timestamp) {
        //mexPrintf("New frame Depth\n");
        uint16_t* depth = static_cast<uint16_t*>(_depth);
        for( unsigned int i = 0 ; i < 640*480 ; i++) {
            int pval = m_gamma[depth[i]];
            int lb = pval & 0xff;
            switch (pval>>8) {
            case 0:
                m_buffer_depth[3*i+0] = 255;
                m_buffer_depth[3*i+1] = 255-lb;
                m_buffer_depth[3*i+2] = 255-lb;
                break;
            case 1:
                m_buffer_depth[3*i+0] = 255;
                m_buffer_depth[3*i+1] = lb;
                m_buffer_depth[3*i+2] = 0;
                break;
            case 2:
                m_buffer_depth[3*i+0] = 255-lb;
                m_buffer_depth[3*i+1] = 255;
                m_buffer_depth[3*i+2] = 0;
                break;
            case 3:
                m_buffer_depth[3*i+0] = 0;
                m_buffer_depth[3*i+1] = 255;
                m_buffer_depth[3*i+2] = lb;
                break;
            case 4:
                m_buffer_depth[3*i+0] = 0;
                m_buffer_depth[3*i+1] = 255-lb;
                m_buffer_depth[3*i+2] = 255;
                break;
            case 5:
                m_buffer_depth[3*i+0] = 0;
                m_buffer_depth[3*i+1] = 0;
                m_buffer_depth[3*i+2] = 255-lb;
                break;
            default:
                m_buffer_depth[3*i+0] = 0;
                m_buffer_depth[3*i+1] = 0;
                m_buffer_depth[3*i+2] = 0;
                break;
            }
        }
        boost::mutex::scoped_lock lock(mutex_frames);
        ++got_frames_depth;
        if (got_frames_depth >= max_frames_) {
            stopDepth();
        }
    }

    int capturedFrames() {
        boost::mutex::scoped_lock lock(mutex_frames);
        return std::min(got_frames_rgb,got_frames_depth);
    }

private:
    std::vector<uint8_t> m_buffer_depth;
    std::vector<uint8_t> m_buffer_video;
    std::vector<uint16_t> m_gamma;
    boost::mutex mutex_frames;
    int got_frames_rgb;
    int got_frames_depth;
    int max_frames_;
};



double freenect_angle(0);

double *data_depth = NULL;
double *data_rgb = NULL;

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

    double numFrames = *((double*)mxGetData(prhs[0]));

    if (nlhs != 2) {
        usage();
        mexPrintf("There must be two outputs\n");
    }

    const int width = 640;
    const int height = 480;
    const int channels = 3;
    //mwSize dims_out[3] = {width,height,channels};
    //mxArray *out_rgb = mxCreateNumericArray(3, dims_out, mxDOUBLE_CLASS, mxREAL);
    //mxArray *out_depth = mxCreateNumericArray(2, dims_out, mxDOUBLE_CLASS, mxREAL);

    //data_rgb = (double*)mxGetData(out_rgb);
    //data_depth = (double*)mxGetData(out_depth);

    Freenect::Freenect freenect;
    MyFreenectDevice* device;
    freenect_video_format requested_format(FREENECT_VIDEO_RGB);

    device = &freenect.createDevice<MyFreenectDevice>(0);
    device->setMaxFrames(10);


    

    device->startVideo();
    device->startDepth();

    while (device->capturedFrames() < 10) {
        
    }

    device->stopVideo();
    device->stopDepth();
    
}


