//
//  BufferReader.h
//  FaceDetectionProcessor
//
//  Created by Vitaliy Malakhovskiy on 7/3/14.
//  Copyright (c) 2014 Vitaliy Malakhovskiy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@class AVAsset;
@protocol BufferReaderDelegate;

@interface BufferReader : NSObject
@property (nonatomic, weak) id <BufferReaderDelegate> delegate;

- (instancetype)initWithDelegate:(id <BufferReaderDelegate>)delegate;
- (void)startReadingAsset:(AVAsset *)asset error:(NSError *)error;
@end

@protocol BufferReaderDelegate <NSObject>
- (void)bufferReader:(BufferReader *)reader didFinishReadingAsset:(AVAsset *)asset;
- (void)bufferReader:(BufferReader *)reader didGetNextVideoSample:(CMSampleBufferRef)bufferRef;
- (void)bufferReader:(BufferReader *)reader didGetErrorRedingSample:(NSError *)error;
@end
