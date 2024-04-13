//
//  MyXfireOverlay.m
//  iFire
//
//  Created by Florian on 18.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MyXfireOverlay.h"


@implementation MyXfireOverlay

+ (void)receivedMessage:(NSString *)message fromUser:(NSString *)user
{
	NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:user, @"Username", message, @"Message", nil];
	[dnc postNotificationName:@"ReceivedMessage" object:nil userInfo:dict];
	NSLog(@"Noti posted!");
}

@end
