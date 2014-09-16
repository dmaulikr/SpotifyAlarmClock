//
//  Option.m
//  SpotifyAlarmClock
//
//  Created by Niels Vroegindeweij on 16-09-14.
//  Copyright (c) 2014 Niels Vroegindeweij. All rights reserved.
//

#import "Option.h"

@implementation Option
@synthesize label;
@synthesize selected;


- initWithLabel:(NSString *)lb selected:(BOOL)sl
{
    self = [super init];
    if (self) {
        self.label = lb;
        self.selected = sl;
    }
    return self;
}

@end
