//
//  MyXfireUpdater.h
//  iFire
//
//  Created by Florian Bethke on 05.03.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MyXfireUpdater : NSObject {
	NSURL *downloadURL;
}

- (void)checkForUpdates;
- (BOOL)checkForUpdatesWithWindow:(NSWindow *)window andInfoField:(NSTextField *)info andNotesView:(NSTextView *)notes;
- (NSURL *)getURL;

@end
