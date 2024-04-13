//
//  MyXfireGames.m
//  Xfire Mac Client
//
//  Created by Florian Bethke on 27.10.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MyXfireGames.h"


@implementation MyXfireGames

- (id)init
{
	if(self == [super init]){
		workspace = [NSWorkspace sharedWorkspace];
		NSString *filePath = [NSString stringWithFormat:@"%@/MacGames", [[NSBundle mainBundle] resourcePath]];
		macGames = [[NSArray alloc] initWithContentsOfFile:filePath];
		sortedMacGames = [[NSMutableArray alloc] init];
		installedGames = [[NSMutableArray alloc] init];
		[self makeArray];
		
		
/*		NSString *iconPath = [NSString stringWithFormat:@"%@/Xfire Icons/Icons.rc", [[NSBundle mainBundle] resourcePath]];
		NSString *icons = [NSString stringWithContentsOfFile:iconPath];
		
		NSScanner *scan = [NSScanner scannerWithString:icons];
		NSString *iconName, *fileName;
		pcIcons = [[NSMutableDictionary alloc] init];

		while(![scan isAtEnd]){
			[scan scanUpToString:@"XF_"intoString:nil];
			[scan scanString:@"XF_"intoString:nil];
			[scan scanUpToString:@".ICO ICONS "intoString:&iconName];
			[scan scanUpToString:@"\""intoString:nil];
			[scan scanString:@"\""intoString:nil];
			[scan scanUpToString:@"\""intoString:&fileName];
			[pcIcons setObject:fileName forKey:iconName];
		}
*/	}
	return self;
}

- (void)dealloc
{
	[macGames release];
	[sortedMacGames release];
	[sortedPCGames release];
	[installedGames release];
	[super dealloc];
}

- (void)makeArray
{
	int i;
	for(i=0;i<[macGames count];i++){
		if([self macGameInstalled:[[macGames objectAtIndex:i] objectForKey:@"Game"]])
			[installedGames addObject:[[macGames objectAtIndex:i] objectForKey:@"Game"]];
	}
}

- (void)sortGames
{
	/* Mac Games */
	int i;
	for(i=0;i<[macGames count];i++){
		[sortedMacGames addObject:[[macGames objectAtIndex:i]  objectForKey:@"Game"]];
	}
	[sortedMacGames sortUsingSelector:@selector(compare:)];
	
	/* PC Games */
	sortedPCGames = [[NSMutableArray alloc] initWithArray:[games allValues]];
	[sortedPCGames sortUsingSelector:@selector(compare:)];
	
	/* Installed Games */
	[installedGames sortUsingSelector:@selector(compare:)];
}

- (void)parseGameFile
{
	NSString *filePath = [NSString stringWithFormat:@"%@/games.txt", [[NSBundle mainBundle] resourcePath]];
	NSString *gamesFile = [NSString stringWithContentsOfFile:filePath];
	NSString *gameNumber;
	NSString *game, *shortGame;
	NSScanner *scan = [NSScanner scannerWithString:gamesFile];
	NSRange range;
	range.location	= 4;
	range.length	= 2;
	games = [[NSMutableDictionary alloc] init];
	shortGames = [[NSMutableDictionary alloc] init];
	
	while(![scan isAtEnd]){
		[scan scanUpToString:@"["intoString:nil];
		[scan scanString:@"["intoString:nil];
		[scan scanUpToString:@"]"intoString:&gameNumber];
		if([gameNumber isEqualToString:@"0"]){
			[scan scanUpToString:@"\n[" intoString:nil];
		//	[scan scanUpToString:@"["intoString:nil];
			[scan scanString:@"["intoString:nil];
			[scan scanUpToString:@"]"intoString:&gameNumber];
		}
		if([gameNumber length] > 4){
			NSMutableString *mutStr = [[NSMutableString alloc] initWithString:gameNumber];
			[mutStr deleteCharactersInRange:range];
			gameNumber = mutStr;
		}
		
		if([gameNumber isEqualToString:@"3_1"])
			gameNumber = @"3";
		
		[scan scanUpToString:@"LongName=" intoString:nil];
		[scan scanString:@"LongName=" intoString:nil];
		[scan scanUpToString:@"ShortName=" intoString:&game];
		[scan scanString:@"ShortName=" intoString:nil];
		[scan scanUpToString:@"\n" intoString:&shortGame];
		[games setObject:game forKey:gameNumber];
		NSString *shortGame2 = [[shortGame substringToIndex:[shortGame length] -1] uppercaseString];
		[shortGames setObject:shortGame2 forKey:gameNumber];
	}
	[self sortGames];
}

- (BOOL)startGame:(NSString *)game withArguments:(NSArray *)arguments
{
	NSMutableString *fullName = [NSMutableString stringWithString:game];
	[fullName appendString:@".app"];
	NSMutableString *path = [NSMutableString stringWithString:[workspace fullPathForApplication:fullName]];
	[path appendString:@"/Contents/MacOS/"];
	[path appendString:game];
	[NSTask launchedTaskWithLaunchPath:path arguments:arguments];
	return TRUE; //TODO!!
}

- (BOOL)startGameWithAppendingString:(NSString *)game withArguments:(NSArray *)arguments
{
	NSMutableString *fullName = [NSMutableString stringWithString:game];
	NSMutableString *path = [NSMutableString stringWithString:[workspace fullPathForApplication:fullName]];
	[path appendString:@"/Contents/MacOS/"];
	NSMutableString *gameWithoutAppendingString = [NSMutableString stringWithString:game];
	[gameWithoutAppendingString replaceOccurrencesOfString:[self getAppendingStringForMacGame:game] withString:@"" options:nil range:NSMakeRange(0, [gameWithoutAppendingString length])];
	[path appendString:gameWithoutAppendingString];
	NSLog(@"%@", path);
	[NSTask launchedTaskWithLaunchPath:path arguments:arguments];
	return TRUE; //TODO!!
}

- (BOOL)startGame:(NSString *)game withAdress:(NSString *)adress
{	
	NSString *theGame = [NSString stringWithString:game];

	if([self getLaunchArgumentsForMacGame:game]){
		if([[self getLaunchArgumentsForMacGame:game] isEqualToString:@"NSServices"]){
			if(adress){
				NSPasteboard *paste = [NSPasteboard pasteboardWithName:@"paste"];
				[paste declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: nil];
				[paste setString:adress forType:NSStringPboardType];
				NSString *str = [NSString stringWithFormat:@"%@/Connect To Server", game];
				NSPerformService(str, paste);
			}
		}
		else {
			NSMutableArray *arguements = [[NSMutableArray alloc] init];
			if(![self macGameExists:game])
				return FALSE;
		
			if(adress){
				[arguements addObject:[self getLaunchArgumentsForMacGame:game]];
				[arguements addObject:adress];
			}
			if([self getAppendingStringForMacGame:game])
				return [self startGameWithAppendingString:theGame withArguments:arguements];
			else
				return [self startGame:theGame withArguments:arguements];
			}
	}
	else
		return [workspace launchApplication:theGame];
		
	return true;
}

- (BOOL)startGame:(NSString *)game
{
	return [workspace launchApplication:game];
}

- (BOOL)macGameExists:(NSString *)game
{
	int i;
	for(i=0;i<[macGames count];i++){
		if([[[macGames objectAtIndex:i] objectForKey:@"Game"] isEqualToString:game])
			return TRUE;
	}
	return FALSE;
}

- (BOOL)macGameInstalled:(NSString *)game
{
	
	if([workspace fullPathForApplication:game])
		return true;
	else
		return false;
}

- (BOOL)teamSpeakRunning
{
	NSArray *apps = [workspace launchedApplications];
	int i;
	for(i=0;i<[apps count];i++){
		if([[[apps objectAtIndex:i] objectForKey:@"NSApplicationName"] isEqualToString:@"TeamSpeex"])
			return TRUE;
	}

	return FALSE;
}

- (NSString *)getShortNameForKey:(NSString *)key
{
	return [shortGames objectForKey:key];
}

- (NSString *)getNameForKey:(NSString *)key
{
	return [games objectForKey:key];
}

- (NSString *)getKeyForShortName:(NSString *)game
{
	return [[shortGames allKeysForObject:game] objectAtIndex:0];
}

- (NSString *)getKeyForGame:(NSString *)game
{
	return [[games allKeysForObject:game] objectAtIndex:0];
}

- (NSString *)getKeyForMacGame:(NSString *)game
{
	int i;
	for(i=0;i<[macGames count];i++){
		if([[[macGames objectAtIndex:i] objectForKey:@"Game"] isEqualToString:game])
			return [[macGames objectAtIndex:i] objectForKey:@"GameID"];
	}
	return nil;
}

- (NSString *)getMacGameForKey:(NSString *)key
{
	int i;
	for(i=0;i<[macGames count];i++){
		if([[[macGames objectAtIndex:i] objectForKey:@"GameID"] isEqualToString:key])
			return [[macGames objectAtIndex:i] objectForKey:@"Game"];
	}
	return nil;
}

- (NSString *)getLaunchArgumentsForMacGame:(NSString *)game
{
	int i;
	for(i=0;i<[macGames count];i++){
		if([[[macGames objectAtIndex:i] objectForKey:@"Game"] isEqualToString:game])
			return [[macGames objectAtIndex:i] objectForKey:@"LaunchArguments"];
	}
	return nil;
}

- (NSString *)getAppendingStringForMacGame:(NSString *)game
{
	int i;
	for(i=0;i<[macGames count];i++){
		if([[[macGames objectAtIndex:i] objectForKey:@"Game"] isEqualToString:game])
			return [[macGames objectAtIndex:i] objectForKey:@"AppendingString"];
	}
	return nil;
}

- (NSString *)getGamePortForMacGame:(NSString *)game
{
	int i;
	for(i=0;i<[macGames count];i++){
		if([[[macGames objectAtIndex:i] objectForKey:@"Game"] isEqualToString:game])
			return [[macGames objectAtIndex:i] objectForKey:@"GamePort"];
	}
	return nil;
}

- (NSString *)getGameServerForMacGame:(NSString *)game
{
	int i;
	for(i=0;i<[macGames count];i++){
		if([[[macGames objectAtIndex:i] objectForKey:@"Game"] isEqualToString:game])
			return [[macGames objectAtIndex:i] objectForKey:@"GameServer"];
	}
	return nil;
}

- (NSNumber *)gameRunning
{
	return [self isApplicationRunning:macGames];
}

- (NSNumber *)isApplicationRunning:(NSArray *)appName
{
	NSArray *apps = [workspace launchedApplications];
	int i, j;
	for(i=0;i<[apps count];i++){
		for(j=0;j<[appName count];j++){
		/*	if([[appName objectAtIndex:j] objectForKey:@"AppendingString"]){
				NSMutableString *game = [NSMutableString stringWithString:[[appName objectAtIndex:j] objectForKey:@"Game"]];
				[game replaceOccurrencesOfString:@".app" withString:@"" options:nil range:NSMakeRange(0, [game length])];
				if([[[apps objectAtIndex:i] objectForKey:@"NSApplicationName"] isEqualToString:game])
					return [[appName objectAtIndex:j] objectForKey:@"GameID"];
			}
			if([[appName objectAtIndex:j] objectForKey:@"SecondName"]){
				if([[[apps objectAtIndex:i] objectForKey:@"NSApplicationName"] isEqualToString:[[appName objectAtIndex:j] objectForKey:@"SecondName"]])
					return [[appName objectAtIndex:j] objectForKey:@"GameID"];
			}
			if([[[apps objectAtIndex:i] objectForKey:@"NSApplicationName"] isEqualToString:[[appName objectAtIndex:j] objectForKey:@"Game"]])
				return [[appName objectAtIndex:j] objectForKey:@"GameID"];
			*/
			if([[[[apps objectAtIndex:i] objectForKey:@"NSApplicationPath"] lastPathComponent] isEqualToString:[NSString stringWithFormat:@"%@.app", [[appName objectAtIndex:j] objectForKey:@"Game"]]])
				return [[appName objectAtIndex:j] objectForKey:@"GameID"];
		}
	}
	return nil;

}

- (NSImage *)getIconForGame:(NSString *)gameNumber
{
	return [workspace iconForFile:[workspace fullPathForApplication:[self getMacGameForKey:gameNumber]]];
}

- (NSImage *)getIconForPCGame:(NSString *)gameNumber
{
	NSString *game = [self getShortNameForKey:gameNumber];
	NSString *path = [NSString stringWithFormat:@"%@/Xfire Icons/XF_%@.ICO", [[NSBundle mainBundle] resourcePath], game];
	return [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
}

- (NSMutableArray *)getMacGames
{
	return sortedMacGames;
}

- (NSMutableArray *)getPCGames
{
	return sortedPCGames;
}

- (NSMutableArray *)getInstalledGames
{
	return installedGames;
}

@end
