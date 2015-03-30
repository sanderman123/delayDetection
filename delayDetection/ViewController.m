//
//  ViewController.m
//  delayDetection
//
//  Created by Sander Valstar on 3/30/15.
//  Copyright (c) 2015 Sander Valstar. All rights reserved.
//

#import "ViewController.h"
#import "MyAudioPlayer.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupAudioController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (void)setupAudioController{
     audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription] inputEnabled:YES];
    audioController.preferredBufferDuration = 0.0029;
    
//    [audioController addInputReceiver:
//     [AEBlockAudioReceiver audioReceiverWithBlock:^(void *source,
//                                                    const AudioTimeStamp *time,
//                                                    UInt32 frames,
//                                                    AudioBufferList *audio) {
//            // Receiving left channel
//            //Devide the ABL into one stereo ABL per channel
////            for (int i = 0; i < numChannels; i++) {
////                //ablist->mBuffers[i]
////                ((AudioBufferManager*)[ablArray1 objectAtIndex:i]).buffer->mBuffers[0] = audio->mBuffers[i];
////                ((AudioBufferManager*)[ablArray1 objectAtIndex:i]).buffer->mBuffers[1] = audio->mBuffers[i];
////            }
////            for (int i = 0; i < (int)clients.count; i++) {
////                [[clients objectAtIndex:i] mixAudioBufferListArray:ablArray1];
////            }
//        
//    }]];
    
    MyAudioPlayer *player1 = [[MyAudioPlayer alloc]init];
    MyAudioPlayer *player2 = [[MyAudioPlayer alloc]init];
    AudioBufferList *abl1 = AEAllocateAndInitAudioBufferList([audioController audioDescription], 64);
    AudioBufferList *abl2 = AEAllocateAndInitAudioBufferList([audioController audioDescription], 64);
    
    AEChannelGroupRef channel1 = [audioController createChannelGroup];
    AEChannelGroupRef channel2 = [audioController createChannelGroup];
    [audioController addChannels:[NSArray arrayWithObject:player1] toChannelGroup:channel1];
    [audioController addChannels:[NSArray arrayWithObject:player2] toChannelGroup:channel2];
    
//    time1 = 0.f;
//    time2 = 0.f;
    
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
                                        
                                        
                                        
                                        // Do something with 'audio'
                                        float pwl1;
                                        float peak1;
//                                        [audioController inputAveragePowerLevel:&pwl peakHoldLevel:&peak];
                                        [audioController averagePowerLevel:&pwl1 peakHoldLevel:&peak1 forGroup:channel2];
//                                        NSLog(@"1. Avg Power Level: %f, peak: %f",pwl1,peak1);
                                        
                                        if (!time1) {
                                            if (peak1 > -10.f) {
                                                time1 = [NSDate date];
//                                                NSLog(@"Peakk!!: %f",peak1);
                                            }
                                        }
                                        
                                        float pwl2;
                                        float peak2;
                                        [audioController averagePowerLevel:&pwl2 peakHoldLevel:&peak2 forGroup:channel1];
                                       // NSLog(@"1. Avg Power Level: %f, peak: %f",pwl2,peak2);
                                        
                                        if (time1) {
                                            if (peak2 > -10.f) {
                                                time2 = [NSDate date];
                                                NSTimeInterval delay = [time2 timeIntervalSinceDate:time1];
                                                if (delay < 0.06f) {
                                                    NSLog(@"Delay: %f", delay);
                                                } else {
                                                    NSLog(@"Error, Delay: %f", delay);
                                                }

                                                time1 = nil;
                                                time2 = nil;
                                            }
                                        }

                                    }];
    [audioController addInputReceiver:receiver];
    
    NSError *err = nil;
    if (![audioController start:&err]) {
        NSLog(@"Error starting TAAE: %@",err.localizedDescription);
    } else {
        NSLog(@"TAAE successfully started");
    }
}

@end
