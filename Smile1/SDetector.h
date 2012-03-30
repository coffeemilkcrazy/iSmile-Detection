//
//  SDetector.h
//  Smile1
//
//  Created by Jarruspong Makkul on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/objdetect/objdetect.hpp>

@interface SDetector : NSObject

+ (SDetector *)detector;


//API

- (UIImage *)drawHistogram:(NSMutableArray *)array;

- (int)smileProcess:(NSMutableArray*)histoArr;

- (NSMutableArray *)getHistogramArray:(UIImage*)image;

- (UIImage *)convertImageToGrayColor:(UIImage *)colorImage;

@end
