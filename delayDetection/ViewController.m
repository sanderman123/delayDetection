//
//  ViewController.m
//  delayDetection
//
//  Created by Sander Valstar on 3/30/15.
//  Copyright (c) 2015 Sander Valstar. All rights reserved.
//

#import "ViewController.h"
#import "MyAudioPlayer.h"
#import "CHCSVParser.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupAudioController];
    [self checkPeak];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (void)setupAudioController{
     audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription] inputEnabled:YES];
    audioController.preferredBufferDuration = 0.0014;
    
    delayArray = [[NSMutableArray alloc]init];
    
    MyAudioPlayer *player1 = [[MyAudioPlayer alloc]init];
    MyAudioPlayer *player2 = [[MyAudioPlayer alloc]init];
    AudioBufferList *abl1 = AEAllocateAndInitAudioBufferList([audioController audioDescription], 64);
    AudioBufferList *abl2 = AEAllocateAndInitAudioBufferList([audioController audioDescription], 64);
    
    channel1 = [audioController createChannelGroup];
    channel2 = [audioController createChannelGroup];
    [audioController addChannels:[NSArray arrayWithObject:player1] toChannelGroup:channel1];
    [audioController addChannels:[NSArray arrayWithObject:player2] toChannelGroup:channel2];
    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    [fileManager createFileAtPath:@"/Users/Me/Desktop/myimage.png" contents:myImageData attributes:nil];
    
    id<AEAudioReceiver> receiver = [AEBlockAudioReceiver audioReceiverWithBlock:
                                    ^(void *source,
                                      const AudioTimeStamp *time,
                                      UInt32 frames,
                                      AudioBufferList *audio) {
               
               abl1->mBuffers[0] = audio->mBuffers[0];
               abl1->mBuffers[1] = audio->mBuffers[0];
               
               abl2->mBuffers[0] = audio->mBuffers[1];
               abl2->mBuffers[1] = audio->mBuffers[1];
               
               [player1 addToBufferAudioBufferList:abl1 frames:frames timestamp:time];
               [player2 addToBufferAudioBufferList:abl2 frames:frames timestamp:time];
               
            }];
    [audioController addInputReceiver:receiver];
    
    NSError *err = nil;
    if (![audioController start:&err]) {
        NSLog(@"Error starting TAAE: %@",err.localizedDescription);
    } else {
        NSLog(@"TAAE successfully started");
    }
}

-(void)writeResultsToFile{
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
//    NSString *dateString = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
    NSString *dateString = [formatter stringFromDate:date];
    NSLog(@"Datestring: %@", dateString);
    NSString *path = [NSString stringWithFormat:@"/Users/mobilehci/Desktop/Results/Results_%@",dateString];
    NSLog(@"Path: %@",path);
    [[NSFileManager  defaultManager] createFileAtPath:path contents:nil attributes:nil];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    if (fileHandle) {
        for (int i = 0; i < delayArray.count; i++) {
            NSString *str = [delayArray objectAtIndex:i];
            NSData *data = [[NSData alloc]initWithData:[str dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:data];
        }
        [fileHandle closeFile];
        NSLog(@"File written");
    } else {
        NSLog(@"Error creating file handle");
    }
    
//    [delayArray writeToFile:@"/Users/Sander/Desktop/Results" atomically:YES];
    [audioController stop];
}

-(void)checkPeak{
    checkPeakQueue = dispatch_queue_create("checkPeakQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(checkPeakQueue, ^{
        while (true) {
            float pwl1;
            float peak1;
            //                                        [audioController inputAveragePowerLevel:&pwl peakHoldLevel:&peak];
            [audioController averagePowerLevel:&pwl1 peakHoldLevel:&peak1 forGroup:channel2];
            //                                        NSLog(@"1. Avg Power Level: %f, peak: %f",pwl1,peak1);
            
            if (!time1) {
                if (peak1 > -9.f) {
                    time1 = [NSDate date];
                    //                                                NSLog(@"Peakk!!: %f",peak1);
                }
            }
            
            float pwl2;
            float peak2;
            [audioController averagePowerLevel:&pwl2 peakHoldLevel:&peak2 forGroup:channel1];
            // NSLog(@"1. Avg Power Level: %f, peak: %f",pwl2,peak2);
            
            if (time1) {
                if (peak2 > -9.f) {
                    time2 = [NSDate date];
                    NSTimeInterval delay = [time2 timeIntervalSinceDate:time1];
                    if (delay < 0.06f && 0.005f < delay) {
                        NSString *delayString = [NSString stringWithFormat:@"%f\n",delay];
                        NSLog(@"Delay: %f", delay);
                        [delayArray addObject:delayString];
                        if (delayArray.count == 100) {
                            break;
                        }
                    } else {
                        NSLog(@"Error, Delay: %f", delay);
                    }
                    time1 = nil;
                    time2 = nil;
                }
            }
        }
        [self writeResultsToFile];
    });
    
}
@end
