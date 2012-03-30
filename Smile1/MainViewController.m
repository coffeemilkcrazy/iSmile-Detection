//
//  MainViewController.m
//  Smile1
//
//  Created by Phatthana Tongon on 3/30/55 BE.
//  Copyright (c) 2555 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()
- (UIImage *) imageWithView:(UIView *)view;
- (void)initCapture;

-(void)markFaces:(UIImage *)facePicture;
-(void)faceDetector;
-(int)smileProcess:(UIImage*)smileImg;

- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image;
- (UIImage *)UIImageFromIplImage:(IplImage *)image;
- (NSMutableArray *)getHistogramArray:(UIImage*)image;

@end

@implementation MainViewController

@synthesize captureSession = _captureSession;
@synthesize imageView = _imageView;
@synthesize customLayer = _customLayer;
@synthesize prevLayer = _prevLayer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    currentImage = [[UIImage alloc] init];
    
    // Do any additional setup after loading the view from its nib.
    [self initCapture];
    [HUDView setTransform:CGAffineTransformMakeScale(1, -1)];
    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void) viewDidAppear:(BOOL)animated {
    //	OverlayView *overlay = [[OverlayView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGTH)];
    
    NSLog(@"viewDidAppear");
    [super viewDidAppear:YES];
    
	// Create a new image picker instance:
    //	cameraPicker = [[UIImagePickerController alloc] init];
    //	cameraPicker.delegate = self;
    //    
    //	// Set the image picker source:
    //	cameraPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    //	
    //	// Hide the controls:
    //	cameraPicker.showsCameraControls = NO;
    //	cameraPicker.navigationBarHidden = YES;
    //	cameraPicker.view.frame = CGRectMake(0, 0, 160, 240);
    //    cameraPicker.wantsFullScreenLayout = YES;
    
    //	picker.cameraViewTransform = CGAffineTransformScale(picker.cameraViewTransform, CAMERA_TRANSFORM_X, CAMERA_TRANSFORM_Y);
    
    
   	// Show the picker:
    //    cameraPicker.view.opaque = YES;
    //    [cameraView addSubview:cameraPicker.view];
    
    //	[self presentModalViewController:picker animated:YES];	
    //	[picker release];
    
    //        previewTimer = [NSTimer scheduledTimerWithTimeInterval:3.5 
    //														 target:self selector:@selector(previewCheck) userInfo:nil repeats:YES];
    
        [NSTimer scheduledTimerWithTimeInterval:1
                                         target:self
                                       selector:@selector(smileDetection)
                                       userInfo:nil
                                        repeats:YES];
}

- (void)initCapture {
	/*We setup the input*/
	AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput 
										  deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] 
										  error:nil];
	/*We setupt the output*/
	AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	/*While a frame is processes in -captureOutput:didOutputSampleBuffer:fromConnection: delegate methods no other frames are added in the queue.
	 If you don't want this behaviour set the property to NO */
	captureOutput.alwaysDiscardsLateVideoFrames = YES; 
	/*We specify a minimum duration for each frame (play with this settings to avoid having too many frames waiting
	 in the queue because it can cause memory issues). It is similar to the inverse of the maximum framerate.
	 In this example we set a min frame duration of 1/10 seconds so a maximum framerate of 10fps. We say that
	 we are not able to process more than 10 frames per second.*/
	//captureOutput.minFrameDuration = CMTimeMake(1, 10);
	
	/*We create a serial queue to handle the processing of our frames*/
	dispatch_queue_t queue;
	queue = dispatch_queue_create("cameraQueue", NULL);
	[captureOutput setSampleBufferDelegate:self queue:queue];
	dispatch_release(queue);
    
    
	// Set the video output to store frame in BGRA (It is supposed to be faster)
	NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey; 
	NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]; 
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key]; 
	[captureOutput setVideoSettings:videoSettings];
    
	/*And we create a capture session*/
	self.captureSession = [[AVCaptureSession alloc] init];
	/*We add input and output*/
	[self.captureSession addInput:captureInput];
	[self.captureSession addOutput:captureOutput];
    /*We use medium quality, ont the iPhone 4 this demo would be laging too much, the conversion in UIImage and CGImage demands too much ressources for a 720p resolution.*/
    [self.captureSession setSessionPreset:AVCaptureSessionPresetLow];
	/*We add the Custom Layer (We need to change the orientation of the layer so that the video is displayed correctly)*/
	self.customLayer = [CALayer layer];
	self.customLayer.frame = self.view.bounds;
	self.customLayer.transform = CATransform3DRotate(CATransform3DIdentity, M_PI/2.0f, 0, 0, 1);
	self.customLayer.contentsGravity = kCAGravityResizeAspectFill;
	[self.view.layer addSublayer:self.customLayer];
    
	
    
    //    /*We add the imageView*/
    //	self.imageView = [[UIImageView alloc] init];
    //	self.imageView.frame = CGRectMake(0, 0, 100, 100);
    //    [self.view addSubview:self.imageView];
    
    
	/*We add the preview layer*/
	self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
    //	self.prevLayer.frame = CGRectMake(0, 0, 160, 214);
    self.prevLayer.frame = CGRectMake(0, 0, 320, 480);
    
	self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //	[cameraView.layer addSublayer: self.prevLayer];
    //    [self.view.layer addSublayer: self.prevLayer];
    
	/*We start the capture*/
	[self.captureSession startRunning];
	
}

#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection 
{ 
	/*We create an autorelease pool because as we are not in the main_queue our code is
	 not executed in the main thread. So we have to create an autorelease pool for the thread we are in*/
	
    //	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
    /*Lock the image buffer*/
    CVPixelBufferLockBaseAddress(imageBuffer,0); 
    /*Get information about the image*/
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer); 
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    size_t width = CVPixelBufferGetWidth(imageBuffer); 
    size_t height = CVPixelBufferGetHeight(imageBuffer);  
    
    /*Create a CGImageRef from the CVImageBufferRef*/
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext); 
	
    /*We release some components*/
    CGContextRelease(newContext); 
    CGColorSpaceRelease(colorSpace);
    
    /*We display the result on the custom layer. All the display stuff must be done in the main thread because
	 UIKit is no thread safe, and as we are not in the main thread (remember we didn't use the main_queue)
	 we use performSelectorOnMainThread to call our CALayer and tell it to display the CGImage.*/
    //	[self.customLayer performSelectorOnMainThread:@selector(setContents:) withObject: (id) newImage waitUntilDone:YES];
	
	/*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly).
	 Same thing as for the CALayer we are not in the main thread so ...*/
	UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
	
	/*We relase the CGImageRef*/
	
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    testBUG = !testBUG;
    
    CGSize newSize = CGSizeMake(320, 480);
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    resizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    
    
	[previewImgaeView performSelectorOnMainThread:@selector(setImage:) withObject:resizeImage waitUntilDone:YES];
    
    //    [previewImgaeView bringSubviewToFront:self.view];
	
    //[self performSelectorInBackground:@selector(markFaces:) withObject:resizeImage];
    //    [self markFaces:[image copy]];
    //    [self markFaces:image];
    //    [HUDView setTransform:CGAffineTransformMakeScale(1, -1)];
    
	/*We unlock the  image buffer*/
    
    CGImageRelease(newImage);
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
	
    //    sleep(1);
    //	[pool drain];
} 

-(void)previewCheck {
	NSLog(@"Check");
}


#pragma mark - Detect

- (IBAction)toggleHUD:(id)sender {
    HUDView.hidden = !HUDView.hidden;
    smileView.hidden = !smileView.hidden;
    histogramImageView.hidden = !histogramImageView.hidden;
}

-(void)markFaces:(UIImage *)facePicture
{
    
    // draw a CI image with the previously loaded face detection picture
    CIImage* image = [CIImage imageWithCGImage:facePicture.CGImage];
    
    // create a face detector - since speed is not an issue we'll use a high accuracy
    // detector
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace 
                                              context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy]];
    
    // create an array containing all the detected faces from the detector    
    NSArray* features = [detector featuresInImage:image];
    
    // we'll iterate through every detected face.  CIFaceFeature provides us
    // with the width for the entire face, and the coordinates of each eye
    // and the mouth if detected.  Also provided are BOOL's for the eye's and
    // mouth so we can check if they already exist.
    
    //    NSLog(@"Finding: %d",[features count]);
    
    HUDView.hidden = YES;
    for(CIFaceFeature* faceFeature in features)
    {
        HUDView.hidden = NO;
        // get the width of the face
        CGFloat faceWidth = faceFeature.bounds.size.width;
        
        // create a UIView using the bounds of the face
        //faceView = [[UIView alloc] initWithFrame:faceFeature.bounds];
        faceView.frame = faceFeature.bounds;
        // add a border around the newly created UIView
        faceView.backgroundColor = [UIColor clearColor];
        faceView.layer.borderWidth = 1;
        faceView.layer.borderColor = [[UIColor redColor] CGColor];
        
        // add the new view to create a box around the face
        //[HUDView addSubview:faceView];
        
        if(faceFeature.hasLeftEyePosition)
        {
            // create a UIView with a size based on the width of the face
            leftEyeView.frame = CGRectMake(faceFeature.leftEyePosition.x-faceWidth*0.15, faceFeature.leftEyePosition.y-faceWidth*0.15, faceWidth*0.3, faceWidth*0.3);
            // change the background color of the eye view
            [leftEyeView setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.3]];
            // set the position of the leftEyeView based on the face
            [leftEyeView setCenter:faceFeature.leftEyePosition];
            // round the corners
            leftEyeView.layer.cornerRadius = faceWidth*0.15;
            // add the view to the window
            //[HUDView addSubview:leftEyeView];
        }
        
        if(faceFeature.hasRightEyePosition)
        {
            // create a UIView with a size based on the width of the face
            leftEye.frame = CGRectMake(faceFeature.rightEyePosition.x-faceWidth*0.15, faceFeature.rightEyePosition.y-faceWidth*0.15, faceWidth*0.3, faceWidth*0.3);
            // change the background color of the eye view
            [leftEye setBackgroundColor:[[UIColor blueColor] colorWithAlphaComponent:0.3]];
            // set the position of the rightEyeView based on the face
            [leftEye setCenter:faceFeature.rightEyePosition];
            // round the corners
            leftEye.layer.cornerRadius = faceWidth*0.15;
            // add the new view to the window
            //[HUDView addSubview:leftEye];
        }
        
        if(faceFeature.hasMouthPosition)
        {
            // create a UIView with a size based on the width of the face
            
            CGRect mouthRect = CGRectMake(faceFeature.mouthPosition.x-faceWidth*0.2, faceFeature.mouthPosition.y-faceWidth*0.2, faceWidth*0.4, faceWidth*0.4);
            
            //float topSpace = faceFeature.bounds.origin.y;
            float bottomSpace = 460- (faceFeature.bounds.origin.y+faceFeature.bounds.size.height);
            
            CGRect cutRect = CGRectMake(faceFeature.mouthPosition.x-faceWidth*0.2, bottomSpace+(faceWidth*0.75), 
                                        faceWidth*0.4, faceWidth*0.4);
            
            mouthRect.origin.y += ((faceFeature.bounds.origin.y)+faceWidth*0.4);
            //mouthRect.origin.y += facePicture.bounds.size.height - (faceFeature.mouthPosition.y + faceWidth*0.2);
            //            CGImageRef imageRef = CGImageCreateWithImageInRect([facePicture CGImage], mouthRect);
            CGImageRef imageRef = CGImageCreateWithImageInRect([facePicture CGImage], cutRect);
            
            // or use the UIImage wherever you like
            
            
            
            //////////////////////////////////////////////////////////////
            
            UIImage *smileData = [UIImage imageWithCGImage:imageRef];
            smileView.image = [[SDetector detector] convertImageToGrayColor:smileData];
            CGImageRelease(imageRef);
            
            NSMutableArray *histoData = [[SDetector detector] getHistogramArray:smileData];
            
            int value = [[SDetector detector] smileProcess:histoData];
            scoreLB.text = [NSString stringWithFormat:@"%d",value];
            
            
            histogramImageView.image = [[SDetector detector] drawHistogram:histoData];
            
            //////////////////////////////////////////////////////////////
            
            
            
            mouth.frame = mouthRect;
            // change the background color for the mouth to green
            [mouth setBackgroundColor:[[UIColor greenColor] colorWithAlphaComponent:0.3]];
            // set the position of the mouthView based on the face
            [mouth setCenter:faceFeature.mouthPosition];
            // round the corners
            mouth.layer.cornerRadius = faceWidth*0.2;
            // add the new view to the window
        }
        
        //NSLog(@"Lx%.2f Ly%.2f Rx%.2f Ry%.2f Mx%.2f My%.2f", faceFeature.leftEyePosition.x, faceFeature.leftEyePosition.y, faceFeature.rightEyePosition.x, faceFeature.rightEyePosition.y, faceFeature.mouthPosition.x, faceFeature.mouthPosition.y);   
    }
}

- (void)smileDetection {
    [self performSelectorOnMainThread:@selector(markFaces:) withObject:resizeImage waitUntilDone:NO];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
