//
//  PluginManager.m
//  LyricsFetcher
//
//  Created by Toomas Vahter on 26.12.11.
//  Copyright (c) 2011 Toomas Vahter. All rights reserved.
//

#import "PlugInManager.h"
#import "LyricsFetching.h"

@interface PlugInManager()
@property (readwrite, retain) NSArray *plugIns;

- (NSArray *)_bundlePaths;
- (BOOL)_plugInClassIsValid:(Class)plugInClass;
- (void)_loadAndValidatePlugins;
@end

@implementation PlugInManager

@synthesize plugIns = _plugIns;

- (id)init
{
	if ((self = [super init])) 
	{
		[self _loadAndValidatePlugins];
	}
	
	return self;
}


- (NSArray *)_bundlePaths
{
	NSString *applicationSupportPluginsSubpath = @"Application Support/MyTunesController/PlugIns";
	NSArray *librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES); // e.g. /Users/Toomas/Library
	
	NSString *librarySearchPath = nil;
	NSMutableArray *bundleSearchPaths = [[NSMutableArray alloc] init];
	
	for (librarySearchPath in librarySearchPaths) 
	{
		[bundleSearchPaths addObject:[librarySearchPath stringByAppendingPathComponent:applicationSupportPluginsSubpath]];
	}
	
	[bundleSearchPaths addObject:[[NSBundle mainBundle] builtInPlugInsPath]]; // Resource folder
	
	NSString *bundleSearchPath = nil;
	NSString *bundlePathComponent = nil;
	NSMutableArray *bundlePaths = [[NSMutableArray alloc] init];
	NSDirectoryEnumerator *directoryEnumerator = nil;
	
	for (bundleSearchPath in bundleSearchPaths) 
	{
		directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:bundleSearchPath];
		
		if (directoryEnumerator) 
		{
			for (bundlePathComponent in directoryEnumerator) 
			{
				if ([[bundlePathComponent pathExtension] isEqualToString:@"bundle"])
				{
					[bundlePaths addObject:[bundleSearchPath stringByAppendingPathComponent:bundlePathComponent]];
				}
			}
		}
	}
	
	return bundlePaths;
}


- (BOOL)_plugInClassIsValid:(Class)plugInClass
{
	if ([plugInClass conformsToProtocol:@protocol(LyricsFetching)]) 
	{
		if ([plugInClass instancesRespondToSelector:@selector(lyricsForTrackName:artist:album:)]) 
		{
			return YES;
		}
	}
	
	return NO;
}


- (void)_loadAndValidatePlugins
{
	NSArray *paths = [self _bundlePaths];
	NSLog(@"%@", paths);
	
	NSMutableArray *instances = [[NSMutableArray alloc] init];
	NSString *bundlePath = nil;
	NSBundle *currentBundle = nil;
	Class currentPrincipalClass = nil;
	id currentInstance = nil;
	
	for (bundlePath in paths) 
	{
		currentBundle = [[NSBundle alloc] initWithPath:bundlePath];
		
		if (currentBundle) 
		{
			currentPrincipalClass = [currentBundle principalClass];
			
			if (currentPrincipalClass && [self _plugInClassIsValid:currentPrincipalClass]) 
			{
				currentInstance = [[currentPrincipalClass alloc] init];
				
				if (currentInstance) 
				{
					[instances addObject:currentInstance];
				}
			}
		}
	}
	
	self.plugIns = [NSArray arrayWithArray:instances];
	NSLog(@"Loaded %lu plugins", [self.plugIns count]);
}

@end

















