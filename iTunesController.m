//
//  iTunesController.m
//  MyTunesController
//
//  Created by Toomas Vahter on 27.07.10.
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

#import "iTunesController.h"

@implementation iTunesController

+ (iTunesController *)sharedInstance 
{	
	static iTunesController *sharediTunesControllerInstance = nil;
	static dispatch_once_t iTunesControllerOnceToken;
	
	dispatch_once(&iTunesControllerOnceToken, ^
    {
        sharediTunesControllerInstance = [[[self class] alloc] init];
    });
	
	return sharediTunesControllerInstance;
}


- (id)init 
{	
	if ((self = [super init])) 
	{
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(_iTunesTrackDidChange:)
                                                                name:@"com.apple.iTunes.playerInfo"
                                                              object:@"com.apple.iTunes.player"];
		
		iTunesApp = (iTunesApplication *)[SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
	}
	
	return self;
}


- (void)dealloc 
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}


- (iTunesPlaylist *)playlistWithName:(NSString *)playlistName
{
	__block iTunesSource *librarySource = nil;
	SBElementArray *sources = [iTunesApp sources];
	[sources enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop)
    {
        if ([[object name] isEqualToString:@"Library"])
        {
            librarySource = object;
            *stop = YES;
        }
    }];
	
	__block iTunesPlaylist *playlist = nil;
	[[librarySource playlists] enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop)
    {
        if ([[object name] isEqualToString:playlistName])
        {
            playlist = object;
            *stop = YES;
        }
    }];
	
	return playlist;
}


- (BOOL)isPlaying
{
	if (!iTunesApp.isRunning)
		return NO;
	
	if (iTunesApp.playerState == iTunesEPlSPlaying)
		return YES;

	return NO;
}


- (void)playPause
{
	// starts iTunes if not launched
	[iTunesApp playpause];
}


- (void)playPrevious
{
	if (iTunesApp.isRunning) 
		[iTunesApp backTrack];
}


- (void)playNext
{
	if (iTunesApp.isRunning) 
		[iTunesApp nextTrack];
}


- (iTunesTrack *)currentTrack
{	
	if (!iTunesApp.isRunning)
		return nil;
	
	return iTunesApp.currentTrack;
}


- (void)_iTunesTrackDidChange:(NSNotification *)aNotification 
{	
	iTunesTrack *track = nil;
	
	if (![[aNotification userInfo][@"Player State"] isEqualToString:@"Stopped"])
		track = self.currentTrack;
	
	if ([self.delegate respondsToSelector:@selector(iTunesController:trackDidChange:)])
		[self.delegate iTunesController:self trackDidChange:track];
}

@end
