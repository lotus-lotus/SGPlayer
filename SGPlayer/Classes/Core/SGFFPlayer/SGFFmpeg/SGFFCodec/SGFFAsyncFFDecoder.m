//
//  SGFFAsyncFFDecoder.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAsyncFFDecoder.h"
#import "SGFFError.h"

@interface SGFFAsyncFFDecoder ()

@property (nonatomic, assign) AVCodecContext * codecContext;

@end

@implementation SGFFAsyncFFDecoder

+ (AVCodecContext *)ccodecContextWithCodecpar:(AVCodecParameters *)codecpar timebase:(CMTime)timebase
{
    AVCodecContext * codecContext = avcodec_alloc_context3(NULL);
    if (!codecContext)
    {
        return nil;
    }
    
    int result = avcodec_parameters_to_context(codecContext, codecpar);
    NSError * error = SGFFGetError(result);
    if (error)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    av_codec_set_pkt_timebase(codecContext, (AVRational){(int)timebase.value, (int)timebase.timescale});
    
    AVCodec * codec = avcodec_find_decoder(codecContext->codec_id);
    if (!codec)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    codecContext->codec_id = codec->id;
    
    result = avcodec_open2(codecContext, codec, NULL);
    error = SGFFGetError(result);
    if (error)
    {
        avcodec_free_context(&codecContext);
        return nil;
    }
    
    return codecContext;
}

- (BOOL)open
{
    self.codecContext = [SGFFAsyncFFDecoder ccodecContextWithCodecpar:self.codecpar timebase:self.timebase];
    if (self.codecContext)
    {
        return [super open];
    }
    return NO;
}

- (void)close
{
    [super close];
    if (self.codecContext)
    {
        avcodec_close(self.codecContext);
        self.codecContext = nil;
    }
}

- (void)doFlushCodec
{
    [super doFlushCodec];
    if (self.codecContext)
    {
        avcodec_flush_buffers(self.codecContext);
    }
}

- (NSArray <id <SGFFFrame>> *)doDecode:(SGFFPacket *)packet error:(NSError * __autoreleasing *)error
{
    int result = avcodec_send_packet(self.codecContext, packet.corePacket);
    if (result < 0)
    {
        return nil;
    }
    NSMutableArray * array = nil;
    while (result >= 0)
    {
        id <SGFFFrame> frame = [self fetchReuseFrame];
        NSAssert(frame, @"Fecth frame failed");
        result = avcodec_receive_frame(self.codecContext, frame.coreFrame);
        if (result < 0)
        {
            if (result == AVERROR(EAGAIN) || result == AVERROR_EOF) {
                
            } else {
                * error = SGFFGetErrorCode(result, SGFFErrorCodeCodecReceiveFrame);
            }
            [frame unlock];
            break;
        }
        else
        {
            if (!array) {
                array = [NSMutableArray array];
            }
            [frame fillWithTimebase:self.timebase];
            [array addObject:frame];
        }
    }
    return array;
}

- (__kindof id <SGFFFrame>)fetchReuseFrame
{
    return nil;
}

@end