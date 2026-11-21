#import <UIKit/UIKit.h>
#import <notify.h>

// QA host only. The surface, native volume control and all gestures belong to the product.
@protocol QAObservableVolumeControl
- (BOOL)showsVolumeSlider;
@end

static void inspect(UIView *view, UIWindow *window, NSMutableArray *result) {
    Class cls = NSClassFromString(@"MPVolumeView");
    if (cls && [view isKindOfClass:cls]) {
        CGRect frame = [view convertRect:view.bounds toView:window];
        CGFloat alpha = 1;
        BOOL hidden = NO;
        BOOL interactive = YES;
        for (UIView *v = view; v; v = v.superview) {
            alpha *= v.alpha;
            hidden |= v.hidden;
            interactive &= v.userInteractionEnabled;
        }
        CGPoint middle = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
        UIView *hit = [window hitTest:middle withEvent:nil];
        BOOL intercepts = hit && (hit == view || [hit isDescendantOfView:view]);
        [result addObject:@{
            @"class":NSStringFromClass(view.class), @"identifier":view.accessibilityIdentifier ?: @"",
            @"windowMatch":@(view.window == window), @"windowHidden":@(window.hidden),
            @"intersectsWindow":@(CGRectIntersectsRect(window.bounds, frame)),
            @"width":@(CGRectGetWidth(frame)), @"height":@(CGRectGetHeight(frame)),
            @"x":@(CGRectGetMinX(frame)), @"y":@(CGRectGetMinY(frame)),
            @"alpha":@(view.alpha), @"effectiveAlpha":@(alpha), @"hidden":@(hidden),
            @"effectiveInteraction":@(interactive), @"directInteraction":@(view.userInteractionEnabled),
            @"interceptsHit":@(intercepts), @"accessibilityHidden":@(view.accessibilityElementsHidden),
            @"systemSliderEnabled":@([view respondsToSelector:@selector(showsVolumeSlider)] && [(id<QAObservableVolumeControl>)view showsVolumeSlider])
        }];
    }
    for (UIView *next in view.subviews) inspect(next, window, result);
}

static void registerStage(NSString *stage) {
    int token = 0;
    NSString *name = [@"com.osmcreations.qa.clip23.native." stringByAppendingString:stage];
    int status = notify_register_dispatch(name.UTF8String, &token, dispatch_get_main_queue(), ^(int unused) {
        NSMutableArray *rows = [NSMutableArray new];
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            for (UIWindow *window in ((UIWindowScene *)scene).windows) inspect(window, window, rows);
        }
        NSDictionary *event = @{@"stage":stage, @"views":rows};
        NSData *json = [NSJSONSerialization dataWithJSONObject:event options:0 error:NULL];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://127.0.0.1:8743/test/volume-view"]];
        request.HTTPMethod = @"POST";
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        request.HTTPBody = json;
        [[NSURLSession.sharedSession dataTaskWithRequest:request] resume];
    });
    NSCAssert(status == NOTIFY_STATUS_OK, @"Native host probe failed to register");
}

@interface QAWindowProbe : NSObject
@end
@implementation QAWindowProbe
+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
            object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
        for (NSString *stage in @[@"notes", @"armed", @"revealed", @"returned"]) registerStage(stage);
    }];
}
@end
