//
//  MyXfireUpdater.m
//  iFire
//
//  Created by Florian Bethke on 05.03.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MyXfireUpdater.h"


@implementation MyXfireUpdater

- (void)checkForUpdates
{
//	NSURL *url = [NSURL URLWithString:@"http://xfirebugs.infusion-soft.de/updates"];
	NSURL *url = [NSURL URLWithString:@"http://ifire.games4mac.de/Updates/updates"];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:url];
	float currentVersion = [[[NSUserDefaults standardUserDefaults] stringForKey:@"Version"] floatValue];
	float newVersion = [[dict objectForKey:@"Version"] floatValue];
	if(newVersion > currentVersion){
		NSAlert *myAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"updateShort", @"") defaultButton:NSLocalizedString(@"download", @"") alternateButton:NSLocalizedString(@"cancel", @"") otherButton:NSLocalizedString(@"notes", @"") informativeTextWithFormat:NSLocalizedString(@"update", @""), newVersion, currentVersion];
		int result = [myAlert runModal];
		if(result == 1)
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[dict objectForKey:@"URL"]]];	
		else if(result == 0)
			NSLog(@"Cancled");
		else
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[dict objectForKey:@"Notes"]]];	
	}
}

- (BOOL)checkForUpdatesWithWindow:(NSWindow *)window andInfoField:(NSTextField *)info andNotesView:(NSTextView *)notes
{
//	NSURL *url = [NSURL URLWithString:@"http://xfirebugs.infusion-soft.de/updates"];
	NSURL *url = [NSURL URLWithString:@"http://ifire.games4mac.de/Updates/updates"];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:url];
	float currentVersion = [[[NSUserDefaults standardUserDefaults] stringForKey:@"Version"] floatValue];
	float newVersion = [[dict objectForKey:@"Version"] floatValue];
	downloadURL = [NSURL URLWithString:[dict objectForKey:@"URL"]];
	if(newVersion > currentVersion){
		NSString *str = [NSString stringWithFormat:NSLocalizedString(@"update", @""), [[dict objectForKey:@"Version"] stringValue], [[NSUserDefaults standardUserDefaults] stringForKey:@"Version"]];
		[info setStringValue:str];
	//	NSString *str2 = [NSString stringWithContentsOfURL:[NSURL URLWithString:[dict objectForKey:@"Notes"]]];
		NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[dict objectForKey:@"Notes"]]];
		NSAttributedString *str2 = [[NSAttributedString alloc] initWithRTF:data documentAttributes:nil];
		[[notes textStorage] insertAttributedString:str2 atIndex:0];
		[window makeKeyAndOrderFront:window];
	}
	else
		return false;
	return true;
}

- (NSURL *)getURL
{
	return [NSURL URLWithString:[[NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://ifire.games4mac.de/Updates/updates"]] objectForKey:@"URL"]];
//	return [NSURL URLWithString:[[NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://xfirebugs.infusion-soft.de/updates"]] objectForKey:@"URL"]];
}

@end
