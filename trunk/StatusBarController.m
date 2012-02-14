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
#import "LyricsFetcher.h"


@interface StatusBarController()

@property (nonatomic) NSUInteger processedTracksCount;
@property (nonatomic) NSUInteger totalTracksCount;
@property (nonatomic) BOOL isFetchingAllLyrics;

- (void)addStatusBarControllerObservers;
- (void)removeStatusBarControllerObservers;

- (void)updateProgressMenuItem;

- (void)toggleFetchingAllLyrics;
- (void)startFetchingAllLyrics;
- (void)stopFetchingAllLyrics;
@end

@implementation StatusBarController

@synthesize processedTracksCount = _processedTracksCount;
@synthesize totalTracksCount = _totalTracksCount;
@synthesize isFetchingAllLyrics = _isFetchingAllLyrics;

@synthesize playButton = _playButton;
@synthesize statusView = _statusView;
@synthesize sparkleController = _sparkleController;


- (id)init 
{
    if ((self = [super init])) 
	{
        [self addStatusBarControllerObservers];
    }
	
    return self;
}


- (void)dealloc 
{
    [self removeStatusBarControllerObservers];
}


#pragma mark Actions

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


#pragma mark KVO

static void *FetchingAllLyricsContext = "FetchingAllLyricsContext";

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
    if (context == FetchingAllLyricsContext) 
	{
		if ([keyPath isEqualToString:@"processedTracksCount"]) 
		{
			if (self.totalTracksCount > 0 && self.processedTracksCount == self.totalTracksCount) 
			{
				self.isFetchingAllLyrics = NO;
			}
		}
		
		NSArray *modes = [[NSArray alloc] initWithObjects:NSRunLoopCommonModes, nil];
		[[NSRunLoop currentRunLoop] performSelector:@selector(updateProgressMenuItem) target:self argument:nil order:1 modes:modes];
    } 
	else 
	{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)addStatusBarControllerObservers
{
	if (!_isObservingStatusBarController) 
	{
		[self addObserver:self forKeyPath:@"processedTracksCount" options:NSKeyValueObservingOptionInitial context:FetchingAllLyricsContext];
		[self addObserver:self forKeyPath:@"totalTracksCount" options:NSKeyValueObservingOptionInitial context:FetchingAllLyricsContext];
		[self addObserver:self forKeyPath:@"isFetchingAllLyrics" options:NSKeyValueObservingOptionInitial context:FetchingAllLyricsContext];
		
		_isObservingStatusBarController = YES;
	}
}


- (void)removeStatusBarControllerObservers
{
	if (_isObservingStatusBarController) 
	{
		[self removeObserver:self forKeyPath:@"processedTracksCount"];
		[self removeObserver:self forKeyPath:@"totalTracksCount"];
		[self removeObserver:self forKeyPath:@"isFetchingAllLyrics"];
		
		_isObservingStatusBarController = NO;
	}
}


#pragma mark -

- (void)toggleFetchingAllLyrics
{
	if (self.isFetchingAllLyrics) 
	{
		[self stopFetchingAllLyrics];
	}
	else
	{
		[self startFetchingAllLyrics];
	}
	
	self.isFetchingAllLyrics = !self.isFetchingAllLyrics;
}


- (void)startFetchingAllLyrics
{	
	// Initialize lyrics fetcher
	if (!lyricsFetcher) 
	{
		lyricsFetcher = [[LyricsFetcher alloc] init];
		[lyricsFetcher setDelegate:self];
	}
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, ^
				   {
					   iTunesPlaylist *musicPlaylist = [[iTunesController sharedInstance] playlistWithName:@"FetchTest"];
					   
					   if (musicPlaylist) 
					   {			
						   dispatch_sync(dispatch_get_main_queue(), ^
										 {
											 self.processedTracksCount = 0;
											 self.totalTracksCount = 0;
										 });

						   // Find tracks without lyrics
						   NSMutableArray *tracksWithoutLyrics = [[NSMutableArray alloc] init];
						   [[musicPlaylist tracks] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
						   {
							   if ([[obj lyrics] length] > 0) 
							   {
								   [tracksWithoutLyrics addObject:obj];
							   }
						   }];

						   dispatch_sync(dispatch_get_main_queue(), ^
										 {
											 self.totalTracksCount = [tracksWithoutLyrics count];
											 [lyricsFetcher fetchLyricsForTracks:tracksWithoutLyrics];
										 });
					   }
				   });
}


- (void)stopFetchingAllLyrics
{
	[lyricsFetcher cancelAllFetches];
}


#pragma mark LyricsFetcher Delegate

- (void)lyricsFetcher:(LyricsFetcher *)fetcher didFetchLyrics:(NSString *)lyrics forTrack:(iTunesTrack *)track
{
	track.lyrics = lyrics;
	
	self.processedTracksCount++;
}


#pragma mark Updating UI

- (void)addStatusItems
{
	if (mainItem == nil) 
	{
		NSImage *statusIcon = [NSImage imageNamed:@"status_icon.png"];
		mainItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
		[mainItem setImage:statusIcon];
		[mainItem setHighlightMode:YES];
		
		NSMenu *mainMenu = [[NSMenu alloc] init];
		[mainMenu setAutoenablesItems:NO];
		[mainMenu setDelegate:self];
		
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
		
		progressMenuItem = [mainMenu addItemWithTitle:@"Progress" action:nil keyEquivalent:@""];
		[progressMenuItem setEnabled:NO];
		[progressMenuItem setHidden:YES];
		
		toggleFetchingMenuItem = [mainMenu addItemWithTitle:@"Fetch All Lyrics" 
													 action:@selector(toggleFetchingAllLyrics) 
											  keyEquivalent:@""];
		[toggleFetchingMenuItem setTarget:self];
		
		[mainMenu addItem:[NSMenuItem separatorItem]];
		
		theItem = [mainMenu addItemWithTitle:@"Show Lyrics..."
									  action:@selector(showLyricsWindow)
							   keyEquivalent:@""];
		[theItem setTarget:[NSApp delegate]];
		
		[mainMenu addItem:[NSMenuItem separatorItem]];
		
		
		theItem = [mainMenu addItemWithTitle:@"Quit"
									  action:@selector(terminate:)
							   keyEquivalent:@"Q"];
		[theItem setTarget:NSApp];
		
		[mainItem setMenu:mainMenu];
	}
	
	if (controllerItem == nil) 
	{
		controllerItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
		[controllerItem setImage:[NSImage imageNamed:@"blank.png"]];
		[controllerItem setView:self.statusView];
		[self updatePlayButtonState];
	}
}


- (void)updatePlayButtonState
{
	NSImage *playButtonImage = [NSImage imageNamed:[[iTunesController sharedInstance] isPlaying] ? @"pause" : @"play"];
	[self.playButton setImage:playButtonImage];
}


- (void)updateProgressMenuItem
{
	// Update title
	NSString *title = [NSString stringWithFormat:@"Processed: %ld of %ld", self.processedTracksCount, self.totalTracksCount];
	[progressMenuItem setTitle:title];
	
	// Show/hide menu item
	if (self.isFetchingAllLyrics && [progressMenuItem isHidden] && self.totalTracksCount > 0) 
	{
		// Show progress menu item
		[progressMenuItem setHidden:NO];
		
		// Update title of the toggle menu item
		[toggleFetchingMenuItem setTitle:@"Stop Fetching All Lyrics"];
		
	}
	else if (!self.isFetchingAllLyrics && ![progressMenuItem isHidden])
	{
		// Hide progress menu item
		[progressMenuItem setHidden:YES];
		
		// Update title of the toggle menu item
		[toggleFetchingMenuItem setTitle:@"Fetch All Lyrics"];
	}
}


@end
