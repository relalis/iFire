//
//  MyTableView.m
//  iFire
//
//  Created by Florian on 05.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MyTableView.h"
#import "MyXfireController.h"
#import "MyXfireGames.h"

@implementation MyTableView

/* Subclass of NSTableView to select a row with a right-click at the tableview */
- (NSMenu *)menuForEvent:(NSEvent *)theEvent;
{
	int row = [self rowAtPoint: [self convertPoint: [theEvent locationInWindow] fromView: nil]];
	if (row != -1) {
		[self selectRow: row byExtendingSelection: NO];
				
		NSString *gameNumber = [[[[[controller xfirePointer] getBuddyInfo] objectAtIndex:row] objectForKey:@"gameID"] stringValue];

		if(![[controller gamesPointer] macGameInstalled:[[controller gamesPointer] getMacGameForKey:gameNumber]])
			[[[super menu] itemWithTag:1] setEnabled:NO];
		else
			[[[super menu] itemWithTag:1] setEnabled:YES];
			
		[[super menu] setAutoenablesItems:NO];
			
		return [super menu];

	}
	return nil;
}

- (void)setController:(MyXfireController *)contrl
{
	controller = contrl;
	[[self window] setAcceptsMouseMovedEvents:YES];
	trackingTag = [self addTrackingRect:[self frame] owner:self userData:nil assumeInside:NO];
}

- (void)mouseEntered:(NSEvent*)theEvent
{
	overView = YES;
}

- (void)mouseExited:(NSEvent *)theEvent
{
	overView = FALSE;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
//	NSPoint mouseLoc = [ [ self window ] convertScreenToBase:[ NSEvent mouseLocation ] ];
//	if(overView && showTooltips)
//		NSLog(@"%f, %f", mouseLoc.x, mouseLoc.y);
	if(!overView)
		showTooltips = FALSE;
	[super mouseMoved:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent
{
	UInt8 key = [theEvent keyCode];
	switch(key)
	{
		case 125 : // Pfeil hoch
			[super keyDown:theEvent];
			break;
			
		case 126 : // Pfeil runter
			[super keyDown:theEvent];
			break;
		case 53 : // ESC
			[self deselectAll:self];
			[controller updateBuddylist];
			break;
	}
} 

- (BOOL)autosaveTableColumns
{
	return nil;
}

- (void)enableTooltips
{
	showTooltips = TRUE;
}

@end
