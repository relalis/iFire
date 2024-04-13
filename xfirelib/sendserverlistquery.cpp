/*
 *  sendserverlistquery.cpp
 *  xfirelib
 *
 *  Created by Florian on 06.01.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#include "sendserverlistquery.h"

#include "variablevalue.h"
#include "xdebug.h"

namespace xfirelib {
	
	int SendServerListQuery::getPacketContent(char *buf) {
		VariableValue val;
		val.setName( "gameid" );
		val.setValueFromLong(gameid,4);		
		int index = 0;
		buf[index++] = 33;
		buf[index++] = 02;
		index += val.writeValue(buf, index);
//		printf("Sending2...");
		
		return index;
	}
	
	
};