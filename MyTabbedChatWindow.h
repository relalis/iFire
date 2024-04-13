//
//  MyTabbedChatWindow.h
//  iFire
//
//  Created by Florian on 04.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MyXfireController;

@interface MyTabbedChatWindow : NSObject {
	IBOutlet NSWindow *chat;
	IBOutlet NSTextView *textField;
	IBOutlet NSTextField *typingNotification;
	IBOutlet NSTextField *inputField;
	IBOutlet NSPopUpButton *smileyMenu;
	MyXfireController *controller;
	NSArray*    topLevelObjs;
	NSString *user;
	bool open;
	int counter, oldRange, oldURLRange;
}

- (id)initWithController:(MyXfireController *)contrl;
- (void)run;

@end
