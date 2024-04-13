//
//  MyTableView.h
//  iFire
//
//  Created by Florian on 05.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MyXfireController;

@interface MyTableView : NSTableView {
		MyXfireController *controller;
		bool overView;
		bool showTooltips;
		NSTrackingRectTag trackingTag;
}

- (void)setController:(MyXfireController *)contrl;
- (void)enableTooltips;

@end
