//
//  MyXfireWrapper.h
//  Xfire Mac Client
//
//  Created by Florian Bethke on 24.10.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "client.h"
#include "xfirepacket.h"
#include "loginfailedpacket.h"
#include "otherloginpacket.h"
#include "messagepacket.h"
#include "sendstatusmessagepacket.h"
#include "sendmessagepacket.h"
#include "invitebuddypacket.h"
#include "sendacceptinvitationpacket.h"
#include "senddenyinvitationpacket.h"
#include "sendremovebuddypacket.h"
#include "sendnickchangepacket.h"
#include "sendgamestatuspacket.h"
#include "sendgamestatus2packet.h"
#include "dummyxfiregameresolver.h"
#include "sendgameserverpacket.h"
#include "recvoldversionpacket.h"
#include "inviterequestpacket.h"
#include "loginsuccesspacket.h"
#include "recvremovebuddypacket.h"
#include "recvstatusmessagepacket.h"
#include "buddylistgamespacket.h"
#include "buddylistgames2packet.h"
#include "messageackpacket.h"
#include "sendtypingpacket.h"
#include "sendsearchfriendpacket.h"
#include "recvfriendsearchpacket.h"
#include "sendserverlistquery.h"
#include "recvserverlistquery.h"

using namespace xfirelib;

@class MyXfireController;

@interface MyXfireWrapper : NSObject {
	NSAutoreleasePool *pool;
	MyXfireController *controller;
	NSMutableDictionary *gameinfo, *voiceinfo;
	NSArray *myBuddyInfo, *statusInfo;
	bool loggedIn;
	bool loginFailed;
}
- (id)initWithController:(MyXfireController *)contrl;
- (void)disconnect;
- (void)loginWithUsername:(NSString *)username andPassword:(NSString *)password;
- (void)setStatusMessage:(NSString *)status;
- (void)changeNick:(NSString *)nick;
- (void)searchFriend:(NSString *)myfriend;
- (void)sendMessage:(NSString *)message toBuddy:(NSString *)buddy;
- (void)inviteBuddy:(NSString *)buddy withMessage:(NSString *)message;
- (void)removeBuddy:(NSString *)buddy;
- (void)acceptInvitation:(NSString *)buddy;
- (void)denyInvitation:(NSString *)buddy;
- (void)setGameStatus:(int)gameid withIP:(NSString *)aIP andPort:(long)aPort;
- (void)setVoiceStatus:(int)gameid withIP:(NSString *)aIP andPort:(NSString *)aPort;
- (void)printBuddylist;
- (void)receivedPacket:(XFirePacket *)packet;
- (void)resetStatus;
- (void)sendTypingNotification:(NSString *)username;
- (bool)loginFailed;
- (bool)loggedIn;
- (bool)update;
- (bool)getChange:(NSArray *)oldArray;
- (bool)getOnlineStatus:(int)buddyID;
- (int)getUserID:(int)buddyID;
- (int)getGameID:(int)buddyID;
- (int)getGame2ID:(int)buddyID;
- (int)getBuddyIDForKey:(NSString *)username;
- (int)buddiesOnline;
- (NSString *)getUsername:(int)buddyID;
- (NSString *)getNick:(int)buddyID;
- (NSString *)getStausMessage:(int)buddyID;
- (NSString *)getNicknameForUser:(NSString *)user;
- (NSString *)getUsernameForNick:(NSString *)nickname;
- (NSString *)buddyStatusChanged;
- (NSString *)compareOldArray:(NSArray *)oldArray withNewArray:(NSArray *)newArray;
- (NSMutableArray *)getBuddies;
- (NSMutableArray *)getBuddyInfo;
- (NSMutableDictionary *)getGameInfo;
- (NSMutableDictionary *)getVoiceInfo;

@end

class XfirePacketListener : public PacketListener {
	public:
		MyXfireWrapper *xfireWrapper;
		XfirePacketListener(MyXfireWrapper *wrapper);
		void receivedPacket( xfirelib::XFirePacket *packet );
};
