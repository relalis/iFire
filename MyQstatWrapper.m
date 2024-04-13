//
//  MyQstatWrapper.m
//  iFire
//
//  Created by Florian on 02.01.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MyQstatWrapper.h"


@implementation MyQstatWrapper

- (id)init {
	if (self = [super init]) {
		qstatPath = [[[NSBundle mainBundle] pathForResource:@"qstat" ofType:@""] retain];
	//	NSLog(@"%@", [self getInformationForGameServer:@"et.hirntot.org" WithServerType:@"-rws"]);
	}
	return self;
}

- (NSDictionary *)getInformationForGameServer:(NSString *)gameServer WithServerType:(NSString *)type
{	
	if(!gameServer)
		return nil;
	if(!type)
		return nil;

	NSArray *arguments = [NSArray arrayWithObjects:@"-P",@"-nh",@"-cfg", [[NSBundle mainBundle] pathForResource:@"qstat" ofType:@"cfg"], type, gameServer, nil];
	NSTask *qstat=[[NSTask alloc] init];
	NSPipe *pipe=[[NSPipe alloc] init];
    NSFileHandle *handle;
    
    [qstat setLaunchPath:qstatPath];
    [qstat setArguments:arguments];
	[qstat setStandardOutput:pipe];
    handle=[pipe fileHandleForReading];
    [qstat launch];
	
	NSString *string = [[[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding] autorelease];
	
	NSScanner *scan = [NSScanner scannerWithString:string];
	NSString *playerNumber, *player, *map, *ping, *name, *shortPlayer, *score;
	NSMutableArray *playerInfo = [[NSMutableArray alloc] init], *scores = [[NSMutableArray alloc] init];
	
	[scan scanUpToString:@" " intoString:nil];
	[scan scanUpToString:@" " intoString:&playerNumber];
	if([playerNumber isEqualToString:@"ERROR"] || [playerNumber isEqualToString:@"no"] || [playerNumber isEqualToString:@"DOWN\n"])
		return nil;
	[scan scanUpToString:@" " intoString:nil];
	[scan scanUpToString:@" " intoString:&map];
	[scan scanUpToString:@" " intoString:&ping];
	[scan scanUpToString:@" " intoString:nil];	//Ignore
	[scan scanUpToString:@" " intoString:nil];	//Ignore
	[scan scanUpToString:@"\n" intoString:&name];

	while(![scan isAtEnd]){
		[scan scanUpToString:@"\n" intoString:&player];
		NSScanner *scan2 = [NSScanner scannerWithString:player];
		[scan2 scanUpToString:@"ms " intoString:nil];
		[scan2 scanString:@"ms " intoString:nil];
		[scan2 scanUpToString:@"" intoString:&shortPlayer];
		[playerInfo addObject:shortPlayer];
		NSScanner *scan3 = [NSScanner scannerWithString:player];
		[scan3 scanUpToString:@" frags" intoString:&score];
		[scores addObject:score];
	}
	
	NSDictionary *dict = [[[NSDictionary alloc] initWithObjectsAndKeys:name, @"Name", playerNumber, @"Playernumber", map, @"Map", ping, @"Ping", playerInfo, @"Playerinfo", scores, @"Score", nil] autorelease];

	[qstat release];
	[pipe release];
	
	return dict;
}

@end
