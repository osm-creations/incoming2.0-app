#import <Foundation/Foundation.h>
#import <Security/Security.h>

// Give only this simulator test app the selected fake refresh token before the
// unmodified production entry point restores its session using the real network client.
__attribute__((constructor)) static void seedFixtureSession(void) {
    @autoreleasepool {
        NSString *token = NSProcessInfo.processInfo.environment[@"QA_RESTORE_TOKEN"];
        if (!token.length && !NSProcessInfo.processInfo.environment[@"QA_CLEAR_SESSION"]) return;
        NSDictionary *query = @{
            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService: @"com.osmcreations.incoming2.auth",
            (__bridge id)kSecAttrAccount: @"refresh_token",
        };
        SecItemDelete((__bridge CFDictionaryRef)query);
        if (!token.length) return;
        NSMutableDictionary *add = [query mutableCopy];
        add[(__bridge id)kSecValueData] = [token dataUsingEncoding:NSUTF8StringEncoding];
        add[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef)add, NULL);
        NSCAssert(status == errSecSuccess, @"Fixture keychain setup failed: %d", (int)status);
    }
}
