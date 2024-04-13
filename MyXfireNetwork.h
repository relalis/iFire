//
//  MyXfireNetwork.h
//  Xfire Mac
//
//  Created by Florian Bethke on 16.01.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MyXfireNetwork : NSObject {
			
			NSTask *lsof;
			NSPipe *pipe;
			NSFileHandle *handle;
			NSString *port;
			bool running;
			bool terminated;
			bool ready;
}

- (NSString *)getLANAddress;
- (NSString *)getPortForGame:(NSString *)game;
- (BOOL)activeInternetConnection;
@end
