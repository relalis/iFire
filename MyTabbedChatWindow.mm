//
//  MyTabbedChatWindow.m
//  iFire
//
//  Created by Florian on 04.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MyTabbedChatWindow.h"
#import "MyXfireController.h"
#import "MyXfireWrapper.h"
#import "MySmiley.h"

@implementation MyTabbedChatWindow

- (id)initWithController:(MyXfireController *)contrl
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"TabChatWindow" owner:self];
		
		[chat setDelegate:self];
		open = false;
		controller = contrl;
		[textField setDelegate:self];
		oldRange = 0;
		
		NSArray *emoticonImages = [[controller smileyPointer] getEmoticonImages];
		int i;
		for(i=0;i<[emoticonImages count];i++){
			[smileyMenu addItemWithTitle:@""];
			[[smileyMenu lastItem] setImage:[emoticonImages objectAtIndex:i]];
		}
		
		[inputField setDelegate:self];
		NSLog(@"%f, %f", [chat frame].origin.x, [chat frame].origin.y);
		NSPoint point;
		point.x = [chat frame].origin.x +21;
		point.y = [chat frame].origin.y +245;
		
		[chat cascadeTopLeftFromPoint:point];
	}
	return self;
}

- (void)run
{
	[chat makeKeyAndOrderFront:self];
	open = true;
}

@end
