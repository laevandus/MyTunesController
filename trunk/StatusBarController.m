//
//  StatusBarController.m
//  MyTunesController
//
//  Created by Toomas Vahter on 21.01.12.
//  Copyright (c) 2010 Toomas Vahter
//
//  This content is released under the MIT License (http://www.opensource.org/licenses/mit-license.php).
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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
