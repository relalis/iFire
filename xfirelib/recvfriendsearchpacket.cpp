/*
 *  recvfriendsearchpacket.cpp
 *  xfirelib
 *
 *  Created by Florian on 06.01.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#include "recvfriendsearchpacket.h"
#include <vector>
#include <string>

#include "xfireparse.h"
#include "variablevalue.h"
#include "xdebug.h"

namespace xfirelib {
	using namespace std;

	RecvFriendSearchPacket::RecvFriendSearchPacket() {
		names = 0;
		fnames = 0;
		lnames = 0;
	}
	RecvFriendSearchPacket::~RecvFriendSearchPacket() {
		delete names;
		delete fnames;
		delete lnames;
	}
	
	void RecvFriendSearchPacket::parseContent(char *buf, int length, int numberOfAtts) {
		int index = 0;
		VariableValue results;
		
		index += results.readName(buf,index);
		index ++; // Ignore 04
		names = new vector<string>;
		index = readStrings(names,buf,index);
	//	printf("Username: %s\n", names->at(1).c_str());
		
		index += results.readName(buf,index);
		index ++; // Ignore 04
		fnames = new vector<string>;
		index = readStrings(fnames,buf,index);
	//	printf("Vorname: %s\n", fnames->at(1).c_str());
		
		index += results.readName(buf,index);
		index ++; // Ignore 04
		lnames = new vector<string>;
		index = readStrings(lnames,buf,index);
	//	printf("Nachname: %s\n", lnames->at(1).c_str());
	}
	
	int RecvFriendSearchPacket::readStrings(vector<string> *strings, char *buf, int index) {
		VariableValue friends;
		index += friends.readValue(buf,index);
		index ++; // Ignore 00
		int numberOfStrings = friends.getValueAsLong();
		XDEBUG(( "name: %s numberOfStrings: %d\n", friends.getName().c_str(), numberOfStrings ));
		for(int i = 0 ; i < numberOfStrings ; i++) {
			int length = (unsigned char)buf[index++];
			index++;
			index += friends.readValue(buf,index,length);
			string stringvalue = string(friends.getValue(),length);
			strings->push_back(stringvalue);
			XDEBUG(( "String length: %2d : %s\n", length, stringvalue.c_str() ));
		}
		return index;
	}

}