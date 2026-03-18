//
//  main.m
//  RelaunchObjC
//
//  Created by Kumaran Vijayan on 2015-12-28.
//
//

#import <AppKit/AppKit.h>

@interface Observer: NSObject
@property (nonatomic, copy) void (^callback)(void);
- (instancetype)initWithCallback:(void (^)(void))callback;
@end
@implementation Observer
- (instancetype)initWithCallback:(void (^)(void))callback {
    self = [super init];
    if (self) {
        _callback = callback;
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
    self.callback();
}
@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) { return 1; }
        int parentPid = atoi(argv[1]);
        NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:parentPid];
        NSURL *bundleURL = app.bundleURL;
        if (!bundleURL) { return 1; }

        Observer *listener = [[Observer alloc] initWithCallback:^{
            CFRunLoopStop(CFRunLoopGetCurrent());
        }];
        [app addObserver:listener forKeyPath:@"isTerminated" options:0 context:nil];
        [app terminate];
        CFRunLoopRun();
        [app removeObserver:listener forKeyPath:@"isTerminated"];

        NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
        config.addsToRecentItems = NO;
        config.activates = NO;
        [[NSWorkspace sharedWorkspace] openApplicationAtURL:bundleURL
                                              configuration:config
                                          completionHandler:^(NSRunningApplication *runningApp, NSError *error) {
            if (error) {
                NSLog(@"Failed to relaunch app: %@", error);
            }
        }];
    }
    return 0;
}
