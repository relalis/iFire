//
//  MySmiley.m
//  iFire
//
//  Created by Florian on 01.08.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MySmiley.h"


@implementation MySmiley

- (id)init {
	if (self = [super init]) {
		/* Get list of all supported Emoticons */
		smileys = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Emoticons" ofType:@""]];
		
		/* Load all images */
		NSArray *arr = [smileys allValues];
		dict = [[NSMutableDictionary alloc] init];
		int i;
		for(i=0;i<[arr count];i++)
			[dict setObject:[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[arr objectAtIndex:i] ofType:@"png"]] forKey:[arr objectAtIndex:i]];
	}
	return self;
}

- (NSArray *)getEmoticonArray
{
	return [smileys allKeys];
}

- (NSArray *)getEmoticonImages
{
	return [dict allValues];
}

- (NSAttributedString *)getEmoticonStringForKey:(NSString *)key
{
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[smileys objectForKey:key] ofType:@"png"]];
	NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
	if ([(NSCell *)[attachment attachmentCell] respondsToSelector:@selector(setImage:)])
		[(NSCell *)[attachment attachmentCell] setImage:image];
	NSAttributedString *attributedString = [NSAttributedString attributedStringWithAttachment: attachment];
	
	return attributedString;
}

- (NSImage *)getEmoticonForKey:(NSString *)key
{
	return [dict objectForKey:[smileys objectForKey:key]];
}

- (NSString *)emoticonStringForIndex:(int)index
{
	return [[smileys allKeysForObject:[[dict allKeys] objectAtIndex:index-1]] objectAtIndex:0];
}

@end
