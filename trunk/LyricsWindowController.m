//
//  LyricsWindowController.m
//  MyTunesController
//
//  Created by Toomas Vahter on 21.01.12.
//  Copyright (c) 2012 Toomas Vahter. All rights reserved.
//

#import "LyricsWindowController.h"
#import "LyricsFetcher.h"


@implementation LyricsWindowController

@synthesize track = _track;

- (id)init
{
	return [self initWithWindowNibName:@"LyricsWindow"];
}


- (void)windowDidLoad
{
    [super windowDidLoad];
    
	[self.window makeFirstResponder:nil];
}


+ (NSSet *)keyPathsForValuesAffectingAttributedLyrics 
{
    return [NSSet setWithObjects:@"track", @"track.lyrics", nil];
}


- (NSAttributedString *)attributedLyrics
{
	NSDictionary *textAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
									[NSColor colorWithDeviceWhite:0.9 alpha:1.0], NSForegroundColorAttributeName, 
									nil];
	return [[NSAttributedString alloc] initWithString:[self.track lyrics] attributes:textAttributes];
}


+ (NSSet *)keyPathsForValuesAffectingTrackDescription 
{
    return [NSSet setWithObjects:@"track", nil];
}


- (NSString *)trackDescription
{
	return [NSString stringWithFormat:@"%@ - %@", self.track.name, self.track.artist];
}


- (IBAction)clear:(id)sender
{
	[self.track setLyrics:@""];
}


- (IBAction)fetch:(id)sender
{
	[[LyricsFetcher sharedFetcher] fetchLyricsForTrack:self.track];
}

@end
