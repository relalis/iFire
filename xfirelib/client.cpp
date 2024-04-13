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


#include "xdebug.h"
#include "client.h"
#include "clientinformationpacket.h"
#include "clientversionpacket.h"
#include "xfirepacket.h"
#include "authpacket.h"
#include "clientloginpacket.h"
#include "buddylistnamespacket.h"
#include "messagepacket.h"
#include "sendmessagepacket.h"
#include "messageackpacket.h"
#include "recvoldversionpacket.h"
#include "sendkeepalivepacket.cpp"
#include <iostream>

//#define UINT_8 unsigned char
//#define UINT_32 unsigned long

namespace xfirelib {

using namespace std; 

  Client::Client(string xfireHost, int xfirePort) {
    XDEBUG(("Client constructor ...\n"));
    readthread = 0;
    sendpingthread = 0;
    gameResolver = NULL;
    packetReader = new PacketReader(NULL);
    packetReader->addPacketListener( this );
    buddyList = new BuddyList( this );
    protocolVersion = 1000; 
    _xfireHost = xfireHost;
    _xfirePort = xfirePort;
  }
  
  Client::~Client(){
    XDEBUG(("Client destructor ...\n"));
    this->disconnect();
    delete username;
    delete password;
    delete buddyList;
    delete packetReader;
    delete socket;
  }

  void Client::connect( string username, string password ) {
    try {
      this->username = new string(username);
      this->password = new string(password);
      socket = new Socket( _xfireHost, _xfirePort );
      packetReader->setSocket(socket);
      startThreads();
      //packetReader->startListening();


      socket->send("UA01");
      XDEBUG(("Sent UA01\n"));
      ClientInformationPacket *infoPacket = new ClientInformationPacket();
      this->send( infoPacket );
      delete infoPacket;
      XINFO(("sent ClientInformationPacket\n"));

      ClientVersionPacket *versionPacket = new ClientVersionPacket();
      versionPacket->setProtocolVersion( protocolVersion);
      this->send( versionPacket );
      delete versionPacket;
      XINFO(("sent ClientVersionPacket\n"));
    } catch( SocketException ex ) {
      XERROR(("Socket Exception ?! %s \n",ex.description().c_str() ));
    }
  }
  XFireGameResolver *Client::getGameResolver() {
    return gameResolver;
  }
  void Client::startThreads() {
    void* (*func)(void*) = &xfirelib::Client::startReadThread;
    XINFO(("About to start thread\n"));
    pthread_create( &readthread, NULL, func, (void*)this );
    void* (*func2)(void*) = &xfirelib::Client::startSendPingThread;
    pthread_create( &sendpingthread, NULL, func2, (void*)this );
  }
  void *Client::startReadThread(void *ptr) {
    try {
      ((Client*)ptr)->packetReader->run();
    } catch (SocketException ex) {
      XERROR(("Socket Exception ?! %s \n",ex.description().c_str() ));
      //((Client*)ptr)->disconnect();
    }
    return NULL;
  }
  void *Client::startSendPingThread(void *ptr) {
    Client *me = (Client*)ptr;
    while(1) {
      sleep(60 * 3); // Sleep for 3 minutes
      XDEBUG(( "Sending KeepAlivePacket\n" ));
      SendKeepAlivePacket packet;
      if(!me->send( &packet )) {
	XINFO(( "Could not send KeepAlivePacket... exiting thread.\n" ));
	break;
      }
    }
    return NULL;
  }

  void Client::disconnect() {
    int r;

    if(readthread && sendpingthread) {
      XDEBUG(( "cancelling readthread ... %d\n", (int)readthread ));
      r = pthread_cancel (readthread);
      if(!r) XERROR(( "error while cancelling thread %d ... (%d)\n", (int)readthread, r ));
      XDEBUG(( "cancelling sendpingthread ... %d\n", (int)sendpingthread ));
      
      r = pthread_cancel (sendpingthread);
      if(!r) XERROR(( "error while cancelling thread %d ... (%d)\n", (int)readthread, r ));
      XDEBUG(( "deleting socket ...\n" ));
      readthread = 0; sendpingthread = 0;
    }

    if(socket){
        delete socket;
        socket = NULL;
    }
    XDEBUG(( "done\n" ));
  }

  bool Client::send( XFirePacketContent *content ) {
    if(!socket) {
      XERROR(( "Trying to send content packet altough socket is NULL ! (ignored)\n" ));
      return false;
    }
    XFirePacket *packet = new XFirePacket(content);
    packet->sendPacket( socket );
    delete packet;
    return true;
  }

  void Client::addPacketListener( PacketListener *listener ) {
    packetReader->addPacketListener( listener );
  }


  void Client::receivedPacket( XFirePacket *packet ) {
    XDEBUG(("Client::receivedPacket\n"));
    if( packet == NULL ) {
      XERROR(("packet is NULL !!!\n"));
      return;
    }
    if( packet->getContent() == NULL ) {
      XERROR(("ERRRR getContent() returns null ?!\n"));
      return;
    }
    XFirePacketContent *content = packet->getContent();

    switch( content->getPacketId() ) {
    case XFIRE_PACKET_AUTH_ID: {
      XINFO(("Got Auth Packet .. Sending Login\n"));
      AuthPacket *authPacket = (AuthPacket*)packet->getContent();

      ClientLoginPacket *login = new ClientLoginPacket();
      login->setSalt( authPacket->getSalt() );
      login->setUsername( *username );
      login->setPassword( *password );
      send( login );
      delete login;
      break;
    }

    case XFIRE_MESSAGE_ID: {
      XDEBUG(( "Got Message, sending ACK\n" ));
        MessagePacket *message = (MessagePacket*)packet->getContent();
        if(message->getMessageType() == 0){
            MessageACKPacket *ack = new MessageACKPacket();
            memcpy(ack->sid,message->getSid(),16);
            ack->imindex = message->getImIndex();
            send( ack );
	    delete ack;
        }else if(message->getMessageType() == 2){
            send(message);
        }
	break;
    }

    default:
      cout << "Nothing here ... " << endl;
      break;
    }

  }
};
