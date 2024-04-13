/*
 *  xfirelib - C++ Library for the xfire protocol.
 *  Copyright (C) 2006 by
 *          Beat Wolf <asraniel@fryx.ch> / http://gfire.sf.net
 *          Herbert Poul <herbert.poul@gmail.com> / http://goim.us
 *    http://xfirelib.sphene.net
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
 */


#include <iostream>
#include <vector>
#include "buddylist.h"
#include "buddylistonlinepacket.h"
#include "buddylistgamespacket.h"
#include "buddylistgames2packet.h"
#include "recvremovebuddypacket.h"
#include "recvstatusmessagepacket.h"
#include "xdebug.h"


namespace xfirelib {
  using namespace std;

  BuddyList::BuddyList(Client *client) {
    entries = new vector<BuddyListEntry *>;
    this->client = client;
    this->client->addPacketListener( this );
  }
  BuddyList::~BuddyList() {
    for(vector<BuddyListEntry *>::iterator it = entries->begin();
	it != entries->end(); it++) {
      delete *it;
    }
    delete entries;
  }

  BuddyListEntry *BuddyList::getBuddyById(long userid) {
    for(uint i = 0 ; i < entries->size() ; i++) {
      BuddyListEntry *entry = entries->at(i);
      if(entry->userid == userid)
	return entry;
    }
    XDEBUG(( "Unable to find buddy with id %ld\n", userid ));
    return 0;
  }

  BuddyListEntry *BuddyList::getBuddyByName(string username) {
    for(uint i = 0 ; i < entries->size() ; i++) {
      BuddyListEntry *entry = entries->at(i);
      if(entry->username == username)
	return entry;
    }
    return 0;
  }

  BuddyListEntry *BuddyList::getBuddyBySid(const char *sid) {
    for(uint i = 0 ; i < entries->size() ; i++) {
      BuddyListEntry *entry = entries->at(i);

      if(memcmp((void *)sid,(void *)entry->sid,16) == 0)
	return entry;

    }
    return 0;
  }


  void BuddyList::initEntries(BuddyListNamesPacket *buddyNames) {
    for(uint i = 0 ; i < buddyNames->usernames->size() ; i++) {
      BuddyListEntry *entry = new BuddyListEntry;
      entry->username = buddyNames->usernames->at(i);
      entry->userid = buddyNames->userids->at(i);
      entry->nick = buddyNames->nicks->at(i);
      entries->push_back(entry);
    }
  }
  void BuddyList::updateOnlineBuddies(BuddyListOnlinePacket* buddiesOnline) {
    for(uint i = 0 ; i < buddiesOnline->userids->size() ; i++) {
      BuddyListEntry *entry = getBuddyById( buddiesOnline->userids->at(i) );
        if(entry){
         entry->setSid( buddiesOnline->sids->at(i) );
        }else{
         XDEBUG(("Could not find buddy with this sid!\n"));
        }
    }
  }

  void BuddyList::updateBuddiesGame(BuddyListGamesPacket* buddiesGames) {
    bool isFirst = buddiesGames->getPacketId() == XFIRE_BUDDYS_GAMES_ID;
    for(uint i = 0 ; i < buddiesGames->sids->size() ; i++) {
      BuddyListEntry *entry = getBuddyBySid( buddiesGames->sids->at(i) );
      if(entry){
	if(isFirst) {
	  entry->game = buddiesGames->gameids->at(i);
	  delete entry->gameObj; entry->gameObj = NULL;
	} else {
	  entry->game2 = buddiesGames->gameids->at(i);
	  delete entry->game2Obj; entry->game2Obj = NULL;
	}
	XDEBUG(( "Resolving Game ... \n" ));
	XFireGameResolver *resolver = client->getGameResolver();
	if(resolver) {
	  XDEBUG(( "Resolving Game ... \n" ));
	  if(isFirst)
	    entry->gameObj = resolver->resolveGame( entry->game, i, buddiesGames );
	  else
	    entry->game2Obj = resolver->resolveGame( entry->game2, i, buddiesGames );
	} else {
	  XDEBUG(( "No GameResolver ? :(\n" ));
	}
	XDEBUG(( "%s: Game (%ld): %s / Game2 (%ld): %s\n",
		 entry->username.c_str(),
		 entry->game,
		 (entry->gameObj == NULL ? "UNKNOWN" : entry->gameObj->getGameName().c_str()),
		 entry->game2,
		 (entry->game2Obj== NULL ? "UNKNOWN" :entry->game2Obj->getGameName().c_str())
		 ));
      }else{
        XDEBUG(("Could not find buddy with this sid!\n"));
      }
    }
  }

  void BuddyList::receivedPacket(XFirePacket *packet) {
    XFirePacketContent *content = packet->getContent();
    if(content == 0) return;
    XDEBUG(( "hmm... %d\n", content->getPacketId() ));
    switch(content->getPacketId()) {
    case XFIRE_BUDDYS_NAMES_ID: {
      XINFO(( "Received Buddy List..\n" ));
      this->initEntries( (BuddyListNamesPacket*)content );
      break;
    }
    case XFIRE_BUDDYS_ONLINE_ID: {
      XINFO(( "Received Buddy Online Packet..\n" ));
      this->updateOnlineBuddies( (BuddyListOnlinePacket *)content );
      break;
    }
    case XFIRE_BUDDYS_GAMES2_ID:
    case XFIRE_BUDDYS_GAMES_ID: {
      XINFO(( "Recieved the game a buddy is playing..\n" ));
      this->updateBuddiesGame( (BuddyListGamesPacket *)content );
    }
    case XFIRE_RECVREMOVEBUDDYPACKET: {
      RecvRemoveBuddyPacket *p = (RecvRemoveBuddyPacket*)content;
      XDEBUG(( "Buddy was removed from contact list (userid: %ld)\n", p->userid ));
      std::vector<BuddyListEntry *>::iterator i = entries->begin();
      while( i != entries->end() ) {
	if((*i)->userid == p->userid) {
	  BuddyListEntry *buddy = *i;
	  XINFO(( "%s (%s) was removed from BuddyList.\n", buddy->username.c_str(), buddy->nick.c_str() ));
	  p->username = buddy->username;
	  entries->erase(i);
	  // i.erase();
	  break; // we are done.
	}
	++i;
      }
      break;
    }
    case XFIRE_RECV_STATUSMESSAGE_PACKET_ID: {
      RecvStatusMessagePacket *status = (RecvStatusMessagePacket*) content;

     for(uint i = 0 ; i < status->sids->size() ; i++) {
        BuddyListEntry *entry = getBuddyBySid( status->sids->at(i) );
        if(entry == NULL) {
            XERROR(( "No such Entry - Got StatusMessage from someone who is not in the buddylist ??\n" ));
            return;
        }
        entry->statusmsg = status->msgs->at(i).c_str();
    }

      break;
    }
    }
  }


  BuddyListEntry::BuddyListEntry() {
    memset(sid,0,16);
    statusmsg = std::string();
    game = 0;
    game2 = 0;
    gameObj = NULL;
    game2Obj = NULL;
  }

  BuddyListEntry::~BuddyListEntry() {
    delete gameObj;
    delete game2Obj;
  }

  bool BuddyListEntry::isOnline() {
    for(int i = 0 ; i < 16 ; i++) {
      if(sid[i]) return true;
    }
    return false;
  }
  void BuddyListEntry::setSid(const char *sid) {
    memcpy(this->sid,sid,16);
  }
};

