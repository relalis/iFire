//
//  MySmiley.h
//  iFire
//
//  Created by Florian on 01.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MySmiley : NSObject {
	NSDictionary *smileys;
	NSMutableDictionary *dict;
}

- (NSArray *)getEmoticonArray;
- (NSArray *)getEmoticonImages;
- (NSAttributedString *)getEmoticonStringForKey:(NSString *)key;
- (NSImage *)getEmoticonForKey:(NSString *)key;
- (NSString *)emoticonStringForIndex:(int)index;
@end