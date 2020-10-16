//
//  ViewController.m
//  Sample-OC
//
//  Created by CavanSu on 2020/8/18.
//  Copyright © 2020 CavanSu. All rights reserved.
//

#import "ViewController.h"
#import <Armin/Armin-Swift.h>

@interface ViewController ()
@property (nonatomic, strong) ArminOC *client;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.client = [[ArminOC alloc] init];
    [self getRequest];
}

- (void)getRequest {
    NSString *url = @"https://www.tianqiapi.com/api";
    ArRequestEventOC *event = [[ArRequestEventOC alloc] initWithName:@"Sample-Get"];
    ArRequestTypeObjectOC *type = [[ArRequestTypeJsonObjectOC alloc] initWithMethod:ArHTTPMethodOCGet
                                                                                url:url];
    
    ArRequestTaskOC *task = [[ArRequestTaskOC alloc] initWithEvent:event
                                                              type:type
                                                           timeout:10
                                                            header:nil
                                                        parameters:@{@"appid": @"23035354",
                                                                     @"appsecret": @"8YvlPNrz",
                                                                     @"version": @"v9",
                                                                     @"cityid": @"0",
                                                                     @"city": @"%E9%9D%92%E5%B2%9B",
                                                                     @"ip": @"0",
                                                                     @"callback": @"0"}];
    
    [self.client requestWithTask:task
        responseOnMainQueue:YES
     successCallbackContent:ArResponseTypeOCJson
                    success:^(ArResponseOC * _Nonnull response) {
        NSLog(@"weather json: %@", response.json);
    } failRetryInterval:-1 fail:^(NSError * _Nonnull error) {
        NSLog(@"error: %@", error.localizedDescription);
    }];
}

@end
