//
//  PluginManager.m
//  LyricsFetcher
//
//  Created by Toomas Vahter on 26.12.11.
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

#import "PlugInManager.h"
#import "LyricsFetching.h"

@interface PlugInManager()
@property (readwrite, strong) NSArray *plugIns;

- (NSArray *)_bundlePaths;
- (BOOL)_plugInClassIsValid:(Class)plugInClass;
- (void)_loadAndValidatePlugIns;
@end

@implementation PlugInManager

+ (PlugInManager *)defaultManager
{
	static PlugInManager *sharedPlugInManagerInstance = nil;
	static dispatch_once_t sharedPlugInManagerPredicate;
	
	dispatch_once(&sharedPlugInManagerPredicate, ^
				  {
					  sharedPlugInManagerInstance = [[[self class] alloc] init];
				  });
	
	return sharedPlugInManagerInstance;
}


- (id)init
{
	if ((self = [super init])) 
	{
		[self _loadAndValidatePlugIns];
	}
	
	return self;
}


- (NSArray *)_bundlePaths
{
	NSMutableArray *bundleSearchPaths = [[NSMutableArray alloc] init];
	
	NSError *error = nil;
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSURL *applicationSupportPlugInsURL = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSAllDomainsMask - NSSystemDomainMask appropriateForURL:nil create:YES error:&error];
	
	if (applicationSupportPlugInsURL) 
	{
		error = nil;
		NSString *pluginsSubpath = @"MyTunesController/PlugIns/";
		applicationSupportPlugInsURL = [applicationSupportPlugInsURL URLByAppendingPathComponent:pluginsSubpath];
		
		if ([applicationSupportPlugInsURL checkResourceIsReachableAndReturnError:&error]) 
		{
			[bundleSearchPaths addObject:[applicationSupportPlugInsURL path]];
		}
		else 
		{
			NSLog(@"%s error = (%@)", __func__, [error localizedDescription]);
		}
	}
	else
	{
		NSLog(@"%s error = (%@)", __func__, [error localizedDescription]);
	}
	
	[bundleSearchPaths addObject:[[NSBundle mainBundle] builtInPlugInsPath]]; // Resource folder
	
	NSString *bundleSearchPath = nil;
	NSString *bundlePathComponent = nil;
	NSMutableArray *bundlePaths = [[NSMutableArray alloc] init];
	NSDirectoryEnumerator *directoryEnumerator = nil;
	
	for (bundleSearchPath in bundleSearchPaths) 
	{
		directoryEnumerator = [fileManager enumeratorAtPath:bundleSearchPath];
		
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


- (void)_loadAndValidatePlugIns
{
	NSArray *paths = [self _bundlePaths];
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
}

@end
