//
//  MyXfireWrapper.m
//  Xfire Mac Client
//
//  Created by Florian Bethke on 24.10.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MyXfireWrapper.h"
#import "MyXfireController.h"
#import "MyGrowl.h"
#import "MyXfireGames.h"
#import "MyXfireOverlay.h"
#include "stdio.h"

@implementation MyXfireWrapper

Client *client;
XfirePacketListener *packetListener;

- (id)initWithController:(MyXfireController *)contrl
{
	if(self == [super init]){
		controller = contrl;
		gameinfo = [[NSMutableDictionary alloc] init];
		statusInfo = [[NSArray alloc] init];
		voiceinfo = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[gameinfo release];
	[super dealloc];
}

- (void)disconnect
{
	client->disconnect();
	delete client;
	client = 0;
	loggedIn = false;
}

- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password
{
	packetListener = new XfirePacketListener(self);
	client = new Client();
    client->setGameResolver( new DummyXFireGameResolver() );
	client->connect([username UTF8String],[password UTF8String]);
	client->addPacketListener( packetListener);
	myBuddyInfo = [self getBuddyInfo];
}

- (void)setStatusMessage:(NSString *)status
{
	if(!loggedIn)
		return;
	SendStatusMessagePacket *packet = new SendStatusMessagePacket();
	packet->awaymsg = [status UTF8String];
	client->send( packet );
	delete packet;
}

- (void)changeNick:(NSString *)nick
{
	if(!loggedIn)
		return;
	SendNickChangePacket nickname;
	nickname.nick = [nick UTF8String];
	client->send( &nickname );
	NSLog(@"Nickname geaendert: %@", nick);
}

- (void)searchFriend:(NSString *)myfriend
{
	if(!loggedIn)
		return;
	SendSearchFriendPacket search;
	search.name = [myfriend UTF8String];
	search.fname = search.lname = search.email = [@"" UTF8String];
	client->send( &search );
}

- (void)sendMessage:(NSString *)message toBuddy:(NSString *)buddy
{
	if(!loggedIn)
		return;
	SendMessagePacket msg;
	msg.init(client, [buddy UTF8String], [message UTF8String]);
	client->send( &msg );
}

- (void)inviteBuddy:(NSString *)buddy withMessage:(NSString *)message
{
	if(!loggedIn)
		return;
	InviteBuddyPacket invite;
	invite.addInviteName( [buddy UTF8String], [message UTF8String]);
	client->send( &invite );
	NSLog(@"Einladung gesendet!");
}

- (void)removeBuddy:(NSString *)buddy
{
	if(!loggedIn)
		return;
	BuddyListEntry *entry = client->getBuddyList()->getBuddyByName([buddy UTF8String]);
	if(entry == NULL) {
		NSLog(@"Name in buddylist nicht gefunden");
	    return;
	}
	SendRemoveBuddyPacket removeBuddy;
	removeBuddy.userid = entry->userid;
	client->send( &removeBuddy );
	NSLog(@"Buddy entfernt!");
}

- (void)acceptInvitation:(NSString *)buddy
{
	if(!loggedIn)
		return;
	SendAcceptInvitationPacket accept;
	accept.name = [buddy UTF8String];
	client->send( &accept );
	NSLog(@"Einladung angenommen!");
}

- (void)denyInvitation:(NSString *)buddy
{
	if(!loggedIn)
		return;
	SendDenyInvitationPacket deny;
	deny.name = [buddy UTF8String];
	client->send( &deny );
	NSLog(@"Einladung abgelehnt!");
}

- (void)queryServerListForGame:(int)gameid
{
	if(!loggedIn)
		return;
	SendServerListQuery query;
	query.gameid = gameid;
	client->send( &query );
}

- (void)setGameStatus:(int)gameid withIP:(NSString *)aIP andPort:(long)aPort
{
	if(!loggedIn)
		return;
	SendGameStatusPacket *packet = new SendGameStatusPacket();
	packet->gameid = gameid;
	char ip[4] = {0,0,0,0};
	
	if(aIP){
		NSArray *arr = [aIP componentsSeparatedByString:@"."];

		char ip1 = [[NSNumber numberWithInt:[[arr objectAtIndex:0] intValue]] charValue];
		char ip2 = [[NSNumber numberWithInt:[[arr objectAtIndex:1] intValue]] charValue];
		char ip3 = [[NSNumber numberWithInt:[[arr objectAtIndex:2] intValue]] charValue];
		char ip4 = [[NSNumber numberWithInt:[[arr objectAtIndex:3] intValue]] charValue];
			
		ip[3] = ip1;
		ip[2] = ip2;
		ip[1] = ip3;
		ip[0] = ip4;
	}
		
	memcpy(packet->ip,ip,4);
	packet->port = aPort;
	client->send( packet );
	delete packet;
}

- (void)setVoiceStatus:(int)gameid withIP:(NSString *)aIP andPort:(NSString *)aPort
{
	if(!loggedIn)
		return;
	SendGameStatus2Packet *packet = new SendGameStatus2Packet;
	packet->gameid = gameid;
	char ip[4] = {0,0,0,0};
	
	if(aIP){
		NSArray *arr = [aIP componentsSeparatedByString:@"."];
		
		char ip1 = [[NSNumber numberWithInt:[[arr objectAtIndex:0] intValue]] charValue];
		char ip2 = [[NSNumber numberWithInt:[[arr objectAtIndex:1] intValue]] charValue];
		char ip3 = [[NSNumber numberWithInt:[[arr objectAtIndex:2] intValue]] charValue];
		char ip4 = [[NSNumber numberWithInt:[[arr objectAtIndex:3] intValue]] charValue];
		
		ip[3] = ip1;
		ip[2] = ip2;
		ip[1] = ip3;
		ip[0] = ip4;
	}
	memcpy(packet->ip,ip,4);
	packet->port = [aPort intValue];
	client->send( packet );
	delete packet;
}

- (void)printBuddylist
{
	printf("Buddy List: (* marks online users)\n");
	printf("----------------- Buddy List --------------------------------------------------------\n");
	printf("  %20s | %20s | %10s | %20s | %7s | %7s\n","User Name", "Nick", "UserId", "Status Msg" ,"Gameid" ,"Gameid2" );
	vector<BuddyListEntry*> *entries = client->getBuddyList()->getEntries();
	for(uint i = 0 ; i < entries->size() ; i ++) {
		BuddyListEntry *entry = entries->at(i);
		printf("%1s %20s | %20s | %10ld | %20s | %7ld | %ld\n",
		(entry->isOnline() ? "*" : ""),
		entry->username.c_str(),
		entry->nick.c_str(),
		entry->userid,
		entry->statusmsg.c_str(),
		entry->game,
		entry->game2);
      }
      printf("-------------------------------------------------------------------------------------\n\n");
}

- (void)receivedPacket:(XFirePacket *)packet
{
	pool = [[NSAutoreleasePool alloc] init];
	[controller updateBuddylist];
    XFirePacketContent *content = packet->getContent();
//	NSLog(@"%i", content->getPacketId());
    switch(content->getPacketId()) 
	{
		case XFIRE_LOGIN_FAILED_ID:
		/*	client->disconnect();
			delete client;
			client = 0;
		*/	loginFailed = true;
			[controller loginFailed];
		break;
		
		case XFIRE_LOGIN_SUCCESS_ID:
			loggedIn = true;
			NSLog(@"Login erfolgreich");
		break;
    
		case XFIRE_MESSAGE_ID: 
		{
			BuddyListEntry *entry = client->getBuddyList()->getBuddyBySid( ((MessagePacket*)content)->getSid() );
			if( (( MessagePacket*)content)->getMessageType() == 0){
				NSString *message = [NSString stringWithUTF8String:(const char*)((MessagePacket*)content)->getMessage().c_str()];
				NSString *username = [NSString stringWithUTF8String:entry->username.c_str()];
			//	NSLog(@"%@ from User: %@", message, username);
				[controller addString:message fromUser:username];
				NSString *name = [self getNicknameForUser:username];
				if(![name isEqualToString:@""])
					username = name;
				[[controller growlPointer] postNotificationWithTitle:username andDescription:message andName:NSLocalizedString(@"msgSent", @"") clickContext:username];
				[MyXfireOverlay receivedMessage:message fromUser:username];
			//	[self queryServerListForGame:5186];
			}
			else if( (( MessagePacket*)content)->getMessageType() == 3){
				NSString *username = [NSString stringWithUTF8String:entry->username.c_str()];
				[controller buddyIsTyping:username];
			}

		break;
		}
		case XFIRE_MESSAGE_ACK_ID:
		//	NSLog(@"Nachricht angekommen...");
		break;
	
		case XFIRE_RECV_OLDVERSION_PACKET_ID:
			NSLog(@"Protocol too old!");
        break;
    
		case XFIRE_PACKET_INVITE_REQUEST_PACKET:
		{
			cout << "Invitation Request: " << endl;
			InviteRequestPacket *invite = (InviteRequestPacket*)content;
			cout << "  Name   :  " << invite->name << endl;
			cout << "  Nick   :  " << invite->nick << endl;
			cout << "  Message:  " << invite->msg << endl;
			NSAlert *myAlert = [NSAlert alertWithMessageText:@"Accept Invitation?" defaultButton:@"Accept" alternateButton:@"Decline" otherButton:nil informativeTextWithFormat:@"The User %@(%@) wants to add you to his buddylist. \n %@", [NSString stringWithUTF8String:invite->name.c_str()], [NSString stringWithUTF8String:invite->nick.c_str()], [NSString stringWithUTF8String:invite->msg.c_str()]];
			[[controller growlPointer] postNotificationWithTitle:[NSString stringWithUTF8String:invite->name.c_str()] andDescription:NSLocalizedString(@"authRequest", @"") andName:NSLocalizedString(@"authRequest", @"") clickContext:nil];
			if([myAlert runModal] == 1)
				[self acceptInvitation:[NSString stringWithUTF8String:invite->name.c_str()]];
			else
				[self denyInvitation:[NSString stringWithUTF8String:invite->name.c_str()]];
		break;
		}
    
		case XFIRE_OTHER_LOGIN:
			[controller otherLogin];
			[self resetStatus];
		break;
    
		case XFIRE_BUDDYS_NAMES_ID:
			[controller updateBuddylist];
		break;
		
		case XFIRE_RECVREMOVEBUDDYPACKET:
			[controller updateBuddylist];
		break;

		case XFIRE_RECV_STATUSMESSAGE_PACKET_ID:
			[controller updateBuddylist];
		break;

		case XFIRE_BUDDYS_GAMES_ID:	// Game
		{
			BuddyListGamesPacket *p = (BuddyListGamesPacket*)content;
			vector<char *> *ips		= p->ips;
			vector<long> *ports		= p->ports;
			vector<char *> *sids	= p->sids;
			
			for(uint i=0;i<sids->size();i++){
				unsigned char *sid	= (unsigned char*)sids->at(i);
				BuddyListEntry *myEntry = client->getBuddyList()->getBuddyBySid((const char*)sid);
				if(myEntry){
					unsigned char *ip	= (unsigned char*)ips->at(i);
					long port			= ports->at(i);
					NSMutableArray *myArray = [[NSMutableArray alloc] init];
					NSNumber *myPort = [NSNumber numberWithUnsignedLong:port];
					NSNumber *myUser = [NSNumber numberWithUnsignedLong:myEntry->userid];

					for(uint j=0;j<4;j++){
						NSNumber *myNum = [NSNumber numberWithUnsignedInt:ip[j]];
						[myArray addObject:myNum];
					}

					[myArray addObject:myPort];
					[gameinfo setObject:myArray forKey:myUser];
					
					NSString *game = [[controller gamesPointer] getNameForKey:[NSString stringWithFormat:@"%d", p->gameids->at(0)]];
					NSString *nick = [NSString stringWithUTF8String:myEntry->nick.c_str()];
					NSString *user = [NSString stringWithUTF8String:myEntry->username.c_str()];
					if(![nick isEqualToString:@""])
						user = nick;
					NSString *text = [NSString stringWithFormat:NSLocalizedString(@"playing", @""), user, game];
					
					if(p->gameids->at(0) != 0)
						[[controller growlPointer] postNotificationWithTitle:user andDescription:text andName:NSLocalizedString(@"msgSent", @"") clickContext:nil];
					//	NSLog(@"%@ is now playing %@", [NSString stringWithUTF8String:myEntry->username.c_str()], [[controller gamesPointer] getNameForKey:[NSString stringWithFormat:@"%d", p->gameids->at(0)]]);
				}
			}
			[controller updateBuddylist];
		//	[self printBuddylist];
		break;
		}
		case XFIRE_BUDDYS_GAMES2_ID:	// Voice
		{
			BuddyListGames2Packet *p2 = (BuddyListGames2Packet*)content;
			vector<char *> *ips2		= p2->ips;
			vector<long> *ports2		= p2->ports;
			vector<char *> *sids2	= p2->sids;
			
			for(uint i=0;i<sids2->size();i++){
				unsigned char *sid	= (unsigned char*)sids2->at(i);
				BuddyListEntry *myEntry = client->getBuddyList()->getBuddyBySid((const char*)sid);
				if(myEntry){
					unsigned char *ip	= (unsigned char*)ips2->at(i);
					long port			= ports2->at(i);
					NSMutableArray *myArray = [[NSMutableArray alloc] init];
					NSNumber *myPort = [NSNumber numberWithUnsignedLong:port];
					NSNumber *myUser = [NSNumber numberWithUnsignedLong:myEntry->userid];
					
					for(uint j=0;j<4;j++){
						NSNumber *myNum = [NSNumber numberWithUnsignedInt:ip[j]];
						[myArray addObject:myNum];
					}
					
					[myArray addObject:myPort];
					[voiceinfo setObject:myArray forKey:myUser];
				}
			}
			[controller updateBuddylist];
		break;
		}
		case XFIRE_RECV_FRIEND_SEARCH_ID:
		{
			NSMutableArray *results = [NSMutableArray array];
			RecvFriendSearchPacket *search = (RecvFriendSearchPacket *)content;
			vector<string> *names = search->names;
			vector<string> *fnames = search->fnames;
			vector<string> *lnames = search->lnames;
			for (uint i=0;i<names->size();i++){
				NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:names->at(i).c_str()], @"name",
																				[NSString stringWithUTF8String:fnames->at(i).c_str()], @"fname",
																				[NSString stringWithUTF8String:lnames->at(i).c_str()], @"lname", nil];
				[results addObject:dict];
			}
			[controller updateSearchResults:results];
		break;
		}
		case XFIRE_RECV_SERVER_LIST_QUERY_ID:
			break;
    }
	[pool release];
}

- (void)resetStatus
{
	loginFailed = false;
	loggedIn = false;
}

- (void)sendTypingNotification:(NSString *)username
{
	if(!loggedIn)
		return;
	SendTypingPacket typing; 
	typing.init(client, [username UTF8String]); 
	client->send( &typing ); 
}

- (bool)loginFailed
{
	return loginFailed;
}

- (bool)loggedIn
{
	return loggedIn;
}

- (bool)update
{
	if([self getChange:myBuddyInfo]){
		myBuddyInfo = [self getBuddyInfo];
		return true;
	}
	return false;
}

- (bool)getChange:(NSArray *)oldArray
{
	if(![oldArray isEqualToArray:[self getBuddyInfo]]){
		[self printBuddylist];
		return true;
	}
	return false;
}

- (bool)getOnlineStatus:(int)buddyID
{
	if(!loggedIn)
		return false;
	vector<BuddyListEntry*> *entries = client->getBuddyList()->getEntries();
	BuddyListEntry *entry = entries->at(buddyID);
	return entry->isOnline();
}

- (int)getUserID:(int)buddyID
{
	if(!loggedIn)
		return 0;
	vector<BuddyListEntry*> *entries = client->getBuddyList()->getEntries();
	BuddyListEntry *entry = entries->at(buddyID);
	return entry->userid;
}

- (int)getGameID:(int)buddyID
{
	if(!loggedIn)
		return 0;
	vector<BuddyListEntry*> *entries = client->getBuddyList()->getEntries();
	BuddyListEntry *entry = entries->at(buddyID);
	return entry->game;
}

- (int)getGame2ID:(int)buddyID
{
	if(!loggedIn)
		return 0;
	vector<BuddyListEntry*> *entries = client->getBuddyList()->getEntries();
	BuddyListEntry *entry = entries->at(buddyID);
	return entry->game2;
}

- (int)getBuddyIDForKey:(NSString *)username
{
	if(!loggedIn)
		return 0;
	NSArray *buddies = [self getBuddies];
	int i;
	for(i=0;i<[buddies count];i++){
		if([[buddies objectAtIndex:i] isEqualToString:username]){
			return i;
		}
	}
	return 0;
}

- (int)buddiesOnline
{
	NSArray *buddies = [self getBuddies];
	int i, count = 0;
	for(i=0;i<[buddies count];i++){
		if([self getOnlineStatus:i])
			count += 1;
	}
	
	return count;
}

- (NSString *)getUsername:(int)buddyID
{
	if(!loggedIn)
		return nil;
	vector<BuddyListEntry*> *entries = client->getBuddyList()->getEntries();
	BuddyListEntry *entry = entries->at(buddyID);
	NSString *name = [NSString stringWithUTF8String:entry->username.c_str()];
	return name;
}

- (NSString *)getNick:(int)buddyID
{
	if(!loggedIn)
		return nil;
	vector<BuddyListEntry*> *entries = client->getBuddyList()->getEntries();
	BuddyListEntry *entry = entries->at(buddyID);
	NSString *nick = [NSString stringWithUTF8String:entry->nick.c_str()];
	return nick;
}

- (NSString *)getStausMessage:(int)buddyID
{
	if(!loggedIn)
		return nil;
	vector<BuddyListEntry*> *entries = client->getBuddyList()->getEntries();
	BuddyListEntry *entry = entries->at(buddyID);
	NSString *msg = [NSString stringWithUTF8String:entry->statusmsg.c_str()];
	return msg;
}

- (NSString *)getNicknameForUser:(NSString *)user
{
	if(!loggedIn)
		return nil;
	NSArray *buddies = [self getBuddies];
	int i;
	
	for(i=0;i<[buddies count];i++){
		NSString *name			= [self getUsername:i];
		NSString *nick			= [self getNick:i];
		if([name isEqualToString:user])
			return nick;
	}
	return nil;
}

- (NSString *)getUsernameForNick:(NSString *)nickname
{
	if(!loggedIn)
		return nil;
	NSArray *buddies = [self getBuddies];
	int i;
	
	for(i=0;i<[buddies count];i++){
		NSString *name			= [self getUsername:i];
		NSString *nick			= [self getNick:i];
		if([nick isEqualToString:nickname])
			return name;
	}
	return nil;
}

- (NSString *)buddyStatusChanged
{
	if(!loggedIn)
		return nil;
	NSMutableArray *offlineArray = [[NSMutableArray alloc] init];
	NSArray *buddies = [self getBuddies];
	NSString *returnString = nil;
	bool change = false;
	int i;
	for(i=0;i<[buddies count];i++){
		NSNumber *onlineStatus	= [NSNumber numberWithBool:[self getOnlineStatus:i]];
		NSString *name			= [self getUsername:i];
		if(![onlineStatus boolValue])
			[offlineArray addObject:name];
	}

	if(![offlineArray isEqualToArray:statusInfo]){
		change = true;
		returnString = [self compareOldArray:statusInfo withNewArray:offlineArray];
	}
	
	[statusInfo release];
	statusInfo =  offlineArray;
	
	if(!change)
		returnString = [NSString string];

	return returnString;
}

- (NSString *)compareOldArray:(NSArray *)oldArray withNewArray:(NSArray *)newArray
{
	int i, count;
	NSString *oldString, *newString;
	if([oldArray count] < [newArray count])
		count = [newArray count];
	else if([oldArray count] > [newArray count])
		count = [oldArray count];
	else
		return nil;
	
	for(i=0;i<count;i++){
		if([oldArray count] <= i)
			oldString = [NSString string];
		else
			oldString = [oldArray objectAtIndex:i];
		if([newArray count] <= i)
			newString = [NSString string];
		else
			newString = [newArray objectAtIndex:i];
			
		if(![oldString isEqualToString:newString]){
			if(count == [newArray count])
				return [newString retain];
			else
				return [oldString retain];
		}
	}
	
	return nil;
}

- (NSMutableArray *)getBuddies
{
	if(!loggedIn)
		return nil;
	NSMutableArray *buddylist = [[NSMutableArray alloc] init];
	vector<BuddyListEntry*> *entries = client->getBuddyList()->getEntries();
	
		for(uint i = 0 ; i < entries->size() ; i ++) {
			BuddyListEntry *entry = entries->at(i);
			NSString *name = [NSString stringWithUTF8String:entry->username.c_str()];
			[buddylist addObject:name];
      }
	  return buddylist;
}

- (NSMutableArray *)getBuddyInfo
{
	if(!loggedIn)
		return nil;
	NSMutableArray *buddyInfo = [[[NSMutableArray alloc] init] autorelease];
	NSMutableArray *onlineArray = [[NSMutableArray alloc] init];
	NSMutableArray *offlineArray = [[NSMutableArray alloc] init];
	NSMutableArray *awayArray = [[NSMutableArray alloc] init];
	NSArray *buddies = [self getBuddies];
	int i;
	for(i=0;i<[buddies count];i++){
		NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
		NSNumber *onlineStatus	= [NSNumber numberWithBool:[self getOnlineStatus:i]];
		NSNumber *userID		= [NSNumber numberWithInt:[self getUserID:i]];
		NSNumber *gameID		= [NSNumber numberWithInt:[self getGameID:i]];
		NSNumber *game2ID		= [NSNumber numberWithInt:[self getGame2ID:i]];
		NSString *name			= [self getUsername:i];
		NSString *nick			= [self getNick:i];
		NSString *msg			= [self getStausMessage:i];
		
		[info setObject:name forKey:@"name"];
		[info setObject:onlineStatus forKey:@"onlineStatus"];
		[info setObject:userID forKey:@"userID"];
		[info setObject:gameID forKey:@"gameID"];
		[info setObject:game2ID forKey:@"game2ID"];
		[info setObject:nick forKey:@"nick"];
		[info setObject:msg forKey:@"msg"];
		
		if(![onlineStatus boolValue])
			[offlineArray addObject:info];
		else if([msg isEqualToString:@"Online"])
			[onlineArray addObject:info];
		else if([msg isEqualToString:@""])
			[onlineArray addObject:info];
		else
			[awayArray addObject:info];

		[info			release];
	}
	[buddyInfo addObjectsFromArray:onlineArray];
	[buddyInfo addObjectsFromArray:awayArray];
	[buddyInfo addObjectsFromArray:offlineArray];
	
	[onlineArray	release];
	[awayArray		release];
	[offlineArray	release];
	[buddies		release];
	
	return buddyInfo;
}

- (NSMutableDictionary *)getGameInfo
{
	return gameinfo;
}

- (NSMutableDictionary *)getVoiceInfo
{
	return voiceinfo;
}

 XfirePacketListener::XfirePacketListener(MyXfireWrapper *wrapper)
{
	xfireWrapper = wrapper;
}

void XfirePacketListener::receivedPacket(XFirePacket *packet) 
{
	[xfireWrapper receivedPacket:packet];
}

@end
