/* MyXfireController */

#import <Cocoa/Cocoa.h>

@class MyXfireWrapper;
@class MyXfireGames;
@class MyXfireNetwork;
@class MyXfireUpdater;
@class MySmiley;
@class MyGrowl;
@class MyTableView;
@class AGKeychain;
@class MyQstatWrapper;
@class MyTabbedChatWindow;

@interface MyXfireController : NSObject
{
	/****************************/
	/*    IBOutlets             */
	/****************************/
	
	/* Login Window */
	IBOutlet NSWindow *loginWindow;
    IBOutlet NSButton *autoLoginBox;
    IBOutlet NSButton *savePasswordBox;
    IBOutlet NSTextField *usernameField;
    IBOutlet NSSecureTextField *passwordField;
    IBOutlet NSProgressIndicator *progressIndicator;

	/* Preferences */
	IBOutlet NSWindow *prefWin;
    IBOutlet NSButton *autoLoginBox2;
    IBOutlet NSButton *savePasswordBox2;
	IBOutlet NSButton *enableNetworkBox;
    IBOutlet NSButton *noIPBox;
	IBOutlet NSButton *autosizeBox;
    IBOutlet NSTextField *interfaceField;			// Not implemented
	IBOutlet NSPopUpButton *soundOff;
	IBOutlet NSPopUpButton *soundOn;
	IBOutlet NSPopUpButton *soundSent;
	IBOutlet NSPopUpButton *soundRecieved;
	IBOutlet NSButton *bounceBox;
	IBOutlet NSButton *drawerBox;
	IBOutlet NSButton *gameInfoBox;
	IBOutlet NSTableView *statusTable;
	IBOutlet NSButton *showOfflineBox;
	
	/* Main Window */
    IBOutlet NSWindow *mainWindow;
	IBOutlet MyTableView *buddyList;
    IBOutlet NSTextField *drawerInfo;
    IBOutlet NSButton *joinGameButton;
    IBOutlet NSPopUpButton *statusPopUpMenu;
    IBOutlet NSButton *visitProfile;
    IBOutlet NSDrawer *infoDrawer;
	IBOutlet NSTextView *playerList;
    IBOutlet NSTableView *playerinfoTable;
	IBOutlet NSButton *joinVoiceButton;
	
	/* Invitation Window */
    IBOutlet NSWindow *invitationWindow;
    IBOutlet NSTextField *invitationMessage;
    IBOutlet NSTextField *invitationUsername;
	
	/* Game Launcher */
    IBOutlet NSPopUpButton *gamePopUpButton;
    IBOutlet NSTextField *launchServerIP;
	
	/*Supported Games */
    IBOutlet NSTableView *installedGameList;
    IBOutlet NSTableView *macGameList;
    IBOutlet NSTableView *pcGameList;

	/* Updater */
	IBOutlet NSWindow *updateWindow;
	IBOutlet NSTextField *updateInfo;
	IBOutlet NSTextView *releaseNotes;
	
	/* Gaming Info */
    IBOutlet NSTextField *myGame;
    IBOutlet NSImageView *myGameIcon;
    IBOutlet NSTextField *myIP;
    IBOutlet NSTextField *myStatusField;
    IBOutlet NSTextField *myUserName;
	
	/* Nickname Window */
    IBOutlet NSTextField *nicknameField;
	
	/* Manuell IP Window */
    IBOutlet NSTextField *overrideField;
	IBOutlet NSTextField *voiceOverrideField;
	
	/* Context Menu */
    IBOutlet NSMenu *contextMenu;
	IBOutlet NSMenuItem *joinGameMenu;
	
	/* Donation */
	IBOutlet NSWindow *donationWindow;
	
	/* Search */
	IBOutlet NSWindow *searchWindow;
	IBOutlet NSTextField *searchField;
	IBOutlet NSTableView *searchResultTable;
	IBOutlet NSProgressIndicator *searchProgress;
		
	/****************************/
	/*    Variables             */
	/****************************/

	/* Classes */
	MyXfireWrapper *xfire;
	MyXfireGames *games;
	MyXfireNetwork *net;
	MyXfireUpdater *updater;
	MySmiley *smiley;
	MyGrowl *growl;
	MyQstatWrapper *qstat;
	MyTabbedChatWindow *tchat;
	
	/* Array containing all chat windows */
	NSMutableArray *chats;

	/* Images */
	NSImage *red;
	NSImage *green;
	NSImage *orange;
	NSImage *haken;
	NSImage *kreuz;
	
	/* Strings for Server IP detection*/
	NSString *localIP;
	NSString *theIP;
	NSString *thePort;
	NSString *overridedIP, *overridedVoiceIP;
	NSString *overridedPort, *overridedVoicePort;
	NSString *tsPort;
	NSString *tsIP;
	NSString *friendsVoiceIP;
	
	/* Stuff needed for the NSTableView */
	NSTextFieldCell *myTextCell;
	NSImageCell *myImageCell;
	NSMutableArray *statusArray;
	NSDictionary *serverData;
	NSMutableArray *playerData, *scoreData;
	NSArray *searchResults;
	
	/* Path to the sound files */
	NSMutableDictionary *soundPaths;

	/* Other variables, some unused */
	int sameAddress;
	int tim;
	int buddiesOnline;
	int teamspeak;
	bool getTSInfo;
	bool dontContinue;
	bool override, overrideVoice;
	bool firstNotification;
	bool tabbed;
	int oldLength, newLength;
	
	/* Toolbar */
	NSDictionary *toolbarItems;
}
	
	/****************************/
	/*     Methodes				*/
	/****************************/
	
/* Notifications and other things*/
- (void)awakeFromNib;
- (void)applicationDidFinishLaunching:(NSNotification*)notification;
- (void)applicationDidBecomeActive:(NSNotification*)notification;
- (void)copyData:(NSFileHandle*)handle;
	
/* Pointers */	
- (MyXfireWrapper *)xfirePointer;
- (MySmiley *)smileyPointer;
- (MyGrowl *)growlPointer;	
- (MyXfireGames *)gamesPointer;

/* Chatting */
- (bool)chattingWithBuddy:(NSString *)buddy;
- (void)setString:(NSString *)string;
- (void)setString:(NSString *)string forUser:(NSString *)user;
- (void)addString:(NSString *)string fromUser:(NSString *)user;
- (void)playSoundForKey:(NSString *)key;
- (void)removeChatWindow:(NSString *)name;
- (void)openChatWindow:(NSString *)name;
- (void)buddyIsTyping:(NSString *)username;
- (void)buddy:(NSString *)buddy isOnline:(bool)isOnline;

/* Getting nicknames and usernames */
- (NSString *)getUsername;
- (NSString *)getNickForUser:(NSString *)user;	// Not working

/* Logging in and out*/
- (bool)login;
- (void)otherLogin;
- (void)loginFailed;
- (void)logout;

/* Preferences and registering Xfire-URL*/
- (void)loadPrefs;
- (void)saveData;
- (void)registerMyApp;
- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;

/* Updating Buddylist, Drawer and Statusmenu */
- (void)updateBuddylist;
- (void)updateDrawer;
- (void)updateStatusMenu;
- (void)update:(NSTimer *)timer;

/* Tableviews */
- (void)doubleclick;
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row;
//- (void)tableView:(NSTableView *)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn;
- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation;

	/****************************/
	/*    IBActions             */
	/****************************/

/* Add/Remove Buddies */
- (IBAction)addBuddy:(id)sender;
- (IBAction)removeBuddy:(id)sender;
- (IBAction)sendInvitaion:(id)sender;
- (IBAction)newChat:(id)sender;

/* Login Window */
- (IBAction)login:(id)sender;
- (IBAction)getPassword:(id)sender;				// Unused
- (IBAction)registerUser:(id)sender;			// Unused

/* Main Window */
- (IBAction)tableClick:(id)sender;
- (IBAction)visitProfile:(id)sender;
- (IBAction)joinGame:(id)sender;
- (IBAction)popupClick:(id)sender;
- (IBAction)startModal:(id)sender;
- (IBAction)stopModal:(id)sender;

/* Preferences */
- (IBAction)applyPrefs:(id)sender;
- (IBAction)chooseSound:(id)sender;
- (IBAction)addStatus:(id)sender;
- (IBAction)removeStatus:(id)sender;

/* Change Nickname */
- (IBAction)changeNickname:(id)sender;

/* Launch Game */
- (IBAction)launchGame:(id)sender;
- (IBAction)launchVoice:(id)sender;

/* IP Override */
- (IBAction)applyOverride:(id)sender;
- (IBAction)resetOverride:(id)sender;

/* Updater */
- (IBAction)downloadUpdate:(id)sender;
- (IBAction)checkForUpdates:(id)sender;

/* Donation */
- (IBAction)donate:(id)sender;

/* Help */
- (IBAction)help:(id)sender;

/* Search */
- (IBAction)searchUser:(id)sender;
- (IBAction)addSearchedUser:(id)sender;
- (void)updateSearchResults:(NSArray *)arr;

@end
