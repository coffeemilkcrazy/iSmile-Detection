//
//  SDetector.m
//  Smile1
//
//  Created by Jarruspong Makkul on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SDetector.h"

@implementation SDetector


static SDetector *detector = nil;

+ (SDetector *)detector
{
    @synchronized(self) {
        if (detector == nil) {
            detector = [[SDetector alloc] init];
        }
    }
    return detector;
}

- (UIImage *)convertImageToGrayColor:(UIImage *)colorImage {
    
    IplImage *img_color = [self CreateIplImageFromUIImage:colorImage];
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
    UIImage *grayImage = [self UIImageFromIplImage:imageSmile];
    cvReleaseImage(&imageSmile);
    
    return grayImage;
}

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
    
    cvReleaseImage(&img_grayOutput);
    cvReleaseImage(&img_gray2);
    cvReleaseImage(&img_gray);
    cvReleaseImage(&img_color);
    
    
    return histogramDataArr;
}

- (int)smileProcess:(NSMutableArray*)histoArr
{
    int score = 0;
    
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


- (UIImage *)drawHistogram:(NSMutableArray *)array {
    double max=0;
    CvScalar pointXY;
    
    for (int i=0; i<=254; i++) {
        NSString *data = [array objectAtIndex:i];
        if ([data doubleValue] > max) {
            max = [data doubleValue];
        }
    }
    
    UIImage *histogramIMG = [UIImage imageNamed:@"Histogram.jpg"];
    IplImage *histo_color = [self CreateIplImageFromUIImage:histogramIMG];
    IplImage *histoOutput = cvCreateImage(cvGetSize(histo_color), IPL_DEPTH_8U, 3);
    
    for (int y=0; y < histo_color->width; y++) 
    {
        NSString *data = [array objectAtIndex:y];
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
    
    UIImage *result = [self UIImageFromIplImage:histoOutput];
    cvReleaseImage(&histoOutput);
    cvReleaseImage(&histo_color);
    
    return result;
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


@end
