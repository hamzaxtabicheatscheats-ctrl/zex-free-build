#import "AppDelegate.h"
#import "MCMFilzaIntegration.h"
#import "ZEXFileService.h"
#import "ZEXInjectorVC.h"
#include <fcntl.h>
#include <unistd.h>
#import "sandbox_escape.h"
#import "kexploit/kexploit_opa334.h"
#import "kexploit/kutils.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // 1. Initialize Modern MCM Bridge for iOS 17 - 26+
        MCMFilzaStart();
        
        // 2. Only run kexploit on iOS 15.0 - 16.6.1 when sandbox is restricted
        NSString *ver = [[UIDevice currentDevice] systemVersion];
        NSComparisonResult cmp16 = [ver compare:@"16.6.1" options:NSNumericSearch];
        if (cmp16 != NSOrderedDescending) {
            int fd = open("/var/mobile/.sbx_check", O_WRONLY | O_CREAT | O_TRUNC, 0644);
            if (fd >= 0) {
                close(fd);
                unlink("/var/mobile/.sbx_check");
                NSLog(@"[ZEX] Sandbox already unrestricted.");
            } else {
                NSLog(@"[ZEX] Attempting legacy kexploit_opa334 on iOS %@...", ver);
                @try {
                    int kret = kexploit_opa334();
                    if (kret == 0) {
                        uint64_t self_proc_addr = proc_self();
                        int sret = sandbox_escape(self_proc_addr);
                        NSLog(@"[ZEX] sandbox_escape returned: %d", sret);
                    }
                } @catch (NSException *e) {
                    NSLog(@"[ZEX] kexploit exception: %@", e);
                }
            }
        }
    });
    
    UIColor *bg = [UIColor colorWithRed:.04 green:.01 blue:.02 alpha:1];
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = bg;
    ZEXInjectorVC *vc = [[ZEXInjectorVC alloc] init];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    self.window.backgroundColor = bg;
    return YES;
}

@end
