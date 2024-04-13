//
//  MyXfireNetwork.m
//  Xfire Mac
//
//  Created by Florian on 16.01.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MyXfireNetwork.h"


@implementation MyXfireNetwork

- (id)init {
	if (self = [super init]) {
	
	}
	return self;
}

- (void)dealloc
{
	[pipe release];
	[lsof release];
	[super dealloc];
}

- (NSString *)getLANAddress
{
	NSEnumerator *addresses = [[[NSHost currentHost] addresses] objectEnumerator];
	NSString *address;
	while (address = [addresses nextObject]){
		NSArray *arr = [address componentsSeparatedByString:@"."];
		
		if([[arr objectAtIndex:0] isEqualToString:@"192"] && [[arr objectAtIndex:1] isEqualToString:@"168"])
			return address;
		else if([[arr objectAtIndex:0] isEqualToString:@"10"])
			return address;
		else if([[arr objectAtIndex:0] isEqualToString:@"172"])
			return address;
	}
	
	return nil;
}

- (NSString *)getPortForGame:(NSString *)game
{
	if(!running){
		lsof=[[NSTask alloc] init];
		pipe=[[NSPipe alloc] init];
		
		[lsof setLaunchPath:@"/usr/sbin/lsof"];
		[lsof setArguments:[NSArray arrayWithObjects:@"-i",@"-P",@"-M",nil]];
		[lsof setStandardOutput:pipe];
		handle=[pipe fileHandleForReading];
	
		[lsof launch];
    
		[NSThread detachNewThreadSelector:@selector(copyData:) toTarget:self withObject:game];
	
		running = true;
	}
	
	while([lsof isRunning]){
	}
	
	running = false;
	[lsof release];
	[pipe release];
	return port;
}

- (void)copyData:(NSString *)game {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    NSData *data;

    while([data=[handle availableData] length]) {
        NSString *string=[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		NSScanner *scan = [NSScanner scannerWithString:string];
		NSString *myPort;
		NSLock *lock = [NSLock new];
		[lock lock];
		
		[scan scanUpToString:game intoString:nil];
		[scan scanUpToString:@"UDP *:" intoString:nil];
		[scan scanString:@"UDP *:" intoString:nil];
		[scan scanUpToString:@"\n" intoString:&myPort];	
		
		if(![myPort isEqualTo:[NSNull null]])
			port = [[NSString alloc] initWithString:myPort];
		
		[string release];
		[lock unlock];
    }
    [pool release];
}

- (BOOL)activeInternetConnection
{
	NSURL *url = [NSURL URLWithString:@"http://xfirebugs.infusion-soft.de/updates"];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:url];
	if(!dict)
		return false;
		
	return true;
}

@end
