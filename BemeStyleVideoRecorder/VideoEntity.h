//
//  VideoEntity.h
//  BemeStyleVideoRecorder
//
//  Created by Russell Stephens on 7/25/15.
//  Copyright (c) 2015 Russell Stephens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface VideoEntity : NSManagedObject

@property (nonatomic, retain) NSString * timestamp;
@property (nonatomic, retain) NSString * path;

@end
