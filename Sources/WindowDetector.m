//
//  WindowDetector.m
//  MacPenguins
//
//  Created by MacPenguins on 26/11/2024.
//

#import "WindowDetector.h"
#import <AppKit/AppKit.h>

// Private API declarations for Spaces support
extern CGError CGSGetWorkspaces(int cid, CFArrayRef *workspaces);
extern CGError CGSGetWorkspace(int cid, int *workspace);
extern CGError CGSGetWindowWorkspace(int cid, CGWindowID wid, int *workspace);
extern int _CGSDefaultConnection(void);

@implementation WindowInfo
@end

@implementation WindowDetector {
    NSTimer *_monitoringTimer;
    void(^_changeCallback)(void);
    NSArray<WindowInfo *> *_lastWindowList;
}

+ (instancetype)sharedInstance {
    static WindowDetector *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WindowDetector alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lastWindowList = @[];
    }
    return self;
}

- (NSArray<WindowInfo *> *)getAllWindows {
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);

    if (!windowList) {
        return @[];
    }

    NSMutableArray<WindowInfo *> *windows = [NSMutableArray array];

    for (NSDictionary *windowDict in (__bridge NSArray *)windowList) {
        WindowInfo *windowInfo = [[WindowInfo alloc] init];

        // Extract window properties
        NSNumber *windowID = windowDict[(NSString *)kCGWindowNumber];
        windowInfo.windowID = windowID.unsignedIntValue;

        NSNumber *level = windowDict[(NSString *)kCGWindowLayer];
        windowInfo.level = level.intValue;

        NSDictionary *bounds = windowDict[(NSString *)kCGWindowBounds];
        if (bounds) {
            CGRect rect;
            CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)bounds, &rect);
            windowInfo.bounds = rect;
        }

        windowInfo.ownerName = windowDict[(NSString *)kCGWindowOwnerName] ?: @"Unknown";
        windowInfo.windowName = windowDict[(NSString *)kCGWindowName] ?: @"";
        windowInfo.isOnScreen = [windowDict[(NSString *)kCGWindowIsOnscreen] boolValue];

        // Get workspace for this window (requires private API)
        int workspace = -1;
        CGSGetWindowWorkspace(_CGSDefaultConnection(), windowInfo.windowID, &workspace);
        windowInfo.workspace = workspace;

        [windows addObject:windowInfo];
    }

    CFRelease(windowList);
    return [windows copy];
}

- (NSArray<WindowInfo *> *)getVisibleWindows {
    NSArray<WindowInfo *> *allWindows = [self getAllWindows];
    NSMutableArray<WindowInfo *> *visibleWindows = [NSMutableArray array];

    for (WindowInfo *window in allWindows) {
        // Filter for windows that are:
        // - On screen
        // - Have reasonable size (not tiny)
        // - Are at normal window level (not desktop or above menu bar)
        if (window.isOnScreen &&
            window.bounds.size.width > 50 &&
            window.bounds.size.height > 50 &&
            window.level >= 0 && window.level < 20) {
            [visibleWindows addObject:window];
        }
    }

    return [visibleWindows copy];
}

- (NSArray<WindowInfo *> *)getWindowsInCurrentSpace {
    NSNumber *currentSpace = [self getCurrentSpace];
    return [self getWindowsForSpace:currentSpace];
}

- (NSArray<NSNumber *> *)getAllSpaces {
    CFArrayRef spaces = NULL;
    CGSGetWorkspaces(_CGSDefaultConnection(), &spaces);

    if (!spaces) {
        return @[];
    }

    NSMutableArray<NSNumber *> *spaceArray = [NSMutableArray array];

    for (id spaceID in (__bridge NSArray *)spaces) {
        if ([spaceID isKindOfClass:[NSNumber class]]) {
            [spaceArray addObject:(NSNumber *)spaceID];
        }
    }

    CFRelease(spaces);
    return [spaceArray copy];
}

- (NSNumber *)getCurrentSpace {
    int workspace = -1;
    CGSGetWorkspace(_CGSDefaultConnection(), &workspace);
    return @(workspace);
}

- (NSArray<WindowInfo *> *)getWindowsForSpace:(NSNumber *)spaceID {
    NSArray<WindowInfo *> *allWindows = [self getVisibleWindows];
    NSMutableArray<WindowInfo *> *spaceWindows = [NSMutableArray array];

    for (WindowInfo *window in allWindows) {
        if (window.workspace == spaceID.intValue) {
            [spaceWindows addObject:window];
        }
    }

    return [spaceWindows copy];
}

- (NSArray<NSValue *> *)getAllDisplayBounds {
    NSMutableArray<NSValue *> *displayBounds = [NSMutableArray array];

    for (NSScreen *screen in [NSScreen screens]) {
        CGRect bounds = screen.frame;
        [displayBounds addObject:[NSValue valueWithRect:NSRectFromCGRect(bounds)]];
    }

    return [displayBounds copy];
}

- (CGRect)getCombinedDisplayBounds {
    CGRect combinedBounds = CGRectZero;

    for (NSScreen *screen in [NSScreen screens]) {
        combinedBounds = CGRectUnion(combinedBounds, screen.frame);
    }

    return combinedBounds;
}

- (void)startMonitoring:(void(^)(void))callback {
    _changeCallback = [callback copy];

    // Store initial window list
    _lastWindowList = [self getAllWindows];

    // Start timer-based monitoring (could be enhanced with CGWindowServer notifications)
    _monitoringTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                      target:self
                                                    selector:@selector(_checkForChanges)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)stopMonitoring {
    [_monitoringTimer invalidate];
    _monitoringTimer = nil;
    _changeCallback = nil;
}

- (void)_checkForChanges {
    NSArray<WindowInfo *> *currentWindows = [self getAllWindows];

    // Simple change detection - compare window count and basic properties
    BOOL hasChanges = NO;

    if (currentWindows.count != _lastWindowList.count) {
        hasChanges = YES;
    } else {
        // Check for position/size changes
        for (NSUInteger i = 0; i < currentWindows.count; i++) {
            WindowInfo *current = currentWindows[i];
            WindowInfo *last = _lastWindowList[i];

            if (current.windowID != last.windowID ||
                !CGRectEqualToRect(current.bounds, last.bounds) ||
                current.workspace != last.workspace) {
                hasChanges = YES;
                break;
            }
        }
    }

    if (hasChanges) {
        _lastWindowList = currentWindows;
        if (_changeCallback) {
            _changeCallback();
        }
    }
}

@end