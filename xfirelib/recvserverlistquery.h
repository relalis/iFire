/*
 *  recvserverlistquery.h
 *  xfirelib
 *
 *  Created by Florian on 06.01.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef __RECVSERVERLISTQUERY_H
#define __RECVSERVERLISTQUERY_H

#define XFIRE_RECV_SERVER_LIST_QUERY_ID 150

#include <vector>
#include <string>

#include "xfirerecvpacketcontent.h"
#include "variablevalue.h"


namespace xfirelib {
	using namespace std;
	
	class RecvServerListQuery : public XFireRecvPacketContent {
	public:
		RecvServerListQuery();
		virtual ~RecvServerListQuery();
		
		XFirePacketContent* newPacket() { return new RecvServerListQuery(); }
		
		virtual int getPacketId() { return XFIRE_RECV_SERVER_LIST_QUERY_ID; }
		int getPacketContent(char *buf) { return 0; }
		int getPacketAttributeCount() { return 0; };
		int getPacketSize() { return 1024; };
		virtual void parseContent(char *buf, int length, int numberOfAtts);
		
		long gameid;
		vector<char *> *ips;
		vector<long> *ports;
	};
};


#endif