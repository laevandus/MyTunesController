//
//  PreferencesController.m
//  MyTunesController
//
//  Created by Toomas Vahter on 25.12.09.
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


#import "PreferencesController.h"
#import <CoreServices/CoreServices.h>

@interface PreferencesController()
- (BOOL)isAppStartingOnLogin;
- (void)insertAppToLoginItems;
- (void)removeAppFromLoginItems;
@end


@implementation PreferencesController

@synthesize loginCheckBox = _loginCheckBox;


- (id)init 
{
	return [self initWithWindowNibName:@"Preferences"];
}


- (void)showWindow:(id)sender 
{
	[self.window center];
	[super showWindow:sender];
	
	[self.loginCheckBox setState:[self isAppStartingOnLogin] ? NSOnState : NSOffState];
	
	[self.window makeKeyAndOrderFront:self];
}


- (IBAction)toggleStartOnLogin:(id)sender 
{
	if ([(NSButton*)sender state] == NSOnState) 
	{
		[self insertAppToLoginItems];
	} 
	else 
	{
		[self removeAppFromLoginItems];
	}
}


#pragma mark -

- (BOOL)isAppStartingOnLogin 
{
	BOOL result = NO;
	LSSharedFileListRef loginListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (loginListRef) 
	{
		NSURL *mainBundleURL = [[NSBundle mainBundle] bundleURL];
		CFArrayRef loginItemsArrayRef = LSSharedFileListCopySnapshot(loginListRef, NULL);
		NSArray *loginItemsArray = [[NSArray alloc] initWithArray:(__bridge NSArray *)loginItemsArrayRef];
		
		for (id itemRef in loginItemsArray) 
		{
			CFURLRef itemURLRef = NULL;
			
			if (LSSharedFileListItemResolve((__bridge LSSharedFileListItemRef)itemRef, 0,&itemURLRef, NULL) == noErr) 
			{
				if ([(__bridge NSURL *)itemURLRef isEqual:mainBundleURL])
					result = YES;
			}
			
			if (itemURLRef) 
			{
				CFRelease(itemURLRef);
			}
			
			if (result) 
			{
				break;
			}
		}

		CFRelease(loginItemsArrayRef);
		CFRelease(loginListRef);
	}
	
	return result;
}


- (void)insertAppToLoginItems 
{
	LSSharedFileListRef loginListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (loginListRef) 
	{
		NSURL *mainBundleURL = [[NSBundle mainBundle] bundleURL];
		LSSharedFileListItemRef loginItemRef = LSSharedFileListInsertItemURL(loginListRef, kLSSharedFileListItemLast, NULL, NULL, (__bridge CFURLRef)mainBundleURL, NULL, NULL);             
		
		if (loginItemRef) 
		{
			CFRelease(loginItemRef);
		}
		
		CFRelease(loginListRef);
	}
}


- (void)removeAppFromLoginItems 
{
	LSSharedFileListRef loginListRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (loginListRef) 
	{
		NSURL *mainBundleURL = [[NSBundle mainBundle] bundleURL];
		CFArrayRef loginItemsArrayRef = LSSharedFileListCopySnapshot(loginListRef, NULL);
		NSArray *loginItemsArray = [[NSArray alloc] initWithArray:(__bridge NSArray *)loginItemsArrayRef];
		
		for (id itemRef in loginItemsArray) 
		{		
			CFURLRef itemURLRef = NULL;
			
			if (LSSharedFileListItemResolve((__bridge LSSharedFileListItemRef)itemRef, 0, &itemURLRef, NULL) == noErr) 
			{
				if ([(__bridge NSURL *)itemURLRef isEqual:mainBundleURL])
					LSSharedFileListItemRemove(loginListRef, (__bridge LSSharedFileListItemRef)itemRef);
			}
			
			if (itemURLRef) 
			{
				CFRelease(itemURLRef);
			}
		}

		CFRelease(loginItemsArrayRef);
		CFRelease(loginListRef);
	}
}

@end
