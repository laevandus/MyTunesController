//
//  LyricsBackgroundView.m
//  MyTunesController
//
//  Created by Toomas Vahter on 21.01.12.
//  Copyright (c) 2012 Toomas Vahter. All rights reserved.
//

#import "LyricsBackgroundView.h"

@implementation LyricsBackgroundView

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor colorWithDeviceWhite:0.0 alpha:0.5] set];
	[[NSBezierPath bezierPathWithRect:dirtyRect] fill];
}

@end
