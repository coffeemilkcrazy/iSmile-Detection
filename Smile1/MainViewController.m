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
    
    
    //    NSLog(@"W: %f  H: %f",resizeImage.size.width,resizeImage.size.height);
    //    CIImage *ciImage = [CIImage imageWithCGImage:resizeImage.CGImage];
    ////    CIImage* ciImage = [CIImage imageWithCGImage:newImage];
    //    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace 
    //                                              context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy]];
    //    NSArray* features = [detector featuresInImage:ciImage options:nil];
    //    NSLog(@"Finding: %d",[features count]);
    
    
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
//-(void)markFaces
{
    //    testCam.image = facePicture;
    //    testCam.image = currentImage;
    
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
            smileView.image = [UIImage imageWithCGImage:imageRef]; 
            //[smileView setTransform:CGAffineTransformMakeScale(1, -1)];
            CGImageRelease(imageRef);
            
            //            NSLog(@"Score: %d",[self smileProcess:smileView.image]);
            scoreLB.text = [NSString stringWithFormat:@"%d",[self smileProcess:smileView.image]];
            //            
            mouth.frame = mouthRect;
            // change the background color for the mouth to green
            [mouth setBackgroundColor:[[UIColor greenColor] colorWithAlphaComponent:0.3]];
            // set the position of the mouthView based on the face
            [mouth setCenter:faceFeature.mouthPosition];
            // round the corners
            mouth.layer.cornerRadius = faceWidth*0.2;
            // add the new view to the window
        }
        
        NSLog(@"Lx%.2f Ly%.2f Rx%.2f Ry%.2f Mx%.2f My%.2f", faceFeature.leftEyePosition.x, faceFeature.leftEyePosition.y, faceFeature.rightEyePosition.x, faceFeature.rightEyePosition.y, faceFeature.mouthPosition.x, faceFeature.mouthPosition.y);   
    }
}

-(void)faceDetector
{
    //    imageView.image = [UIImage imageNamed:@"2.JPG"];
    
    // Execute the method used to markFaces in background
    //    [self performSelectorInBackground:@selector(markFaces:) withObject:imageView.image];
    //    
    //    [HUDView setTransform:CGAffineTransformMakeScale(1, -1)];
}

- (void)smileDetection {
    [self performSelectorOnMainThread:@selector(markFaces:) withObject:resizeImage waitUntilDone:NO];
}


-(int)smileProcess:(UIImage*)smileImg
{
    int score = 0;
    NSMutableArray *histoArr = [[NSMutableArray alloc] init];
    histoArr = [self getHistogramArray:smileImg];
    
    for (int i=0; i<=80; i++) {
        score = score + ([[histoArr objectAtIndex:i] intValue]*0.5);
    }
    //    NSLog(@"ScoreBlack: %d",score);
    
    for (int i=180; i<=255; i++) {
        score = score + ([[histoArr objectAtIndex:i] intValue]*3);
    }
    //    NSLog(@"Score: %d",score);
    return  score;
}


#pragma mark - OpenCV

- (NSMutableArray *)getHistogramArray:(UIImage*)image
{
    NSMutableArray *histogramDataArr = [[NSMutableArray alloc] init];
    
    cvSetErrMode(CV_ErrModeParent);
    histogramDataArr = [[NSMutableArray alloc] init];
    for (int i=0; i<=255; i++) {
        NSString *data = [NSString stringWithFormat:@"0"];
        [histogramDataArr addObject:data];
    }
    
    IplImage *img_color = [self CreateIplImageFromUIImage:image];
    IplImage *img_gray = cvCreateImage(cvGetSize(img_color), IPL_DEPTH_8U, 1);
    cvCvtColor(img_color, img_gray, CV_BGR2GRAY);
    
    IplImage *img_gray2 = cvCreateImage(cvGetSize(img_color), IPL_DEPTH_8U, 1);
    cvCvtColor(img_color, img_gray2, CV_BGR2GRAY);
    
    
    IplImage *imageSmile = cvCreateImage(cvGetSize(img_gray), IPL_DEPTH_8U, 3);
    for(int y=0; y<img_gray2->height; y++) {
        for(int x=0; x<img_gray->width; x++) {
            char *p = imageSmile->imageData + y * imageSmile->widthStep + x * 3;
            *p = *(p+1) = *(p+2) = img_gray->imageData[y * img_gray->widthStep + x];
        }
    }
    smileView.image = [self UIImageFromIplImage:imageSmile];
    cvReleaseImage(&imageSmile);
    
    IplImage *img_grayOutput = cvCreateImage(cvGetSize(img_color), IPL_DEPTH_8U, 1);
    cvCvtColor(img_color, img_grayOutput, CV_BGR2GRAY);
    
    cvSmooth(img_gray2, img_gray, CV_MEDIAN, 3, 3, 1, 1);
    
    CvScalar pointXY;
    for (int y=0; y < img_gray->height; y++) 
    {
        for (int x=0; x < img_gray->width ; x++) 
        {                
            pointXY = cvGet2D(img_gray, y, x);
            int index = (int)pointXY.val[0];
            NSString *data = [histogramDataArr objectAtIndex:index];
            double score = [data doubleValue];
            score = score + 1;
            data = [NSString stringWithFormat:@"%f",score];
            [histogramDataArr replaceObjectAtIndex:index withObject:data];
        }
    }
    
    double max=0;
    
    for (int i=0; i<=254; i++) {
        NSString *data = [histogramDataArr objectAtIndex:i];
        if ([data doubleValue] > max) {
            max = [data doubleValue];
        }
    }
    
    cvReleaseImage(&img_grayOutput);
    cvReleaseImage(&img_gray2);
    cvReleaseImage(&img_gray);
    cvReleaseImage(&img_color);
    
    UIImage *histogramIMG = [UIImage imageNamed:@"Histogram.jpg"];
    IplImage *histo_color = [self CreateIplImageFromUIImage:histogramIMG];
    IplImage *histoOutput = cvCreateImage(cvGetSize(histo_color), IPL_DEPTH_8U, 3);
    
    for (int y=0; y < histo_color->width; y++) 
    {
        NSString *data = [histogramDataArr objectAtIndex:y];
        long score = [data intValue];
        float scale = (float)(score-1)/(float)max;
        long head = (long)((float)histogramIMG.size.height*scale);
        long finnish = histogramIMG.size.height-1 - head;
        
        for (long x=0; x<histo_color->height; x++) {
            pointXY.val[0] = 255;
            cvSet2D(histoOutput, x, y, pointXY);
        }
        
        for (long x=histogramIMG.size.height-1; x > finnish ; x--) 
        {
            pointXY.val[0] = 0;
            cvSet2D(histoOutput, x, y, pointXY);
        }
    }
    
    
    histogramImageView.image = [self UIImageFromIplImage:histoOutput];
    cvReleaseImage(&histoOutput);
    cvReleaseImage(&histo_color);
    return histogramDataArr;
}


#pragma mark -
#pragma mark OpenCV Support Methods

// NOTE you SHOULD cvReleaseImage() for the return value when end of the code.
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
	CGImageRef imageRef = image.CGImage;
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	IplImage *iplimage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
	CGContextRef contextRef = CGBitmapContextCreate(iplimage->imageData, iplimage->width, iplimage->height,
													iplimage->depth, iplimage->widthStep,
													colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
	CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);
	CGContextRelease(contextRef);
	CGColorSpaceRelease(colorSpace);
    
	IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
	cvCvtColor(iplimage, ret, CV_RGBA2BGR);
	cvReleaseImage(&iplimage);
    
	return ret;
}

// NOTE You should convert color mode as RGB before passing to this function
- (UIImage *)UIImageFromIplImage:(IplImage *)image {
	//NSLog(@"IplImage (%d, %d) %d bits by %d channels, %d bytes/row %s", image->width, image->height, image->depth, image->nChannels, image->widthStep, image->channelSeq);
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(image->width, image->height,
										image->depth, image->depth * image->nChannels, image->widthStep,
										colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
										provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *ret = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	return ret;
}


#pragma mark - View to Imgae
- (UIImage *) imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
