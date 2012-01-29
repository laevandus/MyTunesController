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
	[fetchingQueue cancelAllOperations];
	[fetchingQueue addOperation:operation];
}


- (void)_fetchLyricsForTrackInBackground:(iTunesTrack *)track
{
	@autoreleasepool 
	{		
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
			
			// Reduce the interval of querying websites
			usleep(500000);
			
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
