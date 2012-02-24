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
#import "LoginItemManager.h"


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
	
	LoginItemManager *loginItemManager = [[LoginItemManager alloc] init];
	NSURL *mainBundleURL = [[NSBundle mainBundle] bundleURL];
	[self.loginCheckBox setState:[loginItemManager itemExistsAtURL:mainBundleURL] ? NSOnState : NSOffState];
	
	[self.window makeKeyAndOrderFront:self];
}


- (IBAction)toggleStartOnLogin:(id)sender 
{
	LoginItemManager *loginItemManager = [[LoginItemManager alloc] init];
	NSURL *mainBundleURL = [[NSBundle mainBundle] bundleURL];
	
	if ([(NSButton*)sender state] == NSOnState) 
	{
		[loginItemManager addItemAtURL:mainBundleURL];
	} 
	else 
	{
		[loginItemManager removeItemAtURL:mainBundleURL];
	}
}

@end