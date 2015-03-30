//
//  ViewController.h
//  delayDetection
//
//  Created by Sander Valstar on 3/30/15.
//  Copyright (c) 2015 Sander Valstar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TheAmazingAudioEngine.h"

@interface ViewController : UIViewController{
    AEAudioController *audioController;
    NSTimeInterval time1;//timeStamp = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval time2;
}


@end

