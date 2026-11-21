#import <AVFAudio/AVFAudio.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>

// Local test-host input only. The product, public audio-session setter behavior,
// clip lifecycle, and captured value-comparison path are left intact.
static float fixtureVolume = 0.5f;

static float readFixtureVolume(id receiver, SEL cmd) {
    return fixtureVolume;
}

static void registerLevel(AVAudioSession *audio, const char *signal, float level) {
    int token;
    int result = notify_register_dispatch(signal, &token, dispatch_get_main_queue(), ^(int _) {
        [audio willChangeValueForKey:@"outputVolume"];
        fixtureVolume = level;
        [audio didChangeValueForKey:@"outputVolume"];
    });
    NSCAssert(result == NOTIFY_STATUS_OK, @"Failed to install fixture volume control");
}

@interface FixtureVolume : NSObject
@end

@implementation FixtureVolume
+ (void)load {
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidFinishLaunchingNotification
        object:nil queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *notification) {
            AVAudioSession *audio = AVAudioSession.sharedInstance;
            Class audioClass = object_getClass(audio);
            SEL getter = @selector(outputVolume);
            Method original = class_getInstanceMethod(audioClass, getter);
            NSCAssert(original, @"Public volume getter unavailable");
            class_replaceMethod(audioClass, getter, (IMP)readFixtureVolume, method_getTypeEncoding(original));
            registerLevel(audio, "com.osmcreations.qa.clip21.low", 0.25f);
            registerLevel(audio, "com.osmcreations.qa.clip21.mid", 0.50f);
            registerLevel(audio, "com.osmcreations.qa.clip21.high", 0.75f);
            registerLevel(audio, "com.osmcreations.qa.clip21.higher", 0.90f);
        }];
}
@end
