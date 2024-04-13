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



#ifndef __XDEBUG_H
#define __XDEBUG_H

#define RESET 0

#define BLACK  0
#define RED    1
#define GREEN  2
#define YELLOW 3
#define WHITE  7
#include <stdio.h>
#include <stdarg.h>
#include <pthread.h>

int printferr(char* fmt, ...);

  #define XDEBUG(args) { \
    printf( "[0;33;40m" ); \
    printf( "[%5d] XFireLibDEBUG(%25s,%4d): ", (int)pthread_self(), __FILE__, __LINE__ ); \
    printf args ; \
    printf( "[0;37;40m" ); \
  }

  #define XINFO(args)  { \
    printf( "[1;32;40m" ); \
    printf( "[%5d] XFireLibINFO (%25s,%4d): ", (int)pthread_self(), __FILE__, __LINE__ ); \
    printf args ; \
    printf( "[0;37;40m" ); \
  }
  #define XERROR(args) { \
    printf( "[1;31;40m" ); \
    printf( "[%5d] XFireLibERROR(%25s,%4d): ", (int)pthread_self(), __FILE__, __LINE__ ); \
    printf args ; \
    printf( "[0;37;40m" ); \
    fprintf( stderr, "[%5d] XFireLibERROR(%25s,%4d): ", (int)pthread_self(), __FILE__, __LINE__ ); \
    printferr args ; \
  }
#ifndef XENABLEDEBUG

  #undef XDEBUG
  #define XDEBUG(args)
  #ifndef XINFO
    #define XINFO(args)
  #endif
#endif


#endif

