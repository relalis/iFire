//
//  MyQstatWrapper.h
//  iFire
//
//  Created by Florian on 02.01.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MyQstatWrapper : NSObject {
	NSString *qstatPath;

}

- (NSDictionary *)getInformationForGameServer:(NSString *)gameServer WithServerType:(NSString *)type;

@end
