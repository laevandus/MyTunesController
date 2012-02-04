//
//  LyricsFetcher.m
//  LyricsFetcher
//
//  Created by Toomas Vahter on 22.12.11.
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

#import "LyricsFetcher.h"
#import "PlugInManager.h"
#import "LyricsFetching.h"
#import "iTunesController.h"


@interface LyricsFetcher()
@property (nonatomic, readwrite, strong) PlugInManager *pluginManager;
void FetchLyricsForTrackDatabaseIDUsingPlugIns(NSInteger trackDatabaseID, NSArray *plugIns);
iTunesTrack *SearchTrackWithDatabaseID(NSInteger trackDatabaseID);
NSString *FetchLyricsForTrack(iTunesTrack *track, NSArray *plugIns);
@end


@implementation LyricsFetcher

@synthesize delegate = _delegate;
@synthesize pluginManager = _pluginManager;


+ (LyricsFetcher *)sharedFetcher
{
	static LyricsFetcher *sharedLyricsFetcherInstance = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^
	{
		sharedLyricsFetcherInstance = [[[self class] alloc] init];
	});
	
	return sharedLyricsFetcherInstance;
}


- (id)init
{
	if ((self = [super init])) 
	{
		// Load plugins
		_pluginManager = [[PlugInManager alloc] init];
		
		fetchingQueue = dispatch_queue_create("com.mytunescontroller.FetchingQueue", NULL);
		dispatch_retain(fetchingQueue);
	}
	
	return self;
}


- (void)dealloc
{
	dispatch_release(fetchingQueue);
}


- (void)fetchLyricsForTrack:(iTunesTrack *)track
{
	// Get new reference which does not depend on currentTrack. currentTrack reference changes in the lifetime of the application and therefore I might get invalid object I am setting lyrics to in the delegate.
	__block NSInteger trackDatabaseID = [track databaseID];
	__block NSArray *plugIns = [[self pluginManager] plugIns];
	
	dispatch_async(fetchingQueue, ^
    {
		iTunesTrack *foundTrack = SearchTrackWithDatabaseID(trackDatabaseID);
		
		if (foundTrack)
		{
			NSString *lyrics = FetchLyricsForTrack(foundTrack, plugIns);
			
		   // Tell delegate about the result on the main thread
			dispatch_async(dispatch_get_main_queue(), ^
			{
				if ([[self delegate] respondsToSelector:@selector(lyricsFetcher:didFetchLyrics:forTrack:)]) 
				{
					[[self delegate] lyricsFetcher:self didFetchLyrics:lyrics forTrack:foundTrack];
				}
		   });
		}
		else
		{
			NSLog(@"Failed to find track for database ID %ld", trackDatabaseID);
		}
   });
}


iTunesTrack *SearchTrackWithDatabaseID(NSInteger trackDatabaseID)
{
	__block iTunesTrack *track = nil;
	iTunesPlaylist *musicPlaylist = [[iTunesController sharedInstance] playlistWithName:@"Music"];
	
	[[musicPlaylist tracks] enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop)
	 {
		 if ([object databaseID] == trackDatabaseID) 
		 {
			 track = (iTunesTrack *)object;
			 *stop = YES;
		 }
	 }];
	
	return track;
}


NSString *FetchLyricsForTrack(iTunesTrack *track, NSArray *plugIns)
{
	// Track must have name and artist for fetching
	NSString *fetchedLyrics = nil;
	
	if ([track.name length] && [track.artist length]) 
	{
		// Randomize plugins for distributing the load
		NSUInteger offset = rand() % ([plugIns count] + 1);
		id bundleInstance = nil;
		
		for (NSUInteger i = 0; i < [plugIns count]; i++) 
		{
			NSUInteger j = i + offset;
			
			if (j >= [plugIns count]) 
			{
				j = j - [plugIns count];
			}
			
			bundleInstance = [plugIns objectAtIndex:j];
			
			fetchedLyrics = [(id<LyricsFetching>)bundleInstance lyricsForTrackName:[track name] artist:[track artist] album:[track album]];
			
			if ([fetchedLyrics length] > 0) 
			{
				break;
			}
			else
			{
				// Reduce the interval of querying websites
				usleep(500000);
			}
		}
	}
	
	return fetchedLyrics ? fetchedLyrics : @"";
}


@end
