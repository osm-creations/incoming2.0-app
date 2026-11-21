#import <UIKit/UIKit.h>
#import <notify.h>

static void inspect(UIView *view, NSMutableArray *matches) {
    Class systemVolumeView = NSClassFromString(@"MPVolumeView");
    NSString *identifier = view.accessibilityIdentifier;
    if ((systemVolumeView && [view isKindOfClass:systemVolumeView])
            || [identifier isEqualToString:@"performance.systemVolumeView"]
            || [identifier isEqualToString:@"performance.volumeMeter"]) {
        [matches addObject:NSStringFromClass(view.class)];
    }
    for (UIView *child in view.subviews) inspect(child, matches);
}

static void registerStage(NSString *stage) {
    int token = 0;
    NSString *name = [@"com.osmcreations.qa.clip24.native." stringByAppendingString:stage];
    int status = notify_register_dispatch(name.UTF8String, &token, dispatch_get_main_queue(), ^(int unused) {
        NSMutableArray *matches = [NSMutableArray new];
        NSUInteger windows = 0;
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                if (!window.hidden) windows++;
                inspect(window, matches);
            }
        }
        NSDictionary *event = @{@"stage":stage, @"windows":@(windows), @"views":matches};
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
        for (NSString *stage in @[@"notes", @"armed", @"revealed", @"returned", @"afterUp", @"afterDown"]) registerStage(stage);
    }];
}
@end
