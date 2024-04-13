/*
 *  sendserverlistquery.h
 *  xfirelib
 *
 *  Created by Florian on 06.01.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef __SENDSERVERLISTQUERY_H
#define __SENDSERVERLISTQUERY_H

#include "xfiresendpacketcontent.h"
#include <string>


#define XFIRE_SEND_SERVER_LIST_QUERY_PACKET 22

namespace xfirelib {
	class SendServerListQuery : public XFireSendPacketContent {
	public:
		virtual ~SendServerListQuery() { }
		int getPacketId() { return XFIRE_SEND_SERVER_LIST_QUERY_PACKET; }
		
		int getPacketContent(char *buf);
		int getPacketAttributeCount() { return 1; }
		int getPacketSize() { return 100; }
		
		long gameid;
	private:
		
	};
	
};


#endif