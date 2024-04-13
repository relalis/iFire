//
//  MyChatWindow.m
//  Xfire Mac
//
//  Created by Florian Bethke on 30.10.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MyChatWindow.h"
#import "MyXfireController.h"
#import "MyXfireWrapper.h"
#import "MySmiley.h"

@implementation MyChatWindow

- (id)init {
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"ChatWindow" owner:self];
		[chat setDelegate:self];
		open = false;
	}
	return self;
}

- (id)initWithController:(MyXfireController *)contrl andUsername:(NSString *)username
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"ChatWindow" owner:self];
			
		[chat setDelegate:self];
		open = false;
		controller = contrl;
		user = [[NSString alloc] initWithString:username];
		[textField setDelegate:self];
		oldRange = 0;
		
		NSArray *emoticonImages = [[controller smileyPointer] getEmoticonImages];
		int i;
		for(i=0;i<[emoticonImages count];i++){
			[smileyMenu addItemWithTitle:@""];
			[[smileyMenu lastItem] setImage:[emoticonImages objectAtIndex:i]];
		}
		
		[inputField setDelegate:self];
		NSLog(@"%f, %f", [chat frame].origin.x, [chat frame].origin.y);
		NSPoint point;
		point.x = [chat frame].origin.x +21;
		point.y = [chat frame].origin.y +245;
		
		[chat cascadeTopLeftFromPoint:point];
		
		timestampRange = NSMakeRange(11, 12);
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)run
{
	[chat makeKeyAndOrderFront:self];
	open = true;
}

- (void)setTitle:(NSString *)title
{
	[chat setTitle:title];
}

- (void)addString:(NSString *)string
{
	if([string isEqualToString:NSLocalizedString(@"nowOffline", @"")]){
		int oldLength = [[textField textStorage] length];
		[[[textField textStorage] mutableString] appendString: string];
		[[[textField textStorage] mutableString] appendString: @" "];
		int newLength = [[textField textStorage] length];
		NSRange range = NSMakeRange(oldLength, newLength - oldLength -1);
		NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor redColor], NSForegroundColorAttributeName,[NSFont boldSystemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName, NULL];
		[[textField textStorage] setAttributes:attrs range:range];
		[[textField textStorage] endEditing];
	}
	else if([string isEqualToString:NSLocalizedString(@"nowOnline", @"")]){
		int oldLength = [[textField textStorage] length];
		[[[textField textStorage] mutableString] appendString: string];
		[[[textField textStorage] mutableString] appendString: @" "];
		int newLength = [[textField textStorage] length];
		NSRange range = NSMakeRange(oldLength, newLength - oldLength -1);
		NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor greenColor], NSForegroundColorAttributeName,[NSFont boldSystemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName, NULL];
		[[textField textStorage] setAttributes:attrs range:range];
		[[textField textStorage] endEditing];
	}
	else
		[[[textField textStorage] mutableString] appendString: string];
	
	NSRange insertAtEnd = NSMakeRange([[textField textStorage] length],0);
	[textField scrollRangeToVisible:insertAtEnd];
	[typingNotification setStringValue:@""];

	[self searchEmoticons];
//	[self searchURLS];
}

- (NSString *)title
{
	return [chat title];
}

- (NSString *)username
{
	return user;
}

- (BOOL)windowShouldClose:(id)sender
{
	open = true;
	[controller removeChatWindow:[self title]];
	return true;
}

- (bool)windowOpen
{
	return open;
}

- (void)sendMessage:(id)sender
{	if(![[controller xfirePointer] getOnlineStatus:[[controller xfirePointer] getBuddyIDForKey:user]]){
		[[[textField textStorage] mutableString] appendString: @"The Message could not be sent (your buddy is offline) \n"];
		return;
	} 
	if(![[sender stringValue] isEqualToString:@""]){
		/* Highlight your username in the Chat */
		int oldLength = [[textField textStorage] length];
		[[[textField textStorage] mutableString] appendString: [controller getUsername]];
		[[[textField textStorage] mutableString] appendString: @" ("];
		
		int newLength = [[textField textStorage] length];
		
		/* TIMESTAMP */
		unichar *buffer = (unichar *)calloc( [[[NSDate date] description] length], sizeof( unichar ) );
		[[[NSDate date] description] getCharacters:buffer range:timestampRange];
		NSString *timestamp = [NSString stringWithCharacters:buffer length:8];
		free(buffer);
		[[[textField textStorage] mutableString] appendString: timestamp];
		[[[textField textStorage] mutableString] appendString: @"): "];
		NSDictionary *attrs2 = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor grayColor], NSForegroundColorAttributeName,[NSFont boldSystemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName, NULL];
		[[textField textStorage] setAttributes:attrs2 range:NSMakeRange(newLength - 1, 11)];
		/* TIMESTAMP */
		
		NSRange nicknameRange = NSMakeRange(oldLength, newLength - oldLength - 1);
		NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor blueColor], NSForegroundColorAttributeName,[NSFont boldSystemFontOfSize:[NSFont systemFontSize]], NSFontAttributeName, NULL];
		[[textField textStorage] setAttributes:attrs range:nicknameRange];
		[[textField textStorage] endEditing];
		/*************************************/
		[[[textField textStorage] mutableString] appendString: [sender stringValue]];
		[[[textField textStorage] mutableString] appendString: @"\n"];
		[[controller xfirePointer] sendMessage:[sender stringValue] toBuddy:user];
		NSRange insertAtEnd = NSMakeRange([[textField textStorage] length],0);
		[textField scrollRangeToVisible:insertAtEnd];
		
		//Sound abspielen
		[controller playSoundForKey:@"soundSent"];
	}
	[sender setStringValue:@""];
	[sender becomeFirstResponder];
	[self searchEmoticons];
	[self searchURLS];
}

- (void)setIsTyping
{
	if(counter != 0){
		NSString *str = [NSString stringWithFormat:NSLocalizedString(@"typing", @""), [self title]];
		[typingNotification setStringValue:str];
	}
	counter = 0;
}

- (void)update
{
	if(typing == 0)
		[[controller xfirePointer] sendTypingNotification:user];
	counter +=1;
	typing  +=1;
	
	/* Remove typingNotification after 11 seconds without a new notification */
	
	if(counter == 11)
		[typingNotification setStringValue:@""];
}

- (void)searchEmoticons
{
	NSTextStorage* textStorage=[textField textStorage];
	NSString* string=[textStorage string];
	NSRange searchRange=NSMakeRange(oldRange, [string length] - oldRange);
	NSRange foundRange;
	int currentSmiley = 0;
	int count = [[[controller smileyPointer] getEmoticonArray] count];
	bool loop = true;
	
	[textStorage beginEditing];
	while(loop)
	{
		NSString *currentSmileyString = [[[controller smileyPointer] getEmoticonArray] objectAtIndex:currentSmiley];
		foundRange=[string rangeOfString:currentSmileyString options:0 range:searchRange];

		if (foundRange.length > 0) {

			searchRange.location=foundRange.location+foundRange.length;
			searchRange.length = [string length]-searchRange.location-[currentSmileyString length];
					
			[textStorage replaceCharactersInRange:foundRange withString:@""];
			[self insertEmoticon:[[controller smileyPointer] getEmoticonForKey:currentSmileyString] inRange:foundRange];
		}
		else {
			currentSmiley += 1;
			if(currentSmiley == count)
				loop = false;
		}

	 }
	[textStorage endEditing];
	oldRange = [[textStorage string] length];
}

- (void)searchURLS
{

	NSTextStorage* textStorage=[textField textStorage];
	NSString* string=[textStorage string];
	NSRange searchRange=NSMakeRange(oldURLRange, [string length] - oldURLRange);
	NSRange foundRange;

	[textStorage beginEditing];
	do {
		//We assume that all URLs start with http://
		foundRange=[string rangeOfString:@"http://" options:0 range:searchRange];

		if (foundRange.length > 0) { //Did we find a URL?
		  NSURL* theURL;
		  NSDictionary* linkAttributes;
		  NSRange endOfURLRange;

		  //Restrict the searchRange so that it won't find the same string again
		  searchRange.location=foundRange.location+foundRange.length;
		  searchRange.length = [string length]-searchRange.location;

		  //We assume the URL ends with whitespace
                  endOfURLRange=[string rangeOfCharacterFromSet:
                     [NSCharacterSet whitespaceAndNewlineCharacterSet]
		     options:0 range:searchRange];
			 
			 endOfURLRange.location -= 1;

	         //The URL could also end at the end of the text.  The next line fixes it in case it does
	         if (endOfURLRange.length==0)  // BUGFIX - was location == 0
                   endOfURLRange.location=[string length]-1;

	         //Set foundRange's length to the length of the URL
	         foundRange.length = endOfURLRange.location-foundRange.location+1;
			 
	         //grab the URL from the text
                  theURL=[NSURL URLWithString:[string substringWithRange:foundRange]];
				  NSLog(@"%@", [string substringWithRange:foundRange]);

	         //Make the link attributes
	         linkAttributes= [NSDictionary dictionaryWithObjectsAndKeys: theURL, NSLinkAttributeName,
                      [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName,
                      [NSColor blueColor], NSForegroundColorAttributeName,
                      NULL];

	         //Finally, apply those attributes to the URL in the text
	         [textStorage setAttributes:linkAttributes range:foundRange];
		}

	 } while (foundRange.length!=0); //repeat the do block until it no longer finds anything

	[textStorage endEditing];
	oldURLRange = [[textStorage string] length];
}

- (void)insertEmoticon:(NSImage *)smiley inRange:(NSRange)range
{
	NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
	[(NSCell *)[attachment attachmentCell] setImage:smiley];
	NSAttributedString *attributedString = [NSAttributedString attributedStringWithAttachment: attachment];
	[[textField textStorage] insertAttributedString:attributedString atIndex:range.location];
}

- (IBAction)smileySelected:(id)sender
{
	NSString *smileyString = [[[controller smileyPointer] emoticonStringForIndex:[sender indexOfSelectedItem]] retain];
	NSString *inputString = [NSString stringWithFormat:@"%@ %@ ", [inputField stringValue], smileyString];
	[inputField setStringValue:inputString];
}

- (void)controlTextDidChange:(NSNotification *)nd
{
	if(![[controller xfirePointer] getOnlineStatus:[[controller xfirePointer] getBuddyIDForKey:user]])
		return;
	if(typing > 5)
		typing = 0;
//	[[controller xfirePointer] sendTypingNotification:user];
}

- (BOOL)textView:(NSTextView*)textView clickedOnLink:(id)link atIndex:(unsigned)charIndex {
     BOOL success;
     success=[[NSWorkspace sharedWorkspace] openURL: link];
	 NSLog(@"Clicked on Link: %@", link);
     return success;
}

- (NSTextStorage *)textStorage
{
	return [textField textStorage];
}

@end
