//
//  WindowDetector.h
//  MacPenguins
//
//  Created by MacPenguins on 26/11/2024.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface WindowInfo : NSObject
@property (nonatomic, assign) CGRect bounds;
@property (nonatomic, assign) CGWindowID windowID;
@property (nonatomic, assign) int level;
@property (nonatomic, assign) int workspace;
@property (nonatomic, strong) NSString *ownerName;
@property (nonatomic, strong) NSString *windowName;
@property (nonatomic, assign) BOOL isOnScreen;
@end

@interface WindowDetector : NSObject

+ (instancetype)sharedInstance;

// Core window detection methods
- (NSArray<WindowInfo *> *)getAllWindows;
- (NSArray<WindowInfo *> *)getVisibleWindows;
- (NSArray<WindowInfo *> *)getWindowsInCurrentSpace;

// Workspace/Spaces support
- (NSArray<NSNumber *> *)getAllSpaces;
- (NSNumber *)getCurrentSpace;
- (NSArray<WindowInfo *> *)getWindowsForSpace:(NSNumber *)spaceID;

// Screen and display info
- (NSArray<NSValue *> *)getAllDisplayBounds;
- (CGRect)getCombinedDisplayBounds;

// Window change monitoring
- (void)startMonitoring:(void(^)(void))callback;
- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END