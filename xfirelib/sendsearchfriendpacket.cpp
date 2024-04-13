/*
 *  sendsearchfriendpacket.cpp
 *  xfirelib
 *
 *  Created by Florian on 06.01.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#include "sendsearchfriendpacket.h"
#include "variablevalue.h"
#include "xdebug.h"
#include <string.h>

namespace xfirelib {
	
	SendSearchFriendPacket::SendSearchFriendPacket() {
		name = fname = lname = email = "";
	}
	
	int SendSearchFriendPacket::getPacketContent(char *buf) {
		VariableValue val;
		int index = 0;
		
		val.setName( "name" );
		val.setValue((char*)name.c_str(),name.size());
		index += val.writeName(buf, index);
		buf[index++] = 01;
	    buf[index++] = name.size();
		buf[index++] = 0;
		index += val.writeValue(buf, index);
		
		val.setName( "fname" );
		val.setValue((char*)fname.c_str(),fname.size());
		index += val.writeName(buf, index);
		buf[index++] = 01;
		buf[index++] = fname.size();
		buf[index++] = 0;
		index += val.writeValue(buf, index);
		
		val.setName( "lname" );
		val.setValue((char*)lname.c_str(),lname.size());
		index += val.writeName(buf, index);
		buf[index++] = 01;
		buf[index++] = lname.size();
		buf[index++] = 0;
		index += val.writeValue(buf, index);
		
		val.setName( "email" );
		val.setValue((char*)email.c_str(),email.size());
		index += val.writeName(buf, index);
		buf[index++] = 01;
		buf[index++] = email.size();
		buf[index++] = 0;
		index += val.writeValue(buf, index);
		
		
		return index;
	}
	
	
};
