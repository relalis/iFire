#import "MyXfireController.h"
#import "MyXfireWrapper.h"
#import "MyXfireGames.h"
#import "MyXfireNetwork.h"
#import "MyChatWindow.h"
#import "MyTabbedChatWindow.h"
#import "MyXfireUpdater.h"
#import "MyGrowl.h"
#import "MyTableView.h"
#import "AGKeychain.h"
#import "MySmiley.h"
#import "MyQstatWrapper.h"
#import "MyXfireVoice.h"

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

#include <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/IOMessage.h>

/********************************************************************************************************/
/* Sleep notifications */
/* Code from http://developer.apple.com/qa/qa2004/qa1340.html */

io_connect_t  root_port;

void
MySleepCallBack( void * refCon, io_service_t service, natural_t messageType, void * messageArgument )
{
    switch ( messageType )
    {

        case kIOMessageCanSystemSleep:
			[(MyXfireController *)refCon logout];
			IOAllowPowerChange( root_port, (long)messageArgument );
            break;

        case kIOMessageSystemWillSleep:
			[(MyXfireController *)refCon logout];
			IOAllowPowerChange( root_port, (long)messageArgument );
            break;

        default:
            break;

    }
}
/********************************************************************************************************/

@implementation MyXfireController

- (void)dealloc
{
	[xfire		release];
	[games		release];
	[net		release];
	[chats		release];
	[updater	release];
	[theIP		release];
	[thePort	release];
	[red		release];
	[green		release];
	[orange		release];
	[smiley		release];
	[super		dealloc];
}

	/****************************/
	/*     Notifications		*/
	/****************************/

- (void)awakeFromNib
{
	[NSApp setDelegate: self] ;
	/* Init all classes */
	
	xfire = [[MyXfireWrapper alloc] initWithController:self];
//	tchat = [[MyTabbedChatWindow alloc] initWithController:self];
	games = [[MyXfireGames alloc] init];
	net = [[MyXfireNetwork alloc] init];
	updater = [[MyXfireUpdater alloc] init];
	qstat = [[MyQstatWrapper alloc] init];
	smiley = [[MySmiley alloc] init];
	growl = [[MyGrowl alloc] initWithController:self];
	[games parseGameFile];
	chats = [[NSMutableArray alloc] init];
	[buddyList setDelegate:self];
	[buddyList setDataSource:self];
	[buddyList setDoubleAction:@selector(doubleclick)];
	[playerinfoTable setDataSource:self];
	[playerinfoTable setDelegate:self];
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	firstNotification = true;
		
	[self registerMyApp];
	
	searchResults = [[NSArray alloc] init];
	theIP = [[NSString alloc] init];
	thePort = [[NSString alloc] init];
	overridedIP = [[NSString alloc] init];
	overridedPort = [[NSString alloc] init];
	overridedVoiceIP = [[NSString alloc] init];
	overridedVoicePort = [[NSString alloc] init];
	sameAddress = 0;
	
	NSTimeInterval timeInterval = 1.0;
	NSTimer *myTimer;
	myTimer = [ [ NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector( update: ) userInfo:nil repeats:YES ] retain ];
	[ [ NSRunLoop currentRunLoop ] addTimer:myTimer forMode:NSEventTrackingRunLoopMode ];
	[ [ NSRunLoop currentRunLoop ] addTimer:myTimer forMode:NSModalPanelRunLoopMode ];
	
	red = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"red" ofType:@""]];
	green = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"green" ofType:@""]];
	orange = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"orange" ofType:@""]];
	haken = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"haken" ofType:@""]];
	kreuz = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"kreuz" ofType:@""]];

	
	NSMutableDictionary *attrs = [[NSMutableDictionary alloc]init];
	NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:8.0];
	[attrs setObject:font forKey:NSFontAttributeName];
//	[attrs setObject:[NSColor blueColor]forKey:NSForegroundColorAttributeName];
	NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:@"View Profile" attributes:attrs];
	[visitProfile setAttributedTitle:attrStr];
	
	[attrStr release];
	[attrs release];
	
//	[games startGame:[games getMacGameForKey:@"4272"]];
	
	myTextCell = [[NSTextFieldCell alloc] init];
	myImageCell = [[NSImageCell alloc] init];
	
	if([prefs boolForKey:@"EnableNetwork"]){
		OSStatus myStatus;
		AuthorizationFlags myFlags=kAuthorizationFlagDefaults;
		AuthorizationRef myAuthorizationRef;

		myStatus=AuthorizationCreate(NULL,kAuthorizationEmptyEnvironment,myFlags,&myAuthorizationRef);

		if(myStatus==errAuthorizationSuccess){
			AuthorizationItem myItems={kAuthorizationRightExecute,0,NULL,0};
			AuthorizationRights myRights={1,&myItems};
			myFlags=kAuthorizationFlagDefaults| kAuthorizationFlagInteractionAllowed| kAuthorizationFlagPreAuthorize| kAuthorizationFlagExtendRights;
			myStatus=AuthorizationCopyRights(myAuthorizationRef,&myRights,NULL,myFlags,NULL);

			if(myStatus==errAuthorizationSuccess){
				FILE*myCommunicationsPipe=NULL;
				//char*myArguments[] ={ "-n","udp", (char*)[[NSNumber numberWithInt:[[NSString stringWithFormat:@"-i %@", [prefs objectForKey:@"NetworkInterface"]] intValue]] charValue]};
				char*myArguments[]={ "-n","udp"};
				
				NSString *tool=@"/usr/sbin/tcpdump";

				myFlags=kAuthorizationFlagDefaults;
				myStatus=AuthorizationExecuteWithPrivileges(myAuthorizationRef,[tool cString],myFlags,myArguments,&myCommunicationsPipe);

				NSFileHandle *myfilehandle=[[NSFileHandle alloc] initWithFileDescriptor:fileno(myCommunicationsPipe)];
				[NSThread detachNewThreadSelector:@selector(copyData:) toTarget:self withObject:myfilehandle];

				fflush(myCommunicationsPipe);
			}
		}
	}
//	NSLog(@"LAN Address: %@", [net getLANAddress]);

	/* Install sleep notification handler */
	IONotificationPortRef  notifyPortRef;   // notification port allocated by IORegisterForSystemPower
    io_object_t            notifierObject;  // notifier object, used to deregister later
    root_port = IORegisterForSystemPower( self, &notifyPortRef, MySleepCallBack, &notifierObject );
    CFRunLoopAddSource( CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notifyPortRef), kCFRunLoopCommonModes );
	
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"tooltest"];
	[toolbar setDelegate:self];
//	[prefWin setToolbar:toolbar];
	NSToolbarItem *testItem = [[NSToolbarItem alloc] initWithItemIdentifier:@"Test"];
	[testItem setImage:red];
	
	toolbarItems = [[NSDictionary alloc] initWithObjectsAndKeys:@"Test", testItem, nil];
//	NSLog(@"%@", toolbarItems);
	
	tabbed = true;

	return;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar 
    itemForItemIdentifier:(NSString *)itemIdentifier
    willBeInsertedIntoToolbar:(BOOL)flag 
{
    return [toolbarItems objectForKey:itemIdentifier];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	NSLog(@"%@", [toolbarItems allKeys]);
    return [toolbarItems allKeys];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [[toolbarItems allKeys] subarrayWithRange:NSMakeRange(0,6)];
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
	[buddyList setController:self];

	/* Set Autosave-Name for the Buddylist  */
	[buddyList setAutosaveTableColumns:TRUE];
	[buddyList setAutosaveName:@"Buddylist"];

	/* Load Preferences */
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	if([prefs objectForKey:@"Username"])
		[usernameField setStringValue:[prefs objectForKey:@"Username"]];
	else
		[savePasswordBox setState:0];
		
	if([AGKeychain checkForExistanceOfKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[prefs objectForKey:@"Username"]])
		[passwordField setStringValue:[AGKeychain getPasswordFromKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[prefs objectForKey:@"Username"]]];
	else
		[savePasswordBox setState:0];
		
	if([prefs boolForKey:@"AutoLogin"]){
		[autoLoginBox setState:1];
		if([AGKeychain checkForExistanceOfKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[prefs objectForKey:@"Username"]])
			[self login];
	}
	else
		[autoLoginBox setState:0];
	[self loadPrefs];
		
	[installedGameList setDataSource:self];
	[pcGameList setDataSource:self];
	[macGameList setDataSource:self];
	[searchResultTable setDataSource:self];

	getTSInfo = true;

	NSSize size;
	size.width = 16;
	size.height = 16;

	[gamePopUpButton removeAllItems];
	NSArray *arr = [[NSArray alloc] initWithArray:[games getInstalledGames]];
	int i;
	
	for(i=0;i<[arr count];i++){
		[gamePopUpButton addItemWithTitle:[arr objectAtIndex:i]];
		NSImage *img = [games getIconForGame:[games getKeyForMacGame:[arr objectAtIndex:i]]];
		[img setSize:size];
		[[gamePopUpButton lastItem] setImage:img];
	}
	
/*	OSErr iErr;
	InetInterfaceInfo info;
	
	iErr = OTInetGetInterfaceInfo(&info, kDefaultInetInterface);
*/
/*	for(i=0; i<info.fHWAddrLen; i++) {
		NSLog(@"%@", [NSString stringWithFormat:@"%02x", info.fHWAddr[i]]);
	}
*/	
	[updater checkForUpdatesWithWindow:updateWindow andInfoField:updateInfo andNotesView:releaseNotes];
	
	// Load custom states...
	[self updateStatusMenu];
	
	// Sound-Preferences init...
	
	//Get all Sounds...
	NSMutableArray *sounds = [NSMutableArray array];
	soundPaths = [[NSMutableDictionary alloc] init];
	NSArray *array;
	NSString *path = @"/System/Library/Sounds";
	array = [[NSFileManager defaultManager] directoryContentsAtPath:@"/System/Library/Sounds"];
	if(array){
		[sounds addObjectsFromArray:array];
		for(i=0;i<[array count];i++){
			NSString *file = [NSString stringWithFormat:@"%@/%@", path, [array objectAtIndex:i]];
			[soundPaths setObject:file forKey:[array objectAtIndex:i]];
		}
	}
		
	path = @"/Library/Sounds";
	array = [[NSFileManager defaultManager] directoryContentsAtPath:@"/Library/Sounds"];
	if(array){
		[sounds addObjectsFromArray:array];
		for(i=0;i<[array count];i++){
			NSString *file = [NSString stringWithFormat:@"%@/%@", path, [array objectAtIndex:i]];
			[soundPaths setObject:file forKey:[array objectAtIndex:i]];
		}
	}
		
	path = [@"~/Library/Sounds" stringByExpandingTildeInPath];
	array = [[NSFileManager defaultManager] directoryContentsAtPath:[@"~/Library/Sounds" stringByExpandingTildeInPath]];
	if(array){
		[sounds addObjectsFromArray:array];
		for(i=0;i<[array count];i++){
			NSString *file = [NSString stringWithFormat:@"%@/%@", path, [array objectAtIndex:i]];
			[soundPaths setObject:file forKey:[array objectAtIndex:i]];
		}
	}
		
	//Remove all Items from the NSPopUpButtons
	[soundOff removeAllItems];
	[soundOn removeAllItems];
	[soundSent removeAllItems];
	[soundRecieved removeAllItems];
	
	//Add 1 empty entry
	[soundOff addItemWithTitle:@""];
	[soundOn addItemWithTitle:@""];
	[soundSent addItemWithTitle:@""];
	[soundRecieved addItemWithTitle:@""];

	//Add the Sounds...	
	[soundOff addItemsWithTitles:sounds];
	[soundOn addItemsWithTitles:sounds];
	[soundSent addItemsWithTitles:sounds];
	[soundRecieved addItemsWithTitles:sounds];
	
	//Read Prefs and select the Items
	[soundOff selectItemWithTitle:[prefs objectForKey:@"soundOff"]];
	[soundOn selectItemWithTitle:[prefs objectForKey:@"soundOn"]];
	[soundSent selectItemWithTitle:[prefs objectForKey:@"soundSent"]];
	[soundRecieved selectItemWithTitle:[prefs objectForKey:@"soundRecieved"]];

	return;
}

- (void)applicationDidBecomeActive:(NSNotification*)notification
{
	if(![xfire loggedIn]){
		if(![loginWindow isVisible])
			[loginWindow makeKeyAndOrderFront:self];
	}
	else{
		if(![mainWindow isVisible])
			[mainWindow makeKeyAndOrderFront:self];
	}
}

- (void)copyData:(NSFileHandle*)handle {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    NSData *data;
	NSString *address = [[NSString alloc] init];
	NSString *port = [[NSString alloc] init];
	NSString *localhostString = [[NSString alloc] initWithFormat:@"IP %@", [net getLANAddress]];
	NSString *tempPort;

    while([data=[handle availableData] length]) {
        NSString *string=[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		NSScanner *scan = [[NSScanner alloc] initWithString:string];
		while(![scan isAtEnd]){
			tempPort = [NSString string];
			address = [NSString string];
			/* Getting the local port and the server address */
			[scan	scanUpToString:localhostString intoString:nil];
			[scan	scanString:localhostString intoString:nil];
			[scan	scanUpToString:@"> " intoString:&tempPort];
			[scan	scanString:@"> " intoString:nil];
			[scan	scanUpToString:@": UDP" intoString:&address];
				
		//	NSLog(@"%@", address);
		//	NSLog(@"%@", tempPort);	
			/* Removing a dot from the port */
			if([tempPort isEqualTo:[NSNull null]])
				NSLog(@"NSNull");
			else{
				if(![tempPort isEqualToString:@""]){
					NSMutableString* theGamePort;
					theGamePort = [[NSMutableString alloc] initWithString:tempPort];
					[theGamePort replaceOccurrencesOfString:@"." withString:@"" options:nil range:NSMakeRange(0, [theGamePort length])];
					[theGamePort replaceOccurrencesOfString:@" " withString:@"" options:nil range:NSMakeRange(0, [theGamePort length])];

					/* Check wether the address is a TeamSpeak server */
					if(tsPort){
						if([tsPort isEqualToString:theGamePort]){
							tsIP = address;
							dontContinue = true;
						}
						else
							dontContinue = false;
					}
					[theGamePort release];
				}
			}
				
		//	NSLog(@"%@", address);
		//	NSLog(@"Port: %@", theGamePort);
			NSArray *arr = [[NSArray alloc] initWithArray:[address componentsSeparatedByString:@"."]];
		
			if([arr count] > 4){
			if([[arr objectAtIndex:0] isEqualToString:@"192"] && [[arr objectAtIndex:1] isEqualToString:@"168"])
				dontContinue = true;
			else if([[arr objectAtIndex:0] isEqualToString:@"10"])
				dontContinue = true;
			else if([[arr objectAtIndex:0] isEqualToString:@"172"])
				dontContinue = true;
			if([arr count] < 5)
				dontContinue = true;
			}
			
			if(!dontContinue){
				if(!([address length] > 25)){
					/* Get the port */
					port = [[address componentsSeparatedByString:@"."] objectAtIndex:[arr count] -1];
					NSMutableString *ip = [[NSMutableString alloc] initWithString:address];
					NSMutableString *dotPort = [[NSMutableString alloc] initWithString:@"."];
					[dotPort appendString:port];
					/* Final port */
					[ip replaceOccurrencesOfString:dotPort withString:@"" options:nil range:NSMakeRange(0, [ip length])];
			
					/* Check wether the ip is the same as before */
					if([theIP isEqualToString:[[NSHost hostWithName:ip] address]]){
						sameAddress += 1;
						tim = 0;
					}
					else{
						if(tim > 10)
							sameAddress = 0;
						tim += 1;
					}
			
					/* Final checked address */
					theIP = [[[NSHost hostWithName:ip] address] retain];
					thePort = [port retain];
					
					/* Cleaning up */
					[ip release];
					[dotPort release];
				}
			}
			[arr release];
		}
        [string release];
		[scan	release];
		NSLog(@"releasing pool...");
		[pool release];
		pool = [[NSAutoreleasePool alloc] init];
		usleep(10000);
    }
	[localhostString release];
	[address release];
	[port release];
    [pool release];
}

	/****************************/
	/*     Pointers				*/
	/****************************/

- (MyXfireWrapper *)xfirePointer
{
	return xfire;
}

- (MySmiley *)smileyPointer
{
	return smiley;
}

- (MyGrowl *)growlPointer
{
	return growl;
}

- (MyXfireGames *)gamesPointer
{
	return games;
}

	/****************************/
	/*     Chatting				*/
	/****************************/
	
- (bool)chattingWithBuddy:(NSString *)buddy
{
	/* Are we chatting with that guy? */
	int i;
	for(i=0;i<[chats count];i++){
		if([[[chats objectAtIndex:i] title] isEqualToString:buddy])
			return true;
		if(![[xfire getNicknameForUser:buddy] isEqualToString:@""]){
			if([[[chats objectAtIndex:i] title] isEqualToString:[xfire getNicknameForUser:buddy]])
				return true;
		}
	}
	return false;
}

- (void)setString:(NSString *)string
{
	int i;
	for(i=0;i<[chats count];i++){
		MyChatWindow *chat = [chats objectAtIndex:i];
		if([chat windowOpen])
			[chat addString:string];
	}
}

- (void)setString:(NSString *)string forUser:(NSString *)user
{
	int i;
	for(i=0;i<[chats count];i++){
		MyChatWindow *chat = [chats objectAtIndex:i];
		if([[chat title] isEqualToString:user]){
			[chat addString:string];
			[chat addString:@"\n"];
		}
	}
}

- (void)addString:(NSString *)string fromUser:(NSString *)user
{
	NSRange timestampRange = timestampRange = NSMakeRange(11, 12);
	if([bounceBox state] == 1)
		[NSApp requestUserAttention:NSInformationalRequest];
	[self playSoundForKey:@"soundRecieved"];
	int i;
	for(i=0;i<[chats count];i++){
		MyChatWindow *chat = [chats objectAtIndex:i];
		if([[chat title] isEqualToString:user] || [[chat title] isEqualToString:[xfire getNicknameForUser:user]]){
			if([chat windowOpen]){
				oldLength = [[chat textStorage] length];
				if(![[xfire getNicknameForUser:user] isEqualToString:@""])
					[chat addString:[xfire getNicknameForUser:user]];
				else
					[chat addString:user];
				newLength = [[chat textStorage] length];
				
				/* TIMESTAMP */
				[chat addString: @" ("];
				unichar *buffer = (unichar *)calloc( [[[NSDate date] description] length], sizeof( unichar ) );
				[[[NSDate date] description] getCharacters:buffer range:timestampRange];
				NSString *timestamp = [NSString stringWithCharacters:buffer length:8];
				free(buffer);
				[chat addString: timestamp];
				[chat addString: @"): "];
				NSDictionary *attrs2 = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor grayColor], NSForegroundColorAttributeName,[NSFont boldSystemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName, NULL];
				[[chat textStorage] setAttributes:attrs2 range:NSMakeRange(newLength - 1, 13)];
				/* TIMESTAMP */
				
				NSRange nicknameRange = NSMakeRange(oldLength, newLength - oldLength+1);
				NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor redColor], NSForegroundColorAttributeName,[NSFont boldSystemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName, NULL];
				[[chat textStorage] setAttributes:attrs range:nicknameRange];
				[[chat textStorage] endEditing];
				[chat addString:string];
				[chat addString:@"\n"];
				[chat searchURLS];
				return;
			}
		}
	}
	MyChatWindow *chat = [[MyChatWindow alloc] initWithController:self andUsername:user];

//	[tchat run];
	if(![[xfire getNicknameForUser:user] isEqualToString:@""])
		[chat setTitle:[xfire getNicknameForUser:user]];
	else
		[chat setTitle:user];
		
	[chats addObject:chat];
	[chat run];
	oldLength = [[chat textStorage] length];
	if(![[xfire getNicknameForUser:user] isEqualToString:@""])
		[chat addString:[xfire getNicknameForUser:user]];
	else
		[chat addString:user];
	newLength = [[chat textStorage] length];
	[chat addString:@" "];
	NSRange nicknameRange = NSMakeRange(oldLength, newLength - oldLength);
	NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor redColor], NSForegroundColorAttributeName,[NSFont boldSystemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName, NULL];
	[[chat textStorage] setAttributes:attrs range:nicknameRange];
	
	/* TIMESTAMP */
	[chat addString: @"("];
	unichar *buffer = (unichar *)calloc( [[[NSDate date] description] length], sizeof( unichar ) );
	[[[NSDate date] description] getCharacters:buffer range:timestampRange];
	NSString *timestamp = [NSString stringWithCharacters:buffer length:8];
	free(buffer);
	[chat addString: timestamp];
	[chat addString: @"): "];
	NSDictionary *attrs2 = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor grayColor], NSForegroundColorAttributeName,[NSFont boldSystemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName, NULL];
	[[chat textStorage] setAttributes:attrs2 range:NSMakeRange(newLength , 12)];
	/* TIMESTAMP */
	
	[[chat textStorage] endEditing];
	[chat addString:string];
	[chat addString:@"\n"]; 
}

- (void)playSoundForKey:(NSString *)key
{
	NSString *path = [soundPaths objectForKey:[[NSUserDefaults standardUserDefaults] objectForKey:key]];
	if(path){
		NSData *data = [[NSData alloc] initWithContentsOfFile:path];
		NSSound *sound = [[NSSound alloc] initWithData:data];
		[sound play];
		[sound release];
		[data release];
	}
}

- (void)removeChatWindow:(NSString *)name
{
	int i;
	for(i=0;i<[chats count];i++){
		MyChatWindow *chat = [chats objectAtIndex:i];
		if([[chat title] isEqualToString:name]){
			[chat release];
			[chats removeObject:[chats objectAtIndex:i]];
		}
	}
}

- (void)openChatWindow:(NSString *)name
{
	int i;
	for(i=0;i<[chats count];i++){
		MyChatWindow *chat = [chats objectAtIndex:i];
		if([[chat title] isEqualToString:name]){
			[chat run];
			[[NSApplication sharedApplication] arrangeInFront:self];
		}
	}
}

- (void)buddyIsTyping:(NSString *)username
{
	int i;
	for(i=0;i<[chats count];i++){
		MyChatWindow *chat = [chats objectAtIndex:i];
		if([[chat username] isEqualToString:username]){
			[chat setIsTyping];
		}
	}
}

- (void)buddy:(NSString *)buddy isOnline:(bool)isOnline
{
	if(firstNotification){
		firstNotification = false;
		return;
	}
	
	NSString *name = [xfire getNicknameForUser:buddy];
	if(![name isEqualToString:@""])
		buddy = name;

	if(isOnline){
		[growl postNotificationWithTitle:buddy andDescription:NSLocalizedString(@"contactOn", @"") andName:NSLocalizedString(@"contactOn", @"") clickContext:nil];
		[self setString:NSLocalizedString(@"nowOnline", @"") forUser:buddy];
	}
	else{
		[growl postNotificationWithTitle:buddy andDescription:NSLocalizedString(@"contactOff", @"") andName:NSLocalizedString(@"contactOff", @"") clickContext:nil];
		[self setString:NSLocalizedString(@"nowOffline", @"") forUser:buddy];
	}

}

	/****************************/
	/*     Nicks & Usernames	*/
	/****************************/
	
- (NSString *)getUsername
{
	return [usernameField stringValue];
}

- (NSString *)getNickForUser:(NSString *)user
{
	return nil;
}

	/****************************/
	/*     Logging in & out		*/
	/****************************/
	
- (bool)login
{
/*	if(![net activeInternetConnection]){
		NSAlert *myAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"noInetShort", @"") defaultButton:NSLocalizedString(@"ok", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"noInet", @"")];
		[myAlert runModal];
		return false;
	} */
	[xfire resetStatus];
	bool loggingIn = true;
	[progressIndicator startAnimation:progressIndicator];
	[usernameField setStringValue:[[usernameField stringValue] lowercaseString]];
//	[passwordField setStringValue:[[passwordField stringValue] lowercaseString]];	// Password is Case-Sensitive!!!
	[xfire loginWithUsername:[usernameField stringValue] andPassword:[passwordField stringValue]];
	[self saveData];
	[self loadPrefs];

	while(loggingIn){
		if([xfire loggedIn]){
			[progressIndicator stopAnimation:progressIndicator];
			[loginWindow close];
			[mainWindow makeKeyAndOrderFront:self];
			[statusPopUpMenu selectItemAtIndex:0];
			[[[[[NSApp mainMenu] itemWithTag:1] submenu] itemWithTag:5] setAction:@selector(startModal:)];
			[[[[[NSApp mainMenu] itemWithTag:1] submenu] itemWithTag:2] setAction:@selector(startModal:)];
			[[[[[NSApp mainMenu] itemWithTag:1] submenu] itemWithTag:6] setAction:@selector(startModal:)];
			[self updateBuddylist];
		//	[self getNickForUser:@"fl0ri4n"];
			loggingIn = false;
			return true;
		}
		else if([xfire loginFailed]){
			[progressIndicator stopAnimation:progressIndicator];
			return false;
		}
	}
	
	return false;
}

- (void)otherLogin
{
	[buddyList setDataSource:nil];
	[loginWindow makeKeyAndOrderFront:self];
	[mainWindow close];
	if([bounceBox state] == 1)
		[NSApp requestUserAttention:NSInformationalRequest];
	NSAlert *myAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"otherShort", @"") defaultButton:NSLocalizedString(@"ok", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"other", @"")];
	if([myAlert runModal] == 1)
		return;
}

- (void)loginFailed
{
	NSLog(@"Login fehlgeschlagen!");
	if([bounceBox state] == 1)
		[NSApp requestUserAttention:NSInformationalRequest];
	NSAlert *myAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"loginFailedShort", @"") defaultButton:NSLocalizedString(@"ok", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"loginFailed", @"")];
	if([myAlert runModal] == 1)
		return;
}

- (void)logout
{
	if([xfire loggedIn]){
		[xfire disconnect];
		[buddyList setDataSource:nil];
		[loginWindow makeKeyAndOrderFront:self];
		[mainWindow close];
		[[[[[NSApp mainMenu] itemWithTag:1] submenu] itemWithTag:6] setAction:nil];
		[[[[[NSApp mainMenu] itemWithTag:1] submenu] itemWithTag:5] setAction:nil];
		[[[[[NSApp mainMenu] itemWithTag:1] submenu] itemWithTag:2] setAction:nil];
		
	}
}

	/****************************/
	/*     Prefs & Xfire-URLS	*/
	/****************************/
	
- (void)loadPrefs
{
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	
	if(![prefs boolForKey:@"notFirstLaunch"]){
	//	[enableNetworkBox setState:1];
	//	[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"EnableNetwork"];
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"notFirstLaunch"];
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"bounceIcon"];
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"enableDrawer"];
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"gameInfo"];
		[[NSUserDefaults standardUserDefaults] registerDefaults:NULL];
		[donationWindow orderFront:self];
	}
	
	if([AGKeychain checkForExistanceOfKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[prefs objectForKey:@"Username"]])
		[savePasswordBox2 setState:1];
	else
		[savePasswordBox2 setState:0];

	if([prefs boolForKey:@"AutoLogin"])
		[autoLoginBox2 setState:1];
	else
		[autoLoginBox2 setState:0];
		
	if([prefs boolForKey:@"AutoSize"])
		[autosizeBox setState:1];
	else
		[autosizeBox setState:0];

	if([prefs boolForKey:@"noIP"])
		[noIPBox setState:1];
	else
		[noIPBox setState:0];
		
	if([prefs boolForKey:@"EnableNetwork"])
		[enableNetworkBox setState:1];
	else
		[enableNetworkBox setState:0];	
		
	if([prefs objectForKey:@"NetworkInterface"])
		[interfaceField setStringValue:[prefs objectForKey:@"NetworkInterface"]];
	else
		[interfaceField setStringValue:@""];
		
	if([prefs boolForKey:@"bounceIcon"])
		[bounceBox setState:1];
	else
		[bounceBox setState:0];	
		
	if([prefs boolForKey:@"enableDrawer"])
		[drawerBox setState:1];
	else
		[drawerBox setState:0];	
		
	if([prefs boolForKey:@"gameInfo"])
		[gameInfoBox setState:1];
	else{
		[gameInfoBox setState:0];
		[buddyList removeTableColumn:[buddyList tableColumnWithIdentifier:@"Game"]];
	}
	
	if([prefs boolForKey:@"showOffline"])
		[showOfflineBox setState:1];
	else
		[showOfflineBox setState:0];	
	
	statusArray = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"States"]];
	
//	[[NSUserDefaults standardUserDefaults] setObject:@"0.1" forKey:@"Version"];
	[[NSUserDefaults standardUserDefaults] setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey] forKey:@"Version"];
	[[NSUserDefaults standardUserDefaults] registerDefaults:NULL];
}

- (void)saveData
{
	/* Save login data */
	if([savePasswordBox state] == 1){
		[[NSUserDefaults standardUserDefaults] setObject:[usernameField stringValue] forKey:@"Username"];
	//	[[NSUserDefaults standardUserDefaults] setObject:[passwordField stringValue] forKey:@"Password"];
		
		if(![AGKeychain checkForExistanceOfKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[usernameField stringValue]])
			[AGKeychain addKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[usernameField stringValue] withPassword:[passwordField stringValue]];
		else{
			[AGKeychain deleteKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[usernameField stringValue]];
			[AGKeychain addKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[usernameField stringValue] withPassword:[passwordField stringValue]];
		}
	}
	
	/* Remove login data */
	else if(![savePasswordBox state]){
	//	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Username"];
	//	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Password"];
		
		if([AGKeychain checkForExistanceOfKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[usernameField stringValue]])
			[AGKeychain deleteKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[usernameField stringValue]];
	}
	
	/* Enable/disable autologin */
	if([autoLoginBox state] == 1)
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"AutoLogin"];
	else if(![autoLoginBox state])
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AutoLogin"];
	
	/* Save the preferences */
	[[NSUserDefaults standardUserDefaults] registerDefaults:NULL];
}

- (void)registerMyApp
{
	/* Register the Xfire URL */
	
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	NSString *action, *name, *game, *server, *password;
	
	/* Parse the Xfire URL */
	
	NSScanner *scan = [NSScanner scannerWithString:url];
	[scan scanUpToString:@"xfire:"intoString:nil];
	[scan scanString:@"xfire:"intoString:nil];
	[scan scanUpToString:@"?"intoString:&action];
	
	if([action isEqualToString:@"add_friend"]){
		[scan scanUpToString:@"?user="intoString:nil];
		[scan scanString:@"?user="intoString:nil];
		[scan scanUpToString:@""intoString:&name];
		[invitationWindow makeKeyAndOrderFront:self];
		[invitationUsername setStringValue:name];
	}
	else if([action isEqualToString:@"join"]){
		[scan scanUpToString:@"?game="intoString:nil];
		[scan scanString:@"?game="intoString:nil];
		[scan scanUpToString:@"&server="intoString:&game];
		
		[scan scanUpToString:@"&server="intoString:nil];
		[scan scanString:@"&server="intoString:nil];
		if([scan isAtEnd])
			[scan scanUpToString:@""intoString:&server];
		else
			[scan scanUpToString:@"&password="intoString:&server];
		
		if(![scan isAtEnd]){
			[scan scanUpToString:@"&password="intoString:nil];
			[scan scanString:@"&password="intoString:nil];
			[scan scanUpToString:@""intoString:&password];
		}
		[games startGame:[games getMacGameForKey:[games getKeyForShortName:[game uppercaseString]]] withAdress:server];
	}
/*	else if([action isEqualToString:@"status"]){
		[scan scanUpToString:@"?text="intoString:nil];
		[scan scanString:@"?text="intoString:nil];
		[scan scanUpToString:@""intoString:&newStatus];
		NSLog(@"%@", newStatus);
		} */
}

	/****************************/
	/*    Updating             */
	/****************************/
	
- (void)updateBuddylist
{
	if(![xfire loggedIn])
		return;
		
//	[buddyList reloadData];
	if([xfire loggedIn]){
		if([buddyList selectedRow] == -1)
			[infoDrawer close];
		else
			[self updateDrawer];
	}
	
	/* Set size of main window */
	if([autosizeBox state] == 1){
		NSRect frame = [mainWindow frame];
	//	frame.size.height = [buddyList numberOfRows] * 32 + 165;
		frame.size.height = [buddyList numberOfRows] * 32 + 170;
		[mainWindow setFrame:frame display:YES];
	}
	[buddyList reloadData];
}

- (void)updateDrawer
{
	NSMutableString *info = [[NSMutableString alloc] init];
	NSString *game2Number = [[[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"game2ID"] stringValue];
	NSNumber *myUser = [[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"userID"];
	
	[info appendString:@"Username: "];
	NSString *name = [[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"name"];
	if(name)
		[info appendString:name];
	if(![[[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"nick"] isEqualToString:@""]){
		[info appendString:@"\n"];
		[info appendString:@"Nickname: "];
		NSString *nick = [[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"nick"];
		if(nick)
			[info appendString:nick];
	}
	[info appendString:@"\n"];
	[info appendString:@"Status: "];
	if(![[[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"onlineStatus"] boolValue])
		[info appendString:@"Offline"];
	else if([[[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"msg"] isEqualToString:@""])
		[info appendString:@"Online"];
	else{
		NSString *msg = [[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"msg"];
		if(msg)
			[info appendString:msg];
	}
	
	if([game2Number isEqualToString:@"32"] || [game2Number isEqualToString:@"33"] ||[game2Number isEqualToString:@"34"]){
		[info appendString:@"\n\n"];
		if([game2Number isEqualToString:@"32"])
			[info appendString:@"Voice Software: TeamSpeak"];
		if([game2Number isEqualToString:@"33"])
			[info appendString:@"Voice Software: Ventrilo"];
		if([game2Number isEqualToString:@"34"])
			[info appendString:@"Voice Software: Mumble"];
		[info appendString:@"\n"];
		
		NSArray *voiceadress = [[xfire getVoiceInfo] objectForKey:myUser];

		if([[[voiceadress objectAtIndex:4] stringValue] isEqualToString:@"0"])
			voiceadress = nil;

		if(voiceadress){
			NSMutableString *serveradress2 = [[NSMutableString alloc] init];
			[info appendString:@"Voice Server: "];
			
			for(uint j=3;j>0;j--){
				[serveradress2 appendString:[[voiceadress objectAtIndex:j] stringValue]];
				[serveradress2 appendString:@"."];
			}
			if([[voiceadress objectAtIndex:0] stringValue])
				[serveradress2 appendString:[[voiceadress objectAtIndex:0] stringValue]];
			[serveradress2 appendString:@":"];
			if([[voiceadress objectAtIndex:4] stringValue])
				[serveradress2 appendString:[[voiceadress objectAtIndex:4] stringValue]];
			
			[info appendString:serveradress2];
			friendsVoiceIP = [[NSString alloc] initWithString:serveradress2];
			[serveradress2 release];
			
			/* Make TS2-Button visible/invisible */
			if([game2Number isEqualToString:@"32"] && [MyXfireVoice teamspeakIsInstalled])
				[joinVoiceButton setHidden:FALSE];
			else
				[joinVoiceButton setHidden:TRUE];
			[joinVoiceButton setImage:[MyXfireVoice getTSIcon]];
		}
	}
	else
		[joinVoiceButton setHidden:TRUE];
	
	[info appendString:@"\n\n"];
	NSString *gameNumber = [[[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"gameID"] stringValue];
	if(gameNumber && ![gameNumber isEqualToString:@"0"]){
		[info appendString:@"Playing: "];
		if([games getMacGameForKey:gameNumber])
			[info appendString:[games getMacGameForKey:gameNumber]];
		else if([games getNameForKey:gameNumber])
			[info appendString:[games getNameForKey:gameNumber]];
	}
	
	NSArray *adress = [[xfire getGameInfo] objectForKey:myUser];
	
	if([[[adress objectAtIndex:4] stringValue] isEqualToString:@"0"])
		adress = nil;
		
	if([games macGameInstalled:[games getMacGameForKey:gameNumber]]){
		[joinGameButton setHidden:FALSE];
		gameNumber = [[[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"gameID"] stringValue];
		[joinGameButton setImage:[games getIconForGame:gameNumber]];
	}
	else
		[joinGameButton setHidden:TRUE];
	
	[[[playerList superview] superview] setHidden:TRUE];
//	[[playerinfoTable enclosingScrollView] setHidden:TRUE];

	if(adress){
		[info appendString:@"\n"];
		[info appendString:@"Server: "];
		NSMutableString *serveradress = [[NSMutableString alloc] init], *players = [[NSMutableString alloc] init];
		
		for(uint j=3;j>0;j--){
			[serveradress appendString:[[adress objectAtIndex:j] stringValue]];
			[serveradress appendString:@"."];
		}
		if([[adress objectAtIndex:0] stringValue])
			[serveradress appendString:[[adress objectAtIndex:0] stringValue]];
		[serveradress appendString:@":"];
		if([[adress objectAtIndex:4] stringValue])
			[serveradress appendString:[[adress objectAtIndex:4] stringValue]];
		
		[info appendString:serveradress];
		
		NSString *qstatGameServer = [games getGameServerForMacGame:[games getMacGameForKey:gameNumber]];
		NSDictionary *serverInfo = [qstat getInformationForGameServer:serveradress WithServerType:qstatGameServer];
		playerData = [[NSMutableArray alloc] init];
		for(uint j=0;j<[[serverInfo objectForKey:@"Playerinfo"] count];j++)
			[playerData addObject:[NSDictionary dictionaryWithObjectsAndKeys:[[serverInfo objectForKey:@"Playerinfo"] objectAtIndex:j], @"Playerinfo", [NSNumber numberWithInt:[[[serverInfo objectForKey:@"Score"] objectAtIndex:j] intValue]], @"Score", nil]];
	//	NSLog(@"%@", playerData);
	//	NSLog(@"%@, %@, %@", serverInfo, serveradress, qstatGameServer);
		if(serverInfo){
			[info appendString:@"\nName: "];
			NSString *servername = [serverInfo objectForKey:@"Name"];
			if(servername)
				[info appendString:servername];
			[info appendString:@"\nMap: "];
			NSString *map = [serverInfo objectForKey:@"Map"];
			if(map)
				[info appendString:map];
			[info appendString:@"\nPlayers: "];
			NSString *playernumber = [serverInfo objectForKey:@"Playernumber"];
			if(playernumber)
				[info appendString:playernumber];
			if([serverInfo objectForKey:@"Playerinfo"]){
				[[[playerList superview] superview] setHidden:FALSE];
				for(int i=0;i<[[serverInfo objectForKey:@"Playerinfo"] count];i++){
					NSString *player = [[serverInfo objectForKey:@"Playerinfo"] objectAtIndex:i];
					if(player)
					[players appendString:player];
					[players appendString:@"\n"];
				}
				[playerList setString:players];
			}
			[playerinfoTable reloadData];
			[[playerinfoTable enclosingScrollView] setHidden:FALSE];
		} 
		else {
			[[[playerList superview] superview] setHidden:TRUE];
			[[playerinfoTable enclosingScrollView] setHidden:TRUE];
			[serveradress release];
			[players release];
		}
		}
		else
			[[playerinfoTable enclosingScrollView] setHidden:TRUE];

	[drawerInfo setStringValue:info];
	[info release];
}


- (void)updateStatusMenu
{
	NSArray *arr = [NSArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"States"]];
	int i;
	while([statusPopUpMenu numberOfItems] > 5)
		[statusPopUpMenu removeItemAtIndex:3];
	for(i=0;i<[arr count];i++)
		[statusPopUpMenu insertItemWithTitle:[arr objectAtIndex:i] atIndex:3];
}

- (void)update:(NSTimer *)timer
{
	[myUserName setStringValue:[usernameField stringValue]];
	[myStatusField	setStringValue:[[statusPopUpMenu selectedItem] title]];


	/* Open Login window if disconnected */
	if(![xfire loggedIn]){
		[mainWindow close];
//		[statusPopUpMenu selectItemAtIndex:4];
		[statusPopUpMenu selectItem:[statusPopUpMenu lastItem]];
		buddiesOnline = 0;
	}
	else{
		/* Play Sound if someone has logged in/out */
		NSString *str = [xfire buddyStatusChanged];

		if([xfire buddiesOnline] > buddiesOnline){
			[self playSoundForKey:@"soundOn"];
			[self buddy:str isOnline:true];
		}
		else if([xfire buddiesOnline] < buddiesOnline){
			[self playSoundForKey:@"soundOff"];
			[self buddy:str isOnline:false];
		}
		[str release];
			
		buddiesOnline = [xfire buddiesOnline];
	
		[buddyList setDataSource:self];
				
		if(tsIP)
			NSLog(@"TeamSpeak Server found: %@", tsIP);
		
		/* Is a game running? */
		int gameRunning = [[games gameRunning] intValue];
		if(gameRunning){
		//	NSLog(@"%i", gameRunning);
			[myGameIcon setImage:[games getIconForGame:[[NSNumber numberWithInt:gameRunning] stringValue]]];
			[myGame		setStringValue:[games getMacGameForKey:[[NSNumber numberWithInt:gameRunning] stringValue]]];
			/* Is there a connection to that IP? */
			if(override){
				[xfire setGameStatus:gameRunning withIP:overridedIP andPort:[overridedPort intValue]];
				[myIP	setStringValue:[NSString stringWithFormat:@"%@:%@", overridedIP, overridedPort]];
			}
			else{
				if(sameAddress > 19){
					/* Server found :) */
					[xfire setGameStatus:gameRunning withIP:theIP andPort:[thePort intValue]];
				//	NSLog(@"Game Server found: %@", theIP);
					[myIP	setStringValue:[NSString stringWithFormat:@"%@:%@", theIP, thePort]];
				}
				else{
					/* Currently not playing on a server */
					[xfire setGameStatus:gameRunning withIP:@"0.0.0.0" andPort:0];
					[myIP	setStringValue:[NSString string]];
				}
			}
		}
		else{
			/* Currently not playing a game */
			[xfire setGameStatus:0 withIP:@"0.0.0.0" andPort:0];
			theIP = nil;
			thePort = nil;
			sameAddress = 0;
			tim = 0;
			[myGameIcon setImage:nil];
			[myGame		setStringValue:[NSString string]];
			[myIP	setStringValue:[NSString string]];
		}
		
		/* If TeamSpeak is running... */
/*		if([games teamSpeakRunning]){
			if(getTSInfo){
			//	tsPort = [net getPortForGame:@"TeamSpeex"];
			//	NSLog(@"TeamSpeak launched with Port: %@", [net getPortForGame:@"TeamSpeex"]);
			}
			getTSInfo = false;
		}
		else{
			getTSInfo = true;
			tsPort = nil;
			tsIP = nil;
		} */
	//	[xfire setVoiceStatus:32 withIP:@"23.34.56.57" andPort:@"4556"];

	}
	
/*	NSString *voice = [MyXfireVoice voiceSoftwareRunning];
	if([voice isEqualToString:@"TeamSpeak"] && !overrideVoice)
		[xfire setVoiceStatus:32 withIP:@"0.0.0.0" andPort:0];
*/	
	/* Update Chat Wndows */
	int i;
	for(i=0;i<[chats count];i++){
		MyChatWindow *chat = [chats objectAtIndex:i];
		[chat update];
	}
}

	/****************************/
	/*    Tableviews            */
	/****************************/

- (void)doubleclick
{
	if(([buddyList selectedRow] == -1))
		return;
	if(![xfire loggedIn])
		return;
	
	/* Open a chat window and set it up */
	NSString *buddyname = [[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"name"];
	if(![self chattingWithBuddy:buddyname]){
		MyChatWindow *chat = [[MyChatWindow alloc] initWithController:self andUsername:buddyname];
		if(![[xfire getNicknameForUser:buddyname] isEqualToString:@""])
			[chat setTitle:[xfire getNicknameForUser:buddyname]];
		else
			[chat setTitle:buddyname];
		[chats addObject:chat];
		[chat run];
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{

	if(tableView == buddyList){
		if([xfire loggedIn]){
			if([showOfflineBox state] == 1)
				return [[xfire getBuddyInfo] count];
			else if(![showOfflineBox state])
				return [xfire buddiesOnline];
		}
		else
			return 0;
	}
	else if(tableView == macGameList){
		return [[games getMacGames] count];
	}
	
	else if(tableView == pcGameList){
		return [[games getPCGames] count];
	}
	
	else if(tableView == installedGameList){
		return [[games getInstalledGames] count];
	}
	
	else if(tableView == statusTable){
		return [statusArray count];
	}

	else if(tableView == playerinfoTable){
		return [playerData  count];
	}
	else if(tableView == searchResultTable){
		return [searchResults count];
	}
	
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row
{
	if(tableView == buddyList){
		if([xfire loggedIn]){
			NSString *gameNumber = [[[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"gameID"] stringValue];
			NSString *game2Number = [[[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"game2ID"] stringValue];
			if([[column identifier] isEqualToString:@"Name"]){
				[column setDataCell: myTextCell];
					if(![[[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"nick"] isEqualToString:@""])
				return [[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"nick"];
				else
					return [[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"name"];
			}
			else if([[column identifier] isEqualToString:@"Status"]){
				if(![gameNumber isEqualToString:@"0"]){
					if([[[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"onlineStatus"] boolValue]){
				//		NSLog(@"%@ %@", [[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"nick"], gameNumber);
						return @"Playing";
					}
				}

				[column setDataCell: myTextCell];
				if(![[[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"onlineStatus"] boolValue])
					return @"Offline";
				if([[[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"msg"] isEqualToString:@""])
					return @"Online";
				else
					return [[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"msg"];
			}
			else if([[column identifier] isEqualToString:@"Game"]){
				[column setDataCell: myTextCell];
				if(![[[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"onlineStatus"] boolValue])
					return nil;
				if(![gameNumber isEqualToString:@"0"])
					return [games getNameForKey:gameNumber];
				if([game2Number isEqualToString:@"32"])
					return @"TeamSpeak";
				else if([game2Number isEqualToString:@"33"])
					return @"Ventrilo";
				else if([game2Number isEqualToString:@"34"])
					return @"Mumble";
			}
		
			else if([[column identifier] isEqualToString:@"Image"]){
				[column setDataCell: myImageCell];
				if(![gameNumber isEqualToString:@"0"] && [[[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"onlineStatus"] boolValue] && [games macGameInstalled:[games getMacGameForKey:gameNumber]]){
					return [games getIconForGame:gameNumber];
				}
				else if(![gameNumber isEqualToString:@"0"] && [[[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"onlineStatus"] boolValue])
					return [games getIconForPCGame:gameNumber];
				if(![[[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"onlineStatus"] boolValue])
					return red;
				else if([[[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"msg"] isEqualToString:@"Online"])
					return green;
				else if([[[[xfire getBuddyInfo] objectAtIndex:row] objectForKey:@"msg"] isEqualToString:@""])
					return green;
				else
					return orange;
			}
		}
	}
	
	else if(tableView == macGameList){
		if([[column identifier] isEqualToString:@"Name"])
			return [[games getMacGames] objectAtIndex:row];
		else if([[column identifier] isEqualToString:@"Join"]){
			[column setDataCell: myImageCell];
			if([games getLaunchArgumentsForMacGame:[[games getMacGames] objectAtIndex:row]])
				return haken;
			else
				return kreuz;
		}
		else if([[column identifier] isEqualToString:@"Icon"]){
			[column setDataCell: myImageCell];
			return [games getIconForPCGame:[games getKeyForMacGame:[[games getMacGames] objectAtIndex:row]]];
		}
	}
	
	else if(tableView == pcGameList){
		if([[column identifier] isEqualToString:@"Name"])
			return [[games getPCGames] objectAtIndex:row];
		else if([[column identifier] isEqualToString:@"Icon"]){
			[column setDataCell: myImageCell];
			return [games getIconForPCGame:[games getKeyForGame:[[games getPCGames] objectAtIndex:row]]];
		}
	}
	
	else if(tableView == installedGameList){
		if([[column identifier] isEqualToString:@"Name"])
			return [[games getInstalledGames] objectAtIndex:row];
		else if([[column identifier] isEqualToString:@"Icon"])
			[column setDataCell: myImageCell];
			return [games getIconForGame:[games getKeyForMacGame:[[games getInstalledGames] objectAtIndex:row]]];
	}
	
	else if(tableView == statusTable){
		return [statusArray objectAtIndex:row];
	}
	
	else if(tableView == playerinfoTable){
		if([[column identifier] isEqualToString:@"Name"]){
			return [[playerData objectAtIndex:row] objectForKey:@"Playerinfo"];
		}
		else if([[column identifier] isEqualToString:@"Score"]){
			return [[[playerData objectAtIndex:row] objectForKey:@"Score"] stringValue];
		}
	}
	else if(tableView == searchResultTable){
		if([[column identifier] isEqualToString:@"name"]){
			return [[searchResults objectAtIndex:row] objectForKey:@"name"];
		}	
		else if([[column identifier] isEqualToString:@"fname"]){
			return [[searchResults objectAtIndex:row] objectForKey:@"fname"];
		}	
		else if([[column identifier] isEqualToString:@"lname"]){
			return [[searchResults objectAtIndex:row] objectForKey:@"lname"];
		}	
	}

	return nil;
}

- (void)tableView:(NSTableView *)aTable setObjectValue:(id)aData forTableColumn:(NSTableColumn *)aCol row:(int)aRow
{
	if(aTable == statusTable)
		[statusArray replaceObjectAtIndex:aRow withObject:aData];
}

- (void)tableView: (NSTableView *)tableView sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
	[playerData sortUsingDescriptors: [tableView sortDescriptors]];
	[tableView reloadData];
}
	

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation
{
	[buddyList enableTooltips];
	return nil;
}

	/****************************/
	/*    Add/Remove Buddyies   */
	/****************************/
	
- (IBAction)addBuddy:(id)sender
{
//	[invitationWindow makeKeyAndOrderFront:self];
	[NSApp beginSheet:invitationWindow modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[NSApp runModalForWindow:invitationWindow];
   
	[NSApp endSheet:invitationWindow];
    [invitationWindow orderOut:self];
}

- (IBAction)removeBuddy:(id)sender
{
	NSMutableString *alertString = [NSMutableString stringWithString:NSLocalizedString(@"rmBuddy1", @"")];
	[alertString appendString:[[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"name"]];
	[alertString appendString:NSLocalizedString(@"rmBuddy2", @"")];
	NSAlert *myAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"rmShort", @"") defaultButton:NSLocalizedString(@"ok", @"") alternateButton:NSLocalizedString(@"cancel", @"") otherButton:nil informativeTextWithFormat:alertString];
	if([myAlert runModal] == 1)
		[xfire removeBuddy:[[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"name"]];
}

- (IBAction)sendInvitaion:(id)sender
{
	if([invitationUsername stringValue]){
		[xfire inviteBuddy:[invitationUsername stringValue] withMessage:[invitationMessage stringValue]];
		[NSApp stopModal];
		[invitationUsername setStringValue:@""];
		[invitationMessage	setStringValue:@""];
	}
}

- (IBAction)newChat:(id)sender
{
	if(([buddyList selectedRow] == -1))
		return;
	if(![xfire loggedIn])
		return;
	
	/* Open a chat window and set it up */
	NSString *buddyname = [[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"name"];
	if(![self chattingWithBuddy:buddyname]){
		MyChatWindow *chat = [[MyChatWindow alloc] initWithController:self andUsername:buddyname];
		if(![[xfire getNicknameForUser:buddyname] isEqualToString:@""])
			[chat setTitle:[xfire getNicknameForUser:buddyname]];
		else
			[chat setTitle:buddyname];
		[chats addObject:chat];
		[chat run];
	}
}

	/****************************/
	/*    Login Window          */
	/****************************/

- (IBAction)login:(id)sender
{
	if(([autoLoginBox state] == 1) && ([savePasswordBox state] == 0))
		return;
	if([[usernameField stringValue] isEqualToString:@""])
		return;
	if([[passwordField stringValue] isEqualToString:@""])
		return;
		
	[self login];
}

- (IBAction)getPassword:(id)sender
{

}

- (IBAction)registerUser:(id)sender
{

}

	/****************************/
	/*    Main Window           */
	/****************************/
	
- (IBAction)tableClick:(id)sender
{
	if(![xfire loggedIn])
		return;
		
	if([sender selectedRow] == -1)
		[infoDrawer close];
	else{
		if([drawerBox state] == 1)
			[infoDrawer open];
		[self updateDrawer];
	//	NSLog(@"%i", [[buddyList menu] numberOfItems]);
	/*	if([buddyList menu])
			NSLog(@"Bliblablub");
		else
			NSLog(@"Murks");
		if([[buddyList menu] itemWithTag:1])
			NSLog(@"kjdjhf");
		else
			NSLog(@"blub");
	*/	[[[buddyList menu] itemWithTag:1] setEnabled:TRUE];
		int i;
		for(i=0;i<[[[buddyList menu] itemArray] count];i++)
			[[[[buddyList menu] itemArray] objectAtIndex:i] setEnabled:TRUE];
		//	NSLog(@"%@", [[[[buddyList menu] itemArray] objectAtIndex:i] title]);
	}
}

- (IBAction)visitProfile:(id)sender
{
	/* Create the URL to a buddys profile */
	NSMutableString *urlToBuddy = [[NSMutableString alloc] init];
	[urlToBuddy appendString:@"http://profile.xfire.com/"];
	[urlToBuddy appendString:[[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"name"]];
	NSURL *url = [[NSURL alloc] initWithString:urlToBuddy];
	/* Start the browser and go to this URL */
	[[NSWorkspace sharedWorkspace] openURL:url];
	
	[urlToBuddy release];
	[url release];
}

- (IBAction)joinGame:(id)sender
{
	NSNumber *myUser = [[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"userID"];
	NSArray *adress = [[xfire getGameInfo] objectForKey:myUser];
	NSMutableString *info = [[NSMutableString alloc] init];
	NSString *gameNumber = [[[[xfire getBuddyInfo] objectAtIndex:[buddyList selectedRow]] objectForKey:@"gameID"] stringValue];
	
	if([gameNumber isEqualToString:@"0"])
		return;
		
	if(![[[adress objectAtIndex:4] stringValue] isEqualToString:@"0"]){
		for(uint j=3;j>0;j--){
			[info appendString:[[adress objectAtIndex:j] stringValue]];
			[info appendString:@"."];
			}
		[info appendString:[[adress objectAtIndex:0] stringValue]];
		
		[info appendString:@":"];
		[info appendString:[[adress objectAtIndex:4] stringValue]];
		
		[games startGame:[games getMacGameForKey:gameNumber] withAdress:info];
	}
	else{
		if([noIPBox state] == 1)
			[games startGame:[games getMacGameForKey:gameNumber]];
	}
	
	[info release];
}

- (IBAction)popupClick:(id)sender
{
	NSString *status = [[statusPopUpMenu selectedItem] title];
	if([status isEqualToString:@"Offline"]){
		[self logout];
	}
	else if(![status isEqualToString:@"Online"])
		[xfire setStatusMessage:status];
	else
		[xfire setStatusMessage:@""];
	
	[status release];
}

	/****************************/
	/*    Preferences           */
	/****************************/
	
- (IBAction)applyPrefs:(id)sender
{
	/* Save login data */
	if([savePasswordBox2 state] == 1){
		[[NSUserDefaults standardUserDefaults] setObject:[usernameField stringValue] forKey:@"Username"];
	//	[[NSUserDefaults standardUserDefaults] setObject:[passwordField stringValue] forKey:@"Password"];
		
		if(![AGKeychain checkForExistanceOfKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[usernameField stringValue]])
			[AGKeychain addKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[usernameField stringValue] withPassword:[passwordField stringValue]];
		else{
			[AGKeychain deleteKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[usernameField stringValue]];
			[AGKeychain addKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[usernameField stringValue] withPassword:[passwordField stringValue]];
		}
	}

	
	/* Remove login data */
	else if(![savePasswordBox2 state]){
	//	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Username"];
	//	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Password"];
		
		if([AGKeychain checkForExistanceOfKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[usernameField stringValue]])
			[AGKeychain deleteKeychainItem:@"Xfire Password" withItemKind:@"iFire" forUsername:[usernameField stringValue]];
	}
	
	/* Enable/disable autologin */
	if([autoLoginBox2 state] == 1)
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"AutoLogin"];
	else if(![autoLoginBox2 state])
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AutoLogin"];
		
	if([autosizeBox state] == 1)
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"AutoSize"];
	else if(![autosizeBox state])
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AutoSize"];
		
	if([noIPBox state] == 1)
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"noIP"];
	else if(![noIPBox state])
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"noIP"];
		
	if([enableNetworkBox state] == 1)
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"EnableNetwork"];
	else if(![enableNetworkBox state])
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"EnableNetwork"];	
		
	if([[interfaceField stringValue] isEqualToString:@""])
		[[NSUserDefaults standardUserDefaults] setObject:@"en0" forKey:@"NetworkInterface"];
	else
		[[NSUserDefaults standardUserDefaults] setObject:[interfaceField stringValue] forKey:@"NetworkInterface"];
		
	if([bounceBox state] == 1)
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"bounceIcon"];
	else if(![bounceBox state])
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"bounceIcon"];
		
	if([drawerBox state] == 1)
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"enableDrawer"];
	else if(![drawerBox state]){
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"enableDrawer"];
		[infoDrawer close];
	}
	
	if([gameInfoBox state] == 1)
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"gameInfo"];
	else if(![gameInfoBox state])
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"gameInfo"];
	
	if([showOfflineBox state] == 1)
		[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"showOffline"];
	else if(![showOfflineBox state])
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"showOffline"];
	
	/* The Sounds */
	[[NSUserDefaults standardUserDefaults] setObject:[soundOff title] forKey:@"soundOff"];
	[[NSUserDefaults standardUserDefaults] setObject:[soundOn title] forKey:@"soundOn"];
	[[NSUserDefaults standardUserDefaults] setObject:[soundSent title] forKey:@"soundSent"];
	[[NSUserDefaults standardUserDefaults] setObject:[soundRecieved title] forKey:@"soundRecieved"];
	
	/* Status */
	int i;
	for(i=0;i<[statusArray count];i++){
		if([[statusArray objectAtIndex:i] isEqualToString:@"<New Status>"])
			[statusArray removeObjectAtIndex:i];
	}
	[statusTable reloadData];
	[[NSUserDefaults standardUserDefaults] setObject:statusArray forKey:@"States"];
	[self updateStatusMenu];

	/* Save the preferences */
	[[NSUserDefaults standardUserDefaults] registerDefaults:NULL];
	
//	NSLog(@"Saved!");
	[prefWin close];

}

- (IBAction)chooseSound:(id)sender
{
	NSString *path = [soundPaths objectForKey:[sender title]];
	if(path){
		NSSound *sound = [[NSSound alloc] initWithContentsOfFile:path byReference:YES];
		[sound play];
		[sound release];
	}
}

- (IBAction)addStatus:(id)sender
{
	[statusArray addObject:@"<New Status>"];
	[statusTable reloadData];
	[statusTable selectRow:[statusTable numberOfRows] -1 byExtendingSelection:NO];
}

- (IBAction)removeStatus:(id)sender
{
	if([statusTable selectedRow] != -1)
		[statusArray removeObjectAtIndex:[statusTable selectedRow]];
	[statusTable reloadData];
}

	/****************************/
	/*    Change Nickname       */
	/****************************/

- (IBAction)changeNickname:(id)sender
{
	if(![[nicknameField stringValue] isEqualToString:@""] && [xfire loggedIn]){
		[xfire changeNick:[nicknameField stringValue]];
		[nicknameField setStringValue:@""];
	}
	[NSApp stopModal];
}

	/****************************/
	/*    Launch Game           */
	/****************************/

- (IBAction)launchGame:(id)sender
{
	if(![[launchServerIP stringValue] isEqualToString:@""]){
		if([games getLaunchArgumentsForMacGame:[gamePopUpButton titleOfSelectedItem]])
			[games startGame:[gamePopUpButton titleOfSelectedItem] withAdress:[launchServerIP stringValue]];
		else{
			NSAlert *myAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"noJoinShort", @"") defaultButton:NSLocalizedString(@"continue", @"") alternateButton:NSLocalizedString(@"cancel", @"") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"noJoin", @"")];
			if([myAlert runModal] == 1)
				[games startGame:[gamePopUpButton titleOfSelectedItem]];
		}
	} 
	else
		[games startGame:[gamePopUpButton titleOfSelectedItem]];
	[NSApp stopModal];
}

- (IBAction)launchVoice:(id)sender
{
	[MyXfireVoice launchTeamspeakWithAdress:friendsVoiceIP];
}

	/****************************/
	/*    IP Override           */
	/****************************/

- (IBAction)applyOverride:(id)sender
{
	override = true;
	overrideVoice = true;
	NSScanner *scan = [NSScanner scannerWithString:[overrideField stringValue]];
	[scan scanUpToString:@":"intoString:&overridedIP];
	[scan scanString:@":"intoString:nil];
	[scan scanUpToString:@""intoString:&overridedPort];
	
	scan = [NSScanner scannerWithString:[voiceOverrideField stringValue]];
	[scan scanUpToString:@":"intoString:&overridedVoiceIP];
	[scan scanString:@":"intoString:nil];
	[scan scanUpToString:@""intoString:&overridedVoicePort];
	
	[overridedIP retain];
	[overridedPort retain];
	[overridedVoiceIP retain];
	[overridedVoicePort retain];
	
	NSString *voice = [MyXfireVoice voiceSoftwareRunning];
	if([voice isEqualToString:@"TeamSpeak"])
	   [xfire setVoiceStatus:32 withIP:overridedVoiceIP andPort:overridedVoicePort];
	else if([voice isEqualToString:@"Ventrilo"])
		[xfire setVoiceStatus:33 withIP:overridedVoiceIP andPort:overridedVoicePort];
	else if([voice isEqualToString:@"Mumble"])
		[xfire setVoiceStatus:34 withIP:overridedVoiceIP andPort:overridedVoicePort];
	else
		[xfire setVoiceStatus:0 withIP:@"0.0.0.0" andPort:@"0"];
	[NSApp stopModal];
}

- (IBAction)resetOverride:(id)sender
{
	[overrideField setStringValue:@""];
	[voiceOverrideField setStringValue:@""];
	[xfire setVoiceStatus:0 withIP:@"0.0.0.0" andPort:@"0"];
	override = false;
	overrideVoice = false;
	[NSApp stopModal];
}

	/****************************/
	/*    Updater               */
	/****************************/

- (IBAction)downloadUpdate:(id)sender
{
//	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://xfirebugs.infusion-soft.de/iFire.zip"]];
	[[NSWorkspace sharedWorkspace] openURL:[updater getURL]];

}

- (IBAction)checkForUpdates:(id)sender
{
	if(![updater checkForUpdatesWithWindow:updateWindow andInfoField:updateInfo andNotesView:releaseNotes]){
		NSAlert *myAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"noUpdateShort", @"") defaultButton:NSLocalizedString(@"ok", @"") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"noUpdate", @"")];
		[myAlert runModal];
	}
}

- (IBAction)startModal:(id)sender
{
	if([sender tag] == 5){
		if(![xfire loggedIn])
			return;
		[NSApp beginSheet:[nicknameField window] modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
		[NSApp runModalForWindow:[nicknameField window]];
		[NSApp endSheet:[nicknameField window]];
		[[nicknameField window] orderOut:self];
	}
	else if([sender tag] == 2){
		if(![xfire loggedIn])
			return;
		[NSApp beginSheet:[overrideField window] modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
		[NSApp runModalForWindow:[overrideField window]];
		[NSApp endSheet:[overrideField window]];
		[[overrideField window] orderOut:self];
	}
	else if([sender tag] == 3){
		if([xfire loggedIn]){
			[NSApp beginSheet:[launchServerIP window] modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
			[NSApp runModalForWindow:[launchServerIP window]];
			[NSApp endSheet:[launchServerIP window]];
			[[launchServerIP window] orderOut:self];
		}
		else
			[[launchServerIP window] makeKeyAndOrderFront:nil];
	}
	else if([sender tag] == 6){
		[searchWindow makeKeyAndOrderFront:self];
	}
}

- (IBAction)stopModal:(id)sender
{
	[NSApp stopModal];
}

- (IBAction)donate:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[[NSURL alloc] initWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=1571841"]];
}

- (IBAction)help:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"iFire" ofType:@"pdf"] withApplication:@"Preview"];
}

		/****************************/
		/*    Searching				*/
		/****************************/

- (IBAction)searchUser:(id)sender
{
	if(![[searchField stringValue] isEqualToString:@""] && [xfire loggedIn]){
		[xfire searchFriend:[searchField stringValue]];
		[searchProgress startAnimation:nil];
	}
}

- (IBAction)addSearchedUser:(id)sender;
{
	[invitationUsername setStringValue:[[searchResults objectAtIndex:[searchResultTable selectedRow]] objectForKey:@"name"]];
	[searchWindow orderOut:self];
	[NSApp beginSheet:invitationWindow modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[NSApp runModalForWindow:invitationWindow];
	[NSApp endSheet:invitationWindow];
    [invitationWindow orderOut:self];
}

- (void)updateSearchResults:(NSArray *)arr
{
	[searchResults release];
	searchResults = [[NSArray alloc] initWithArray:arr];
	[searchResultTable reloadData];
	[searchProgress stopAnimation:nil];
}


@end