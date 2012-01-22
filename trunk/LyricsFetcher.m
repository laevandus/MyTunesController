//
//  LyricsFetcher.m
//  LyricsFetcher
//
//  Created by Toomas Vahter on 22.12.11.
//  Copyright (c) 2011 Toomas Vahter. All rights reserved.
//

#import "LyricsFetcher.h"
#import "PlugInManager.h"
#import "LyricsFetching.h"


@interface LyricsFetcher()
@property (nonatomic, readwrite, strong) PlugInManager *pluginManager;
- (void)_fetchLyricsForTrackInBackground:(iTunesTrack *)track;
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
		fetchingQueue = [[NSOperationQueue alloc] init];
		[fetchingQueue setMaxConcurrentOperationCount:1];
	}
	
	return self;
}

- (void)fetchLyricsForTrack:(iTunesTrack *)track
{
	NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_fetchLyricsForTrackInBackground:) object:track];
	[fetchingQueue addOperation:operation];
}


- (void)_fetchLyricsForTrackInBackground:(iTunesTrack *)track
{
	@autoreleasepool 
	{
		NSLog(@"%s %@ - %@", __func__, [track name], [track artist]);
		
		// Randomize plugins for distributing the load
		NSString *fetchedLyrics = nil;
		NSArray *plugIns = [[self pluginManager] plugIns];
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
		}
		
		if (fetchedLyrics == nil) 
		{
			fetchedLyrics = @"";
		}
		
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
							  track, @"track",
							  fetchedLyrics, @"lyrics", nil];
		[self performSelectorOnMainThread:@selector(_finalizeFetchingWithInfo:) withObject:info waitUntilDone:YES];
	}
}


- (void)_finalizeFetchingWithInfo:(NSDictionary *)fetchInfo
{
	if ([[self delegate] respondsToSelector:@selector(lyricsFetcher:didFetchLyrics:forTrack:)]) 
	{
		[[self delegate] lyricsFetcher:self didFetchLyrics:[fetchInfo objectForKey:@"lyrics"] forTrack:[fetchInfo objectForKey:@"track"]];
	}
}


@end
