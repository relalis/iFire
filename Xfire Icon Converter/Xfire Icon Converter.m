#import <Foundation/Foundation.h>

int main (int argc, const char * argv[]) {
	if(argc < 2){
		printf("Usage: Xfire Icon Converter <icons.dll>\n");
		return 1;
	}
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString *path = [NSString stringWithUTF8String:argv[1]];
//	NSString *path = @"/Users/Flo/Desktop/icons.dll";
	NSString *tempstring;
	NSMutableArray *names = [[NSMutableArray alloc] init];
	NSData *myData = [[NSData alloc] initWithContentsOfFile:path];
	[[NSFileManager defaultManager] createDirectoryAtPath:@"Xfire Icons" attributes:nil];
	NSRange myRange;
	myRange.length = 0;
	myRange.location = 0;
	int length = [myData length];
	int offset = 0;
	int namelength = 0;
	int i = 0;
	bool ICONS = false;
	unsigned short buffer;
		
	while(!ICONS && myRange.location<length){		//Offset suchen
		myRange.length = 2;
		[myData getBytes:(char*)&buffer range:myRange];
		myRange.location += 2;
		if(buffer == 0x0049){
			[myData getBytes:(char*)&buffer range:myRange];
			myRange.location += 2;
			if(buffer == 0x0043){
				[myData getBytes:(char*)&buffer range:myRange];
				myRange.location += 2;
				if(buffer == 0x004F){
					[myData getBytes:(char*)&buffer range:myRange];
					myRange.location += 2;
					if(buffer == 0x004E){
						[myData getBytes:(char*)&buffer range:myRange];
						myRange.location += 2;
						if(buffer == 0x0053){
							offset = myRange.location;
							ICONS = true;		//ICONS gefunden
						}
					}
				}
			}
		}
	}
	if(!ICONS)
		return 1;

	while(myRange.location<length){			// Namen der Icons suchen
		NSMutableString *name = [[NSMutableString alloc] init];
		[myData getBytes:(char*)&buffer range:myRange];
		namelength = buffer;
		if(namelength == 0)
			break;
		for(i=0;i<namelength+1;i++){
			myRange.location += 2;
			[myData getBytes:(char*)&buffer range:myRange];
			tempstring = [NSString stringWithUTF8String:(char*)&buffer];
			if(i == namelength)
				break;
			[name appendString:tempstring];
		}
		[names addObject:name];
	}
	
	for(i=0;i<[names count];i++){		// Icon Daten suchen & schreiben
		NSMutableData *iconData = [[NSMutableData alloc] init];
		while(1){
			[myData getBytes:(char*)&buffer range:myRange];
			myRange.location += 2;
			if(buffer == 0x4150){
				if(i == [names count]-1)
				break;
				[myData getBytes:(char*)&buffer range:myRange];
				if(buffer == 0x0000){
					myRange.location += 2;
					[myData getBytes:(char*)&buffer range:myRange];
					myRange.location -= 2;
					if(buffer == 0x0001)
						break;
				}
			}
			[iconData appendBytes:&buffer length:2];
		}
		[iconData writeToFile:[NSString stringWithFormat:@"Xfire Icons/%@", [names objectAtIndex:i]] atomically:NO];
		[iconData release];
	}


    [pool drain];
    return 0;
}
