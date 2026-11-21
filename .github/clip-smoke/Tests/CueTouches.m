#import "CueTouches.h"
#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>

// These event interfaces belong to the simulator UI-test runner only.
// The target under test receives normal touch events at two distinct points.
@protocol QAPointerPath
- (id)initForTouchAtPoint:(CGPoint)point offset:(double)offset;
- (void)moveToPoint:(CGPoint)point atOffset:(double)offset;
- (void)liftUpAtOffset:(double)offset;
@end
@protocol QAEventRecord
- (id)initWithName:(NSString *)name interfaceOrientation:(NSInteger)orientation;
- (void)addPointerEventPath:(id)path;
@end
@protocol QAEventDriver
- (void)synthesizeEvent:(id)record completion:(void (^)(BOOL, NSError *))finish;
@end
@interface XCUIDevice (QATouchSynthesis)
- (id<QAEventDriver>)eventSynthesizer;
@end

void QASwipeDownWithTwoContacts(CGRect screen, void (^completion)(BOOL, NSString *)) {
    Class recordClass = NSClassFromString(@"XCSynthesizedEventRecord");
    Class pathClass = NSClassFromString(@"XCPointerEventPath");
    XCUIDevice *device = XCUIDevice.sharedDevice;
    if (![recordClass instancesRespondToSelector:@selector(initWithName:interfaceOrientation:)] ||
        ![pathClass instancesRespondToSelector:@selector(initForTouchAtPoint:offset:)] ||
        ![device respondsToSelector:@selector(eventSynthesizer)]) {
        completion(NO, @"The XCTest multi-contact simulator driver is unavailable.");
        return;
    }
    id<QAEventRecord> record = [(id<QAEventRecord>)[recordClass alloc] initWithName:@"Two-finger return"
            interfaceOrientation:UIInterfaceOrientationPortrait];
    for (int i = 0; i < 2; i++) {
        CGFloat x = CGRectGetMidX(screen) + (i == 0 ? -34 : 34);
        CGFloat y = CGRectGetMinY(screen) + 0.34 * CGRectGetHeight(screen);
        id<QAPointerPath> path = [(id<QAPointerPath>)[pathClass alloc] initForTouchAtPoint:CGPointMake(x, y) offset:0];
        for (int step = 1; step <= 6; step++) {
            [path moveToPoint:CGPointMake(x, y + 25 * step) atOffset:0.026 * step];
        }
        [path liftUpAtOffset:0.18];
        [record addPointerEventPath:path];
    }
    [[device eventSynthesizer] synthesizeEvent:record completion:^(BOOL result, NSError *error) {
        completion(result && !error, error.localizedDescription ?: @"");
    }];
}
