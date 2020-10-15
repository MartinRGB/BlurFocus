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

@interface BlurFocus : NSObject
@end

@implementation BlurFocus

NSArray         *_blurFilters;
NSArray         *_noirFilters;
NSArray         *_hexFilters;
NSArray         *_crystalFilters;
NSArray         *_constColorFilters;
CIFilter        *blurFilt;
CIFilter        *noirFilt;
CIFilter        *hexFilt;
CIFilter        *crystalFilt;
CIFilter        *constColorFilt;
static void     *filterCache = &filterCache;
static void     *isActive = &isActive;

#define saturationFactor 2.0 //0
#define blurRadius 10.0 //9
#define HexagonalPixellateRadius 4.0
#define crystalRadius 6.0
#define contColorEVRadius -2.0
#define kViewBlurredTintColor [NSColor colorWithCalibratedWhite:1.0 alpha:0.7]
#define kViewDefaultTintColor [NSColor colorWithCalibratedWhite:1.0 alpha:0.0]


+ (void)load
{
//    NSArray *blacklist = @[@"com.apple.notificationcenterui", @"com.google.chrome", @"com.google.chrome.canary", @"com.spotify.client",@"com.electron.lark"];
    NSArray *blacklist = @[@"com.apple.notificationcenterui",@"com.electron.lark",@"com.google.Chrome",@"com.microsoft.VSCode",@"com.github.Electron"];
    NSString *appID = [[NSBundle mainBundle] bundleIdentifier];
    if (![blacklist containsObject:appID])
    {
        blurFilt = [CIFilter filterWithName:@"CIGaussianBlur"];
        [blurFilt setDefaults];
        [blurFilt setValue:[NSNumber numberWithFloat:blurRadius] forKey:@"inputRadius"];
        _blurFilters = [NSArray arrayWithObjects:blurFilt, nil];
        
        noirFilt = [CIFilter filterWithName:@"CIColorControls"];
        [noirFilt setDefaults];
        [noirFilt setValue:[NSNumber numberWithFloat:saturationFactor] forKey:@"inputSaturation"];
        _noirFilters = [NSArray arrayWithObjects:noirFilt, nil];
        
//        ####### Other Filters #######
//        hexFilt = [CIFilter filterWithName:@"CIHexagonalPixellate"];
//        [hexFilt setDefaults];
//        [hexFilt setValue:[NSNumber numberWithFloat:4.0] forKey:@"inputScale"];
//        _hexFilters = [NSArray arrayWithObjects:hexFilt, nil];
//
//        crystalFilt = [CIFilter filterWithName:@"CICrystallize"];
//        [crystalFilt setDefaults];
//        [crystalFilt setValue:[NSNumber numberWithFloat:6.0] forKey:@"inputRadius"];
//        _crystalFilters = [NSArray arrayWithObjects:crystalFilt, nil];
//
//        constColorFilt = [CIFilter filterWithName:@"CIExposureAdjust"];
//        [constColorFilt setDefaults];
//        [constColorFilt setValue:[NSNumber numberWithFloat:-2.0] forKey:@"inputEV"];
//        _constColorFilters = [NSArray arrayWithObjects:constColorFilt, nil];
        
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(BF_blurWindow:) name:NSWindowDidResignKeyNotification object:nil];
        [center addObserver:self selector:@selector(BF_blurWindow:) name:NSWindowDidResignMainNotification object:nil];
        [center addObserver:self selector:@selector(BF_focusWindow:) name:NSWindowDidBecomeMainNotification object:nil];
        [center addObserver:self selector:@selector(BF_focusWindow:) name:NSWindowDidBecomeKeyNotification object:nil];
        NSLog(@"BlurFocus loaded...");
    }
}


NSArray* BF_addFilter(NSArray* gray, NSArray* def)
{
    NSMutableArray *newFilters = [[NSMutableArray alloc] initWithArray:def];
    [newFilters addObjectsFromArray:gray];
    NSArray *result = [newFilters copy];
    return result;
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
        
//        ####### Other Filters #######
//        [newFilters addObjectsFromArray:_hexFilters];
//        [newFilters addObjectsFromArray:_crystalFilters];
//        [newFilters addObjectsFromArray:_constColorFilters];
        
//        ####### Orignal Method #######
//        [[win.contentView superview] setContentFilters:BF_addFilter(_blurFilters, _defaultFilters)];
        
        NSArray *result = [newFilters copy];
        
//  Add TintColor & MaskToBounds
        [[win.contentView superview].layer setBackgroundColor:kViewBlurredTintColor.CGColor];
        [[win.contentView superview].layer setMasksToBounds:YES];
        
        [[win.contentView superview] setContentFilters:result];
        [win setAlphaValue:1.0];
        

   
        
        objc_setAssociatedObject(win, isActive, [NSNumber numberWithBool:true], OBJC_ASSOCIATION_RETAIN);
        [[win.contentView superview].layer setNeedsDisplay];
    }
}



+ (void)BF_focusWindow:(NSNotification *)note
{
    NSWindow *win = note.object;
    if ([objc_getAssociatedObject(win, isActive) boolValue]) {
        [[win.contentView superview] setWantsLayer:YES];
//  Add TintColor
        [[win.contentView superview].layer setBackgroundColor:kViewDefaultTintColor.CGColor];
        
        [[win.contentView superview] setContentFilters:objc_getAssociatedObject(win, filterCache)];
        [win setAlphaValue:1.0];
        objc_setAssociatedObject(win, isActive, [NSNumber numberWithBool:false], OBJC_ASSOCIATION_RETAIN);
        [[win.contentView superview].layer setNeedsDisplay];
    }
}

@end
