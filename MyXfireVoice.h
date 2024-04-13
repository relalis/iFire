//
//  MyXfireVoice.h
//  iFire
//
//  Created by Florian on 13.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MyXfireVoice : NSObject {

}

+(bool)teamspeakIsInstalled;
+(bool)VentriloIsInstalled;
+(bool)mumbleIsInstalled;
+(NSString *)teamspeakPath;
+(void)launchTeamspeakWithAdress:(NSString *)adress;
+(NSImage *)getTSIcon;
+ (NSString *)voiceSoftwareRunning;
@end
