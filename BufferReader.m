//
//  BufferReader.m
//  FaceDetectionProcessor
//
//  Created by Vitaliy Malakhovskiy on 7/3/14.
//  Copyright (c) 2014 Vitaliy Malakhovskiy. All rights reserved.
//

#import "BufferReader.h"
#import <AVFoundation/AVFoundation.h>

@interface BufferReader () {
    struct DelegateMethods {
        unsigned int didGetNextVideoSample   : 1;
        unsigned int didGetErrorRedingSample : 1;
        unsigned int didFinishReadingSample  : 1;
    } _delegateMethods;
}
@end

@implementation BufferReader

- (instancetype)initWithDelegate:(id<BufferReaderDelegate>)delegate {
    if (self = [super init]) {
        _delegate = delegate;
        _delegateMethods.didGetNextVideoSample = [self.delegate respondsToSelector:@selector(bufferReader:didGetNextVideoSample:)];
        _delegateMethods.didGetErrorRedingSample = [self.delegate respondsToSelector:@selector(bufferReader:didGetErrorRedingSample:)];
        _delegateMethods.didFinishReadingSample = [self.delegate respondsToSelector:@selector(bufferReader:didFinishReadingAsset:)];
    }
    return self;
}

- (void)startReadingAsset:(AVAsset *)asset error:(NSError *)error {
    
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    if (error) {
        return;
    }

    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (!videoTracks.count) {
        error = [NSError errorWithDomain:@"AVFoundation error" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"Can't read video track" }];
        return;
    }

    AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
    AVAssetReaderTrackOutput *trackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:CVPixelFormatOutputSettings()];
    [reader addOutput:trackOutput];
    [reader startReading];

    CMSampleBufferRef buffer = NULL;
    BOOL continueReading = YES;
    while (continueReading) {
        AVAssetReaderStatus status = [reader status];
        switch (status) {
            case AVAssetReaderStatusUnknown: {
            } break;
            case AVAssetReaderStatusReading: {
                buffer = [trackOutput copyNextSampleBuffer];

                if (!buffer) {
                    break;
                }

                if (_delegateMethods.didGetNextVideoSample) {
                    [self.delegate bufferReader:self didGetNextVideoSample:buffer];
                }
            } break;
            case AVAssetReaderStatusCompleted: {
                if (_delegateMethods.didFinishReadingSample) {
                    [self.delegate bufferReader:self didFinishReadingAsset:asset];
                }
                continueReading = NO;
            } break;
            case AVAssetReaderStatusFailed: {
                if (_delegateMethods.didFinishReadingSample) {
                    [self.delegate bufferReader:self didFinishReadingAsset:asset];
                }
                [reader cancelReading];
                continueReading = NO;
            } break;
            case AVAssetReaderStatusCancelled: {
                continueReading = NO;
            } break;
        }
        if (buffer) {
            CMSampleBufferInvalidate(buffer);
            CFRelease(buffer);
            buffer = NULL;
        }
    }
}

NS_INLINE NSDictionary *CVPixelFormatOutputSettings() {
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] };
}

@end