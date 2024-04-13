//
//  MyXfireGames.h
//  Xfire Mac Client
//
//  Created by Florian Bethke on 27.10.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MyXfireGames : NSObject {
	NSWorkspace *workspace;
	NSMutableDictionary *games, *shortGames;
	NSArray *macGames;
	NSMutableArray *sortedMacGames;
	NSMutableArray *sortedPCGames;
	NSMutableArray *installedGames;
	NSMutableDictionary *pcIcons;
}
- (void)makeArray;
- (void)sortGames;
- (void)parseGameFile;
- (BOOL)startGame:(NSString *)game withArguments:(NSArray *)arguments;
- (BOOL)startGame:(NSString *)game withAdress:(NSString *)adress;
- (BOOL)startGame:(NSString *)game;
- (BOOL)macGameExists:(NSString *)game;
- (BOOL)macGameInstalled:(NSString *)game;
- (BOOL)teamSpeakRunning;
- (NSString *)getNameForKey:(NSString *)key;
- (NSString *)getKeyForShortName:(NSString *)game;
- (NSString *)getKeyForGame:(NSString *)game;
- (NSString *)getKeyForMacGame:(NSString *)game;
- (NSString *)getMacGameForKey:(NSString *)key;
- (NSString *)getLaunchArgumentsForMacGame:(NSString *)game;
- (NSString *)getAppendingStringForMacGame:(NSString *)game;
- (NSString *)getGamePortForMacGame:(NSString *)game;
- (NSString *)getGameServerForMacGame:(NSString *)game;
- (NSNumber *)gameRunning;
- (NSNumber *)isApplicationRunning:(NSArray *)appName;
- (NSImage *)getIconForGame:(NSString *)gameNumber;
- (NSImage *)getIconForPCGame:(NSString *)gameNumber;
- (NSMutableArray *)getMacGames;
- (NSMutableArray *)getPCGames;
- (NSMutableArray *)getInstalledGames;
@end
