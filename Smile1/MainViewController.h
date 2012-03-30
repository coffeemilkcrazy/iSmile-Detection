//
//  MainViewController.h
//  Smile1
//
//  Created by Phatthana Tongon on 3/30/55 BE.
//  Copyright (c) 2555 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/objdetect/objdetect.hpp>

#import "SDetector.h"

@interface MainViewController : UIViewController
<UIImagePickerControllerDelegate,UINavigationControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
{
    IBOutlet UIView *previewView;
    IBOutlet UIImageView *previewImgaeView;
    IBOutlet UIView *cameraView;
    
    UIImagePickerController *cameraPicker;
    NSTimer *previewTimer;

    AVCaptureSession *_captureSession;
//	UIImageView *_imageView;
	CALayer *_customLayer;
	AVCaptureVideoPreviewLayer *_prevLayer;
    
    IBOutlet UIImageView *smileView;
    IBOutlet UIView *HUDView;
    IBOutlet UIView* faceView;
    IBOutlet UIView* leftEyeView;
    IBOutlet UIView* leftEye;
    IBOutlet UIView* mouth;
    IBOutlet UIImageView *testCam;
    
    UIImage *resizeImage;
    IBOutlet UIImageView *histogramImageView;
    IBOutlet UILabel *scoreLB;

    UIImage *currentImage;
    
    BOOL testBUG;
}

@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) CALayer *customLayer;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *prevLayer;

- (IBAction)toggleHUD:(id)sender;

@end
