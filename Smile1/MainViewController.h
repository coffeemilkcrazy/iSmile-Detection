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

#import <AudioToolbox/AudioToolbox.h>
#import "AVCamCaptureManager.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/CGImageProperties.h>

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
    IBOutlet UIView* pointView;
    IBOutlet UIImageView *testCam;
    
    UIImage *resizeImage;
    IBOutlet UIImageView *histogramImageView;
    IBOutlet UILabel *scoreLB;

    UIImage *currentImage;
    
    IBOutlet UIButton *hudBt;
    IBOutlet UIButton *autoBt;
    IBOutlet UIProgressView *progressView;
    BOOL autoON;
    int oldDiffSUM ,newDiffSUM;
    NSMutableArray *oldHistoArr, *newHistoArr;
    BOOL testBUG;
    IBOutlet UISegmentedControl *segmentLevel;
    
    float currentLevel;
}

@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) CALayer *customLayer;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *prevLayer;
@property (nonatomic,retain) AVCamCaptureManager *captureManager;

- (IBAction)toggleHUD:(id)sender;
- (void)updateButton;
- (IBAction)toggleAuto:(id)sender;
- (IBAction)changeLevel:(id)sender;
- (IBAction)captureStillImage:(id)sender;

@end
