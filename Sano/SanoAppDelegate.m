//
//  SanoAppDelegate.m
//  Sano
//
//  Created by Raj Gokal on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SanoAppDelegate.h"
#import <Parse/Parse.h>
#import "OnboardingViewController.h"

@implementation SanoAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:@"Y6DDaEB6vQRMOt6WMLYtx1LtMwNwPQIjzztfpBpx"
                  clientKey:@"GJm3uvGxRNE1d14AR8N2lDFfkHyCHcQ6jyl89fJT"];    
    // Override point for customization after application launch.
    [application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//        UINavigationController *nav = [[UINavigationController alloc] init];
//
//    OnboardingViewController *rvc = [[OnboardingViewController alloc]init];
//    self.window.rootViewController = rvc;
//    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:rvc];
    return YES;
}
	
- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
