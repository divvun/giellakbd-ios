@import Sentry;
#import <Foundation/Foundation.h>

// This tire fire of code runs before absolutely anything else, guaranteeing that Sentry can init.
__attribute__((constructor)) static void init_sentry(void) {
    NSLog(@"Running Sentry init");
    
    NSError *error = nil;
    NSString* dsn = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"SentryDSN"];
    
    if (dsn != nil) {
        [SentrySDK startWithConfigureOptions:^(SentryOptions *options) {
            options.dsn = dsn;
#if DEBUG
            // Helpful to see what's going on, but logs heavily, so not in release builds.
            options.debug = YES;
#endif
        }];

        if (error != nil) {
            NSLog(@"%@", error);
        } else {
            NSLog(@"Sentry init successful");
        }
    } else {
        NSLog(@"No DSN; not loading Sentry.");
    }
}
