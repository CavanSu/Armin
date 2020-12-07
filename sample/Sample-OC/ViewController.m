//
//  ViewController.m
//  Sample-OC
//
//  Created by CavanSu on 2020/8/18.
//  Copyright © 2020 CavanSu. All rights reserved.
//

#import "ViewController.h"
#import <Armin/Armin-Swift.h>

@interface ViewController () <ArminDelegateOC, ArLogTubeOC>
@property (nonatomic, strong) ArminOC *client;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.client = [[ArminOC alloc] initWithDelegate:self
                                            logTube:self];
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
    } fail:^NSTimeInterval(ArErrorOC * _Nonnull error) {
        NSLog(@"error: %@", error.localizedDescription);
        return 0;
    }];
}

- (void)postRequest {
    NSString *url = @"";
    ArRequestEventOC *event = [[ArRequestEventOC alloc] initWithName:@"Sample-Post"];
    ArRequestTypeObjectOC *type = [[ArRequestTypeJsonObjectOC alloc] initWithMethod:ArHTTPMethodOCPost
                                                                                url:url];
    
    ArRequestTaskOC *task = [[ArRequestTaskOC alloc] initWithEvent:event
                                                              type:type
                                                           timeout:10
                                                            header:nil
                                                        parameters:nil];
    
    [self.client requestWithTask:task
             responseOnMainQueue:YES
          successCallbackContent:ArResponseTypeOCJson
                         success:^(ArResponseOC * _Nonnull response) {
        NSLog(@"weather json: %@", response.json);
    } fail:^NSTimeInterval(ArErrorOC * _Nonnull error) {
        NSLog(@"error: %@", error.localizedDescription);
        return 0;
    }];
}

- (void)uploadTask {
    NSString *url = @"";
    ArRequestEventOC *event = [[ArRequestEventOC alloc] initWithName:@"Sample-Upload"];
    ArUploadObjectOC *object = [[ArUploadObjectOC alloc] initWithFileKeyOnServer:@"server-input"
                                                                        fileName:@"test"
                                                                        fileData:[[NSData alloc] init]
                                                                            mime:ArFileMIMEOCPng];
    
    ArUploadTaskOC *task = [[ArUploadTaskOC alloc] initWithEvent:event
                                                         timeout:10
                                                          object:object
                                                             url:url
                                                          header:nil
                                                      parameters:nil];
    
    [self.client uploadWithTask:task
            responseOnMainQueue:YES
         successCallbackContent:ArResponseTypeOCBlank
                        success:^(ArResponseOC * _Nonnull response) {
        NSLog(@"upload success");
    } fail:^NSTimeInterval(ArErrorOC * _Nonnull error) {
        NSLog(@"error: %@", error.localizedDescription);
        return -1;
    }];
}

#pragma mark - ArminDelegateOC, ArLogTube
- (void)armin:(ArminOC *)client
requestSuccess:(ArRequestEventOC *)event
    startTime:(NSTimeInterval)startTime
          url:(NSString *)url {
    NSLog(@"event: %@, requestSuccess, url: %@", event.name, url);
}

- (void)armin:(ArminOC *)client
  requestFail:(ArErrorOC *)error
        event:(ArRequestEventOC *)event
          url:(NSString *)url {
    NSLog(@"event: %@, requestFail, url: %@", event.name, url);
}

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
