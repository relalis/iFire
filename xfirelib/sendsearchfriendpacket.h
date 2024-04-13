/*
 *  sendsearchfriendpacket.h
 *  xfirelib
 *
 *  Created by Florian on 06.01.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef _SENDSEARCHFRIENDPACKET_H_
#define _SENDGAMESTATUSPACKET_H_

#include "xfiresendpacketcontent.h"
#include <string.h>

#define XFIRE_SEND_SEARCH_FRIEND_PACKET 12

namespace xfirelib {
	using namespace std;
	
	class SendSearchFriendPacket : public XFireSendPacketContent {
	public:
		SendSearchFriendPacket();
		int getPacketId() { return XFIRE_SEND_SEARCH_FRIEND_PACKET; }
		
		int getPacketContent(char *buf);
		int getPacketAttributeCount() { return 4; }
		int getPacketSize() { return 100; }
		
		string name;
		string fname, lname, email;
		
	};
	
};
#endif //_SENDSEARCHFRIENDPACKET_H_