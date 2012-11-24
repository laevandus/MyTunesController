//
//  LyricsWindowController.m
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

#import "LyricsWindowController.h"

@interface LyricsWindowController()
@property (nonatomic, readwrite, strong) NSColor *textColor;
@end

@implementation LyricsWindowController

- (id)init
{
	return [self initWithWindowNibName:@"LyricsWindow"];
}


- (id)initWithWindow:(NSWindow *)window
{
	if ((self = [super initWithWindow:window])) 
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:nil];
	}
	
	return self;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)windowDidLoad
{
    [super windowDidLoad];
 
	self.textColor = [NSColor lightGrayColor];
	
	[self.window makeFirstResponder:nil];
}


- (void)windowDidBecomeKey:(NSNotification *)notification
{
	self.textColor = [NSColor colorWithDeviceWhite:0.9 alpha:1.0];
}


- (void)windowDidResignKey:(NSNotification *)notification
{
	self.textColor = [NSColor lightGrayColor];
}


+ (NSSet *)keyPathsForValuesAffectingAttributedLyrics 
{
    return [NSSet setWithObjects:@"track", @"track.lyrics", nil];
}


- (NSAttributedString *)attributedLyrics
{
	NSColor *lyricsColor = [NSColor colorWithDeviceWhite:0.9 alpha:1.0];
	NSDictionary *textAttributes = @{NSForegroundColorAttributeName: lyricsColor};
	return [[self.track lyrics] length] ? [[NSAttributedString alloc] initWithString:[self.track lyrics] attributes:textAttributes] : nil;
}


+ (NSSet *)keyPathsForValuesAffectingTrackDescription 
{
    return [NSSet setWithObjects:@"track", @"track.name", @"track.artist", nil];
}


- (NSString *)trackDescription
{
	NSString *trackDescription = nil;
	
	if ([[self.track name] length] && [[self.track artist] length]) 
	{
		trackDescription = [NSString stringWithFormat:@"%@ - %@", self.track.name, self.track.artist];
	}
	else if ([[self.track name] length])
	{
		trackDescription = [self.track name];
	}
	
	return trackDescription;
}


@end
