//
//  StatusBarController.m
//  MyTunesController
//
//  Created by Toomas Vahter on 21.01.12.
//  Copyright (c) 2012 Toomas Vahter. All rights reserved.
//

#import "StatusBarController.h"
#import "StatusView.h"
#import "iTunesController.h"

@implementation StatusBarController

@synthesize playButton = _playButton;
@synthesize statusView = _statusView;
@synthesize sparkleController = _sparkleController;

- (IBAction)playPrevious:(id)sender 
{
	[[iTunesController sharedInstance] playPrevious];
}


- (IBAction)playPause:(id)sender 
{
	[[iTunesController sharedInstance] playPause];
}


- (IBAction)playNext:(id)sender 
{
	[[iTunesController sharedInstance] playNext];
}


- (void)addStatusItems
{
	if (controllerItem == nil) 
	{
		NSImage *statusIcon = [NSImage imageNamed:@"status_icon.png"];
		controllerItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
		[controllerItem setImage:statusIcon];
		[controllerItem setHighlightMode:YES];
		
		NSMenu *mainMenu = [[NSMenu alloc] init];
		[mainMenu setAutoenablesItems:NO];
		
		NSMenuItem *theItem = [mainMenu addItemWithTitle:@"About"
												  action:@selector(showAboutPanel)
										   keyEquivalent:@""];
		[theItem setTarget:[NSApp delegate]];
		
		theItem = [mainMenu addItemWithTitle:@"Check for Updates..."
									  action:@selector(checkForUpdates:)
							   keyEquivalent:@""];
		[theItem setTarget:self.sparkleController];
		
		theItem = [mainMenu addItemWithTitle:@"Preferences..."
									  action:@selector(showPreferencesWindow)
							   keyEquivalent:@""];
		[theItem setTarget:[NSApp delegate]];
		
		[mainMenu addItem:[NSMenuItem separatorItem]];
		
		theItem = [mainMenu addItemWithTitle:@"Lyrics..."
									  action:@selector(showLyricsWindow)
							   keyEquivalent:@""];
		[theItem setTarget:[NSApp delegate]];
		
		[mainMenu addItem:[NSMenuItem separatorItem]];
		
		
		theItem = [mainMenu addItemWithTitle:@"Quit"
									  action:@selector(terminate:)
							   keyEquivalent:@"Q"];
		[theItem setTarget:NSApp];
		
		[controllerItem setMenu:mainMenu];
	}
	
	if (mainItem == nil) 
	{
		mainItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
		[mainItem setImage:[NSImage imageNamed:@"blank.png"]];
		[mainItem setView:self.statusView];
		[self updatePlayButtonState];
	}
}


- (void)updatePlayButtonState
{
	NSImage *playButtonImage = [NSImage imageNamed:[[iTunesController sharedInstance] isPlaying] ? @"pause" : @"play"];
	[self.playButton setImage:playButtonImage];
}

@end
