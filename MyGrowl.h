//
//  MyGrowl.h
//  iFire
//
//  Created by Florian on 03.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@class MyXfireController;

@interface MyGrowl : NSObject <GrowlApplicationBridgeDelegate> {
		MyXfireController *controller;
}

- (id)initWithController:(MyXfireController *)contrl;
- (NSDictionary *) registrationDictionaryForGrowl;
- (void) growlNotificationWasClicked:(id)clickContext;
- (void)postNotificationWithTitle:(NSString *)title andDescription:(NSString *)description andName:(NSString *)name clickContext:(id)click;

@end
