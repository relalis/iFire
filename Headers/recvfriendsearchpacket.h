/*
 *  recvfriendsearchpacket.h
 *  xfirelib
 *
 *  Created by Florian on 06.01.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef __RECVFRIENDSEARCHPACKET_H
#define __RECVFRIENDSEARCHPACKET_H

#define XFIRE_RECV_FRIEND_SEARCH_ID 143

#include <vector>
#include <string>

#include "xfirerecvpacketcontent.h"
#include "variablevalue.h"


namespace xfirelib {
	using namespace std;
	
	class RecvFriendSearchPacket : public XFireRecvPacketContent {
	public:
		RecvFriendSearchPacket();
		virtual ~RecvFriendSearchPacket();
		
		XFirePacketContent* newPacket() { return new RecvFriendSearchPacket(); }
		
		int getPacketId() { return XFIRE_RECV_FRIEND_SEARCH_ID; }
		int getPacketContent(char *buf) { return 0; }
		int getPacketAttributeCount() { return 0; };
		int getPacketSize() { return 1024; };
		void parseContent(char *buf, int length, int numberOfAtts);
		
		//private:
		int readStrings(vector<string> *strings, char *buf, int index);
		
		vector<string> *names;
		vector<string> *fnames;
		vector<string> *lnames;
		vector<string> *emails;
	};
};


#endif