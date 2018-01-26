//
//  SGGLTextureUploader.h
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGGLDefines.h"

typedef NS_ENUM(NSUInteger, SGGLTextureType)
{
    SGGLTextureTypeUnknown,
    SGGLTextureTypeYUV420P,
    SGGLTextureTypeNV12,
};

@interface SGGLTextureUploader : NSObject

- (BOOL)uploadWithType:(SGGLTextureType)type data:(uint8_t **)data size:(SGGLSize)size;

@end