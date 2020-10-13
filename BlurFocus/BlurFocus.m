//
//  BlurFocus.m
//  BlurFocus
//
//  Created by Wolfgang Baird on 4/30/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

NSArray* BF_addFilter(NSArray* gray, NSArray* def)
{
    NSMutableArray *newFilters = [[NSMutableArray alloc] initWithArray:def];
    [newFilters addObjectsFromArray:gray];
    NSArray *result = [newFilters copy];
    return result;
}

@interface BlurFocus : NSObject
@end

@implementation BlurFocus

NSArray         *_blurFilters;
NSArray         *_noirFilters;
NSArray         *_hexFilters;
NSArray         *_crystalFilters;
CIFilter        *blurFilt;
CIFilter        *noirFilt;
CIFilter        *hexFilt;
CIFilter        *crystalFilt;
static void     *filterCache = &filterCache;
static void     *isActive = &isActive;

+ (void)load
{
//    NSArray *blacklist = @[@"com.apple.notificationcenterui", @"com.google.chrome", @"com.google.chrome.canary", @"com.spotify.client",@"com.electron.lark"];
    NSArray *blacklist = @[@"com.apple.notificationcenterui",@"com.electron.lark",@"com.google.Chrome"];
    NSString *appID = [[NSBundle mainBundle] bundleIdentifier];
    if (![blacklist containsObject:appID])
    {
        blurFilt = [CIFilter filterWithName:@"CIGaussianBlur"];
        [blurFilt setDefaults];
        [blurFilt setValue:[NSNumber numberWithFloat:8.0] forKey:@"inputRadius"];
        _blurFilters = [NSArray arrayWithObjects:blurFilt, nil];
        
        noirFilt = [CIFilter filterWithName:@"CIColorControls"];
        [noirFilt setDefaults];
        [noirFilt setValue:[NSNumber numberWithFloat:0.0] forKey:@"inputSaturation"];
        _noirFilters = [NSArray arrayWithObjects:noirFilt, nil];
        
//        hexFilt = [CIFilter filterWithName:@"CIHexagonalPixellate"];
//        [hexFilt setDefaults];
//        [hexFilt setValue:[NSNumber numberWithFloat:4.0] forKey:@"inputScale"];
//        _hexFilters = [NSArray arrayWithObjects:hexFilt, nil];
//
//        crystalFilt = [CIFilter filterWithName:@"CICrystallize"];
//        [crystalFilt setDefaults];
//        [crystalFilt setValue:[NSNumber numberWithFloat:6.0] forKey:@"inputRadius"];
//        _crystalFilters = [NSArray arrayWithObjects:crystalFilt, nil];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(BF_blurWindow:) name:NSWindowDidResignKeyNotification object:nil];
        [center addObserver:self selector:@selector(BF_blurWindow:) name:NSWindowDidResignMainNotification object:nil];
        [center addObserver:self selector:@selector(BF_focusWindow:) name:NSWindowDidBecomeMainNotification object:nil];
        [center addObserver:self selector:@selector(BF_focusWindow:) name:NSWindowDidBecomeKeyNotification object:nil];
        NSLog(@"BlurFocus loaded...");
    }
}

+ (void)BF_blurWindow:(NSNotification *)note
{
    NSWindow *win = note.object;
    if (![objc_getAssociatedObject(win, isActive) boolValue] && !([win styleMask] & NSWindowStyleMaskFullScreen)) {
        NSArray *_defaultFilters = [[win.contentView superview] contentFilters];
        objc_setAssociatedObject(win, filterCache, _defaultFilters, OBJC_ASSOCIATION_RETAIN);
        [[win.contentView superview] setWantsLayer:YES];
        
        NSMutableArray *newFilters = [[NSMutableArray alloc] initWithArray:_defaultFilters];
        [newFilters addObjectsFromArray:_blurFilters];
        [newFilters addObjectsFromArray:_noirFilters];
//        [newFilters addObjectsFromArray:_hexFilters];
//        [newFilters addObjectsFromArray:_crystalFilters];
        NSArray *result = [newFilters copy];
        
//        [[win.contentView superview] setContentFilters:BF_addFilter(_blurFilters, _defaultFilters)];
        [[win.contentView superview] setContentFilters:result];
        [win setAlphaValue:1.0];
        objc_setAssociatedObject(win, isActive, [NSNumber numberWithBool:true], OBJC_ASSOCIATION_RETAIN);
    }
}

+ (void)BF_focusWindow:(NSNotification *)note
{
    NSWindow *win = note.object;
    if ([objc_getAssociatedObject(win, isActive) boolValue]) {
        [[win.contentView superview] setWantsLayer:YES];
        [[win.contentView superview] setContentFilters:objc_getAssociatedObject(win, filterCache)];
        [win setAlphaValue:1.0];
        objc_setAssociatedObject(win, isActive, [NSNumber numberWithBool:false], OBJC_ASSOCIATION_RETAIN);
    }
}

@end
