//
//  MyChatWindow.h
//  Xfire Mac
//
//  Created by Florian Bethke on 30.10.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MyXfireController;

@interface MyChatWindow : NSObject {
	IBOutlet NSWindow *chat;
	IBOutlet NSTextView *textField;
	IBOutlet NSTextField *typingNotification;
	IBOutlet NSTextField *inputField;
	IBOutlet NSPopUpButton *smileyMenu;
	MyXfireController *controller;
	NSRange timestampRange;
	NSArray*    topLevelObjs;
	NSString *user;
	bool open;
	int typing;
	int counter, oldRange, oldURLRange;
}
- (id)initWithController:(MyXfireController *)contrl andUsername:(NSString *)username;
- (void)run;
- (void)setTitle:(NSString *)title;
- (void)addString:(NSString *)string;
- (void)sendMessage:(id)sender;
- (NSString *)title;
- (NSString *)username;
- (bool)windowOpen;
- (void)setIsTyping;
- (void)update;
- (void)searchEmoticons;
- (void)searchURLS;
- (void)insertEmoticon:(NSImage *)smiley inRange:(NSRange)range;
- (NSTextStorage *)textStorage;
@end
