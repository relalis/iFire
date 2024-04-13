//
//  MyGrowl.m
//  iFire
//
//  Created by Florian on 03.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MyGrowl.h"
#import "MyXfireController.h"


@implementation MyGrowl

- (id)init
{
	if (self = [super init]) {
		[GrowlApplicationBridge setGrowlDelegate:self];	
	}
	return self;
}

- (id)initWithController:(MyXfireController *)contrl
{
	if (self = [super init]) {
		[GrowlApplicationBridge setGrowlDelegate:self];		
		controller = contrl;
	}
	return self;
}

- (NSDictionary *) registrationDictionaryForGrowl
{
	NSArray *names = [NSArray arrayWithObjects:NSLocalizedString(@"msgSent", @""),NSLocalizedString(@"authRequest", @""),NSLocalizedString(@"contactOff", @""), NSLocalizedString(@"contactOn", @""), NSLocalizedString(@"nowPlaying", @""), nil];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:names, GROWL_NOTIFICATIONS_ALL, names, GROWL_NOTIFICATIONS_DEFAULT, nil];

	return dict;
}

- (void) growlNotificationWasClicked:(id)clickContext
{
	NSLog(@"%@", clickContext);
	[controller openChatWindow:clickContext];
}

- (void)postNotificationWithTitle:(NSString *)title andDescription:(NSString *)description andName:(NSString *)name clickContext:(id)click
{
	[GrowlApplicationBridge	notifyWithTitle:title description:description notificationName:name iconData:nil priority:0 isSticky:NO clickContext:click];
}

@end
