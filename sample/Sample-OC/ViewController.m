//
//  ViewController.m
//  Sample-OC
//
//  Created by CavanSu on 2020/8/18.
//  Copyright © 2020 CavanSu. All rights reserved.
//

#import <Armin/Armin-Swift.h>
#import "ViewController.h"

@interface ViewController () <ArLogTube>
@property (nonatomic, strong) ArminClient *client;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.client = [[ArminClient alloc] initWithLogTube:self];
    [self getRequest];
}

- (void)getRequest {
    NSString *url = @"https://www.tianqiapi.com/api";
    
    NSDictionary *parameters = @{@"appid": @"23035354",
                                 @"appsecret": @"8YvlPNrz",
                                 @"version": @"v9",
                                 @"cityid": @"0",
                                 @"city": @"%E9%9D%92%E5%B2%9B",
                                 @"ip": @"0",
                                 @"callback": @"0"};
    
    [self.client objc_requestWithUrl:url
                             headers:nil
                          parameters:parameters
                              method:ArHttpMethodGet
                               event:@"Sample-Get"
                             timeout:10
                       responseQueue:dispatch_get_main_queue()
                          retryCount:0
                         jsonSuccess:^(NSDictionary<NSString *,id> * _Nonnull json) {
        NSLog(@"weather json: %@", json);
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"error: %@", error.localizedDescription);
    }];
}

#pragma mark - ArLogTube
- (void)logWithInfo:(NSString *)info
              extra:(NSString *)extra {
    NSLog(@"log info: %@, extra: %@", info, extra);
}

- (void)logWithWarning:(NSString *)warning
                 extra:(NSString *)extra {
    NSLog(@"log warning: %@, extra: %@", warning, extra);
}

- (void)logWithError:(NSError *)error
               extra:(NSString *)extra {
    NSLog(@"log error: %@, extra: %@", error, extra);
}
@end
