//
//  FLEXManager+Extensibility.m
//  FLEX
//
//  Created by Tanner on 2/2/20.
//  Copyright © 2020 Flipboard. All rights reserved.
//

#import "FLEXManager+Extensibility.h"
#import "FLEXManager+Private.h"
#import "FLEXGlobalsEntry.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXKeyboardShortcutManager.h"
#import "FLEXExplorerViewController.h"
#import "FLEXNetworkHistoryTableViewController.h"
#import "FLEXKeyboardHelpViewController.h"
#import "FLEXFileBrowserTableViewController.h"

@interface FLEXManager (ExtensibilityPrivate)
@property (nonatomic, readonly) UIViewController *topViewController;
@end

@implementation FLEXManager (Extensibility)

#pragma mark - Globals Screen Entries

- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock {
    NSParameterAssert(entryName);
    NSParameterAssert(objectFutureBlock);
    NSAssert([NSThread isMainThread], @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsEntry *entry = [FLEXGlobalsEntry entryWithNameFuture:^NSString *{
        return entryName;
    } viewControllerFuture:^UIViewController *{
        return [FLEXObjectExplorerFactory explorerViewControllerForObject:objectFutureBlock()];
    }];

    [self.userGlobalEntries addObject:entry];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName viewControllerFutureBlock:(UIViewController * (^)(void))viewControllerFutureBlock {
    NSParameterAssert(entryName);
    NSParameterAssert(viewControllerFutureBlock);
    NSAssert([NSThread isMainThread], @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsEntry *entry = [FLEXGlobalsEntry entryWithNameFuture:^NSString *{
        return entryName;
    } viewControllerFuture:^UIViewController *{
        UIViewController *viewController = viewControllerFutureBlock();
        NSCAssert(viewController, @"'%@' entry returned nil viewController. viewControllerFutureBlock should never return nil.", entryName);
        return viewController;
    }];

    [self.userGlobalEntries addObject:entry];
}


#pragma mark - Simulator Shortcuts

- (void)registerSimulatorShortcutWithKey:(NSString *)key modifiers:(UIKeyModifierFlags)modifiers action:(dispatch_block_t)action description:(NSString *)description {
#if TARGET_OS_SIMULATOR
    [[FLEXKeyboardShortcutManager sharedManager] registerSimulatorShortcutWithKey:key modifiers:modifiers action:action description:description];
#endif
}

- (void)setSimulatorShortcutsEnabled:(BOOL)simulatorShortcutsEnabled {
#if TARGET_OS_SIMULATOR
    [[FLEXKeyboardShortcutManager sharedManager] setEnabled:simulatorShortcutsEnabled];
#endif
}

- (BOOL)simulatorShortcutsEnabled {
#if TARGET_OS_SIMULATOR
    return [[FLEXKeyboardShortcutManager sharedManager] isEnabled];
#else
    return NO;
#endif
}

- (void)registerDefaultSimulatorShortcuts {
    [self registerSimulatorShortcutWithKey:@"f" modifiers:0 action:^{
        [self toggleExplorer];
    } description:@"Toggle FLEX toolbar"];
    
    [self registerSimulatorShortcutWithKey:@"g" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleMenuTool];
    } description:@"Toggle FLEX globals menu"];
    
    [self registerSimulatorShortcutWithKey:@"v" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleViewsTool];
    } description:@"Toggle view hierarchy menu"];
    
    [self registerSimulatorShortcutWithKey:@"s" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleSelectTool];
    } description:@"Toggle select tool"];
    
    [self registerSimulatorShortcutWithKey:@"m" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleMoveTool];
    } description:@"Toggle move tool"];
    
    [self registerSimulatorShortcutWithKey:@"n" modifiers:0 action:^{
        [self toggleTopViewControllerOfClass:[FLEXNetworkHistoryTableViewController class]];
    } description:@"Toggle network history view"];
    
    [self registerSimulatorShortcutWithKey:UIKeyInputDownArrow modifiers:0 action:^{
        if (self.isHidden) {
            [self tryScrollDown];
        } else {
            [self.explorerViewController handleDownArrowKeyPressed];
        }
    } description:@"Cycle view selection\n\t\tMove view down\n\t\tScroll down"];
    
    [self registerSimulatorShortcutWithKey:UIKeyInputUpArrow modifiers:0 action:^{
        if (self.isHidden) {
            [self tryScrollUp];
        } else {
            [self.explorerViewController handleUpArrowKeyPressed];
        }
    } description:@"Cycle view selection\n\t\tMove view up\n\t\tScroll up"];
    
    [self registerSimulatorShortcutWithKey:UIKeyInputRightArrow modifiers:0 action:^{
        if (!self.isHidden) {
            [self.explorerViewController handleRightArrowKeyPressed];
        }
    } description:@"Move selected view right"];
    
    [self registerSimulatorShortcutWithKey:UIKeyInputLeftArrow modifiers:0 action:^{
        if (self.isHidden) {
            [self tryGoBack];
        } else {
            [self.explorerViewController handleLeftArrowKeyPressed];
        }
    } description:@"Move selected view left"];
    
    [self registerSimulatorShortcutWithKey:@"?" modifiers:0 action:^{
        [self toggleTopViewControllerOfClass:[FLEXKeyboardHelpViewController class]];
    } description:@"Toggle (this) help menu"];
    
    [self registerSimulatorShortcutWithKey:UIKeyInputEscape modifiers:0 action:^{
        [[self.topViewController presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    } description:@"End editing text\n\t\tDismiss top view controller"];
    
    [self registerSimulatorShortcutWithKey:@"o" modifiers:UIKeyModifierCommand|UIKeyModifierShift action:^{
        [self toggleTopViewControllerOfClass:[FLEXFileBrowserTableViewController class]];
    } description:@"Toggle file browser menu"];
}

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.sharedManager registerDefaultSimulatorShortcuts];
    });
}


#pragma mark - Private

- (void)tryScrollDown {
    UIScrollView *firstScrollView = [self firstScrollView];
    CGPoint contentOffset = firstScrollView.contentOffset;
    CGFloat distance = floor(firstScrollView.frame.size.height / 2.0);
    CGFloat maxContentOffsetY = firstScrollView.contentSize.height + firstScrollView.contentInset.bottom - firstScrollView.frame.size.height;
    distance = MIN(maxContentOffsetY - firstScrollView.contentOffset.y, distance);
    contentOffset.y += distance;
    [firstScrollView setContentOffset:contentOffset animated:YES];
}

- (void)tryScrollUp {
    UIScrollView *firstScrollView = [self firstScrollView];
    CGPoint contentOffset = firstScrollView.contentOffset;
    CGFloat distance = floor(firstScrollView.frame.size.height / 2.0);
    CGFloat minContentOffsetY = -firstScrollView.contentInset.top;
    distance = MIN(firstScrollView.contentOffset.y - minContentOffsetY, distance);
    contentOffset.y -= distance;
    [firstScrollView setContentOffset:contentOffset animated:YES];
}

- (UIScrollView *)firstScrollView {
    NSMutableArray<UIView *> *views = [UIApplication.sharedApplication.keyWindow.subviews mutableCopy];
    UIScrollView *scrollView = nil;
    while (views.count > 0) {
        UIView *view = views.firstObject;
        [views removeObjectAtIndex:0];
        if ([view isKindOfClass:[UIScrollView class]]) {
            scrollView = (UIScrollView *)view;
            break;
        } else {
            [views addObjectsFromArray:view.subviews];
        }
    }
    return scrollView;
}

- (void)tryGoBack {
    UINavigationController *navigationController = nil;
    UIViewController *topViewController = self.topViewController;
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        navigationController = (UINavigationController *)topViewController;
    } else {
        navigationController = topViewController.navigationController;
    }
    [navigationController popViewControllerAnimated:YES];
}

- (UIViewController *)topViewController {
    UIViewController *topViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}

- (void)toggleTopViewControllerOfClass:(Class)class {
    UINavigationController *topViewController = (id)self.topViewController;
    if ([topViewController isKindOfClass:[UINavigationController class]] &&
        [topViewController.topViewController isKindOfClass:[class class]]) {
        [topViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        id viewController = [class new];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
        [topViewController presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)showExplorerIfNeeded {
    if (self.isHidden) {
        [self showExplorer];
    }
}

@end
