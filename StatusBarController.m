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
#import "NetworkReachability.h"

@interface StatusBarController()

@property NSUInteger processedTracksCount;
@property NSUInteger totalTracksCount;
@property (getter = isFetchingAllLyrics) BOOL fetchingAllLyrics;
@property (getter = isIgnoringTracksWithLyrics) BOOL ignoreTracksWithLyrics;
@property (strong) LyricsFetcher *lyricsFetcher;

- (void)addStatusBarControllerObservers;
- (void)removeStatusBarControllerObservers;

- (void)updateProgressMenuItem;

- (void)toggleFetchingAllLyrics;
- (void)startFetchingAllLyrics;
- (void)stopFetchingAllLyrics;

- (void)_processTracks;
@end

@implementation StatusBarController

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


#pragma mark -
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


#pragma mark -
#pragma mark KVO

static void *const FetchingAllLyricsContext = "FetchingAllLyricsContext";

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
    if (context == FetchingAllLyricsContext) 
	{
		if ([keyPath isEqualToString:@"processedTracksCount"]) 
		{
			if (self.isFetchingAllLyrics && self.totalTracksCount > 0 && self.processedTracksCount == self.totalTracksCount) 
			{
                self.fetchingAllLyrics = NO;
                self.lyricsFetcher = nil;
			}
		}
		
		NSArray *modes = @[NSRunLoopCommonModes];
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
		[self addObserver:self forKeyPath:@"fetchingAllLyrics" options:NSKeyValueObservingOptionInitial context:FetchingAllLyricsContext];
		
		_isObservingStatusBarController = YES;
	}
}


- (void)removeStatusBarControllerObservers
{
	if (_isObservingStatusBarController) 
	{
		[self removeObserver:self forKeyPath:@"processedTracksCount"];
		[self removeObserver:self forKeyPath:@"totalTracksCount"];
		[self removeObserver:self forKeyPath:@"fetchingAllLyrics"];
		
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
}


- (void)startFetchingAllLyrics
{	
	// Initialize lyrics fetcher
	if (!self.lyricsFetcher)
	{
		self.lyricsFetcher = [[LyricsFetcher alloc] init];
		[self.lyricsFetcher setDelegate:self];
	}
	
	// Reset counts
	self.processedTracksCount = 0;
	self.totalTracksCount = 0;
	
	// Start processing tracks in the background
	self.fetchingAllLyrics = YES;
	[self performSelectorInBackground:@selector(_processTracks) withObject:nil];
}


- (void)_processTracks
{
	@autoreleasepool 
	{
		iTunesPlaylist *musicPlaylist = [[iTunesController sharedInstance] playlistWithName:@"Music"];
        
		if (musicPlaylist) 
		{			
			NSMutableArray *tracksToProcess = [[NSMutableArray alloc] init];
			iTunesTrack *track = nil;
			
			NSArray *modes = @[NSRunLoopCommonModes];
			NSString *title = nil;
			NSUInteger totalCount = [[musicPlaylist tracks] count];
			NSUInteger currentIndex = 0;
			
			for (track in [musicPlaylist tracks]) 
			{
                currentIndex++;
				
                if (self.isIgnoringTracksWithLyrics)
                {
                    if ([track.lyrics length] == 0)
                        [tracksToProcess addObject:track];
                }
                else
                {
                    [tracksToProcess addObject:track];
                }
				
                if (!self.isFetchingAllLyrics)
                    break;
				
                // Update analyzing status
                title = [NSString stringWithFormat:NSLocalizedString(@"Menu-item-analyzing-tracks-detailed", nil), currentIndex, totalCount];
                [progressMenuItem performSelectorOnMainThread:@selector(setTitle:) withObject:title waitUntilDone:YES modes:modes];
			}
			
			self.totalTracksCount = [tracksToProcess count];
			[self.lyricsFetcher fetchLyricsForTracks:tracksToProcess];
		}
		else
		{
			self.fetchingAllLyrics = NO;
            self.lyricsFetcher = nil;
		}
	}
}


- (void)stopFetchingAllLyrics
{
	self.fetchingAllLyrics = NO;
    [self.lyricsFetcher cancelAllFetches];
    self.lyricsFetcher.delegate = nil;
    self.lyricsFetcher = nil;
}


#pragma mark -
#pragma mark LyricsFetcher Delegate

- (void)lyricsFetcher:(LyricsFetcher *)fetcher didFetchLyrics:(NSString *)lyrics forTrack:(iTunesTrack *)track
{
	track.lyrics = lyrics;	
	self.processedTracksCount++;
}


#pragma mark -
#pragma mark Updating UI

- (void)addStatusItems
{
	if (!mainItem)
	{
		NSImage *statusIcon = [NSImage imageNamed:@"status_icon"];
		mainItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
		[mainItem setImage:statusIcon];
		[mainItem setHighlightMode:YES];
		
		NSMenu *mainMenu = [[NSMenu alloc] init];
		[mainMenu setAutoenablesItems:NO];
		[mainMenu setDelegate:self];
		
		NSMenuItem *theItem = [mainMenu addItemWithTitle:NSLocalizedString(@"Menu-item-about", nil)
                                                  action:@selector(showAboutPanel)
                                           keyEquivalent:@""];
		[theItem setTarget:[NSApp delegate]];
		
		theItem = [mainMenu addItemWithTitle:NSLocalizedString(@"Menu-item-check-for-updates", nil)
                                      action:@selector(checkForUpdates:)
                               keyEquivalent:@""];
		[theItem setTarget:self.sparkleController];
		
		theItem = [mainMenu addItemWithTitle:NSLocalizedString(@"Menu-item-preferences", nil)
                                      action:@selector(showPreferencesWindow)
                               keyEquivalent:@""];
		[theItem setTarget:[NSApp delegate]];
		
		[mainMenu addItem:[NSMenuItem separatorItem]];
		
		progressMenuItem = [mainMenu addItemWithTitle:@"Progress" action:nil keyEquivalent:@""];
		[progressMenuItem setEnabled:NO];
		[progressMenuItem setHidden:YES];
		
		toggleFetchingMenuItem = [mainMenu addItemWithTitle:NSLocalizedString(@"Menu-item-fetch-missing-lyrics", nil)
                                                     action:@selector(toggleFetchingAllLyrics)
                                              keyEquivalent:@""];
		[toggleFetchingMenuItem setTarget:self];
		
        theItem = [mainMenu addItemWithTitle:NSLocalizedString(@"Menu-item-refetch-lyrics", nil)
                                      action:@selector(refetchCurrentLyrics:)
                               keyEquivalent:@""];
		[theItem setTarget:[NSApp delegate]];
        
		[mainMenu addItem:[NSMenuItem separatorItem]];
		
		theItem = [mainMenu addItemWithTitle:NSLocalizedString(@"Menu-item-show-lyrics", nil)
                                      action:@selector(showLyricsWindow)
                               keyEquivalent:@""];
		[theItem setTarget:[NSApp delegate]];
        
		[mainMenu addItem:[NSMenuItem separatorItem]];
		
		theItem = [mainMenu addItemWithTitle:NSLocalizedString(@"Menu-item-quit", nil)
                                      action:@selector(terminate:)
                               keyEquivalent:@"Q"];
		[theItem setTarget:NSApp];
		
		[mainItem setMenu:mainMenu];
	}
	
	if (!controllerItem)
	{
		controllerItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        [controllerItem setImage:nil];
		[controllerItem setView:self.statusView];
		[self updatePlayButtonState];
	}
}


- (void)menuNeedsUpdate:(NSMenu *)menu
{
    if ([menu isEqual:mainItem.menu])
    {
        if (self.isFetchingAllLyrics)
        {
            [toggleFetchingMenuItem setTitle:NSLocalizedString(@"Menu-item-stop-fetching-lyrics", nil)];
        }
        else
        {
            if ([NSEvent modifierFlags] & NSAlternateKeyMask)
            {
                [toggleFetchingMenuItem setTitle:NSLocalizedString(@"Menu-item-fetch-all-lyrics", nil)];
                self.ignoreTracksWithLyrics = NO;
            }
            else
            {
                [toggleFetchingMenuItem setTitle:NSLocalizedString(@"Menu-item-fetch-missing-lyrics", nil)];
                self.ignoreTracksWithLyrics = YES;
            }
        }
    }
}


- (void)updatePlayButtonState
{
	NSImage *playButtonImage = [NSImage imageNamed:[[iTunesController sharedInstance] isPlaying] ? @"pause" : @"play"];
	[self.playButton setImage:playButtonImage];
}


- (void)updateProgressMenuItem
{
	if (self.isFetchingAllLyrics) 
	{
		if (self.totalTracksCount > 0) 
		{
			NSString *format = NSLocalizedString(@"Menu-item-processing-tracks-format", nil);
			NSString *title = [NSString stringWithFormat:format, self.processedTracksCount, self.totalTracksCount];
			[progressMenuItem setTitle:title];
		}
		else
		{
			// Still processing tracks
			[progressMenuItem setTitle:NSLocalizedString(@"Menu-item-analyzing-tracks", nil)];
		}
		
		if ([progressMenuItem isHidden]) 
		{
			[progressMenuItem setHidden:NO];
			[toggleFetchingMenuItem setTitle:NSLocalizedString(@"Menu-item-stop-fetching-lyrics", nil)];
		}
	}
	else
	{
		[progressMenuItem setHidden:YES];
		[toggleFetchingMenuItem setTitle:NSLocalizedString(@"Menu-item-fetch-missing-lyrics", nil)];
	}
}

@end
