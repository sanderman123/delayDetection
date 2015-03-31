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
    NSDate *time1;//timeStamp = [[NSDate date] timeIntervalSince1970];
    NSDate *time2;
    NSMutableArray *delayArray;
    dispatch_queue_t checkPeakQueue;
    AEChannelGroupRef channel1;
    AEChannelGroupRef channel2;
}


@end

