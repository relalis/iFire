/*
 *  recvserverlistquery.cpp
 *  xfirelib
 *
 *  Created by Florian on 06.01.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#include "recvserverlistquery.h"

#include <vector>
#include <string>
#include "xfireparse.h"
#include "variablevalue.h"
#include "xdebug.h"

namespace xfirelib {
	using namespace std;
	
	RecvServerListQuery::RecvServerListQuery() {
		ips = 0;
		ports = 0;
	}
	RecvServerListQuery::~RecvServerListQuery() {
		if(ips) {
			for( vector<char*>::iterator it = ips->begin() ;
				it != ips->end() ; it++) {
				delete[] *it;
			}
		}
		delete ips;
		delete ports;
	}
	
	void RecvServerListQuery::parseContent(char *buf, int length, int numberOfAtts) {
/*		int index = 0;
		int numberOfSids = 0;
		VariableValue val;
		
		index ++; // Ignore 03
		index ++; // Ignore 02
		
		index += val.readValue(buf,index,2);
		long game = val.getValueAsLong();
		printf("GameID: %i \n", game);
	
		index ++;
		index ++;
		index ++;	// 22
		index ++;	// 04
		index ++;	// 02
		numberOfSids = (unsigned char) buf[index];
		index ++;
		printf("Number: %i\n", numberOfSids);
		
		ips = new vector<char *>;
		for(int i = 0 ; i < numberOfSids ; i++) {
			index += val.readValue(buf,index,4);
			char *ip = new char[4];
			memcpy(ip,val.getValue(),4);
			printf("IP: %u.%u.%u.%u\n", ip[0], ip[1], ip[2], ip[3]);
			ips->push_back(ip);
		}
*/		
	/*	index ++; // Ignore 00
		index ++;
		sids = new vector<char *>;
		for(int i = 0 ; i < numberOfSids ; i++) {
			index += val.readValue(buf,index,16);
			char *sid = new char[16];
			memcpy(sid,val.getValue(),16);
			sids->push_back(sid);
		}
		
		index += val.readName(buf,index);
		index ++; // Ignore 04
		index ++; // Ignore 03
		numberOfSids = (unsigned char) buf[index];
		index ++; // Ignore 00
		index ++;
		
		gameids = new vector<long>;
		gameids2 = new vector<long>;
		for(int i = 0 ; i < numberOfSids ; i++) {
			index += val.readValue(buf,index,2);
			long game = val.getValueAsLong();
			index += val.readValue(buf,index,2);
			long game2 = val.getValueAsLong();
			gameids->push_back(game);
			gameids2->push_back(game2);
		}
		
		index += val.readName(buf,index);
		index ++; // Ignore 04
		index ++; // Ignore 03
		numberOfSids = (unsigned char) buf[index];
		index ++; // Ignore 00
		index ++;
		
		ips = new vector<char *>;
		for(int i = 0 ; i < numberOfSids ; i++) {
			index += val.readValue(buf,index,4);
			char *ip = new char[4];
			memcpy(ip,val.getValue(),4);
			ips->push_back(ip);
		}
		
		index += val.readName(buf,index);
		index ++; // Ignore 04
		index ++; // Ignore 03
		numberOfSids = (unsigned char) buf[index];
		index ++; // Ignore 00
		index ++;
		
		ports = new vector<long>;
		for(int i = 0 ; i < numberOfSids ; i++) {
			index += val.readValue(buf,index,2);
			long port = val.getValueAsLong();
			printf("Port: %i\n", port);
			ports->push_back(port);
		} */
	}
	
};