//
//  MyXfireVoice.m
//  iFire
//
//  Created by Florian on 13.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MyXfireVoice.h"


@implementation MyXfireVoice

+ (bool)teamspeakIsInstalled
{
	if([[NSWorkspace sharedWorkspace] fullPathForApplication:@"TeamSpeex"])
		return true;
	else
		return false;
}

+ (bool)VentriloIsInstalled
{
	if([[NSWorkspace sharedWorkspace] fullPathForApplication:@"Ventrilo"])
		return true;
	else
		return false;
}

+ (bool)mumbleIsInstalled
{
	if([[NSWorkspace sharedWorkspace] fullPathForApplication:@"Mumble"])
		return true;
	else
		return false;
}

+ (NSString *)teamspeakPath
{
	return [[NSWorkspace sharedWorkspace] fullPathForApplication:@"TeamSpeex"];
}

+ (void)launchTeamspeakWithAdress:(NSString *)adress
{
	NSString *urlstring = [NSString stringWithFormat:@"teamspeak://%@", adress];
	NSURL *ts2url = [NSURL URLWithString:urlstring];
	[[NSWorkspace sharedWorkspace] openURL:ts2url];
}

+ (NSImage *)getTSIcon
{
	return [[NSWorkspace sharedWorkspace] iconForFile:[self teamspeakPath]];
}

+ (NSString *)voiceSoftwareRunning
{
	NSArray *apps = [[NSWorkspace sharedWorkspace] launchedApplications];
	int i;
	for(i=0;i<[apps count];i++){
		if([[[apps objectAtIndex:i] objectForKey:@"NSApplicationName"] isEqualToString:@"TeamSpeex"])
			return @"TeamSpeak";
		else if([[[apps objectAtIndex:i] objectForKey:@"NSApplicationName"] isEqualToString:@"Ventrilo"])
			return @"Ventrilo";
		else if([[[apps objectAtIndex:i] objectForKey:@"NSApplicationName"] isEqualToString:@"Mumble"])
			return @"Mumble";	
	}
	
	return nil;
}
												

@end
