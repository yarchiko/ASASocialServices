//
//  DPVkontakteCommunicator.h
//
//  Created by Andrew Shmig on 18.12.12.
//  Copyright (c) 2012 DigiPeople Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DPVkontakteUserAccount;

static const NSString *kVKONTAKTE_APP_ID = @"3541027";
static const NSString *kVKONTAKTE_PRIVATE_KEY = @"EImkkJQ8jF7obXFVSHIZ";
static const NSString *kVKONTAKTE_PERMISSIONS_LIST = @"friends,status,wall,messages,offline,photos";

@interface DPVkontakteCommunicator : NSObject <UIWebViewDelegate>

- (id)initWithWebView:(UIWebView *)webView;

- (void)startOnCancelBlock:(void (^)(void))cancelBlock
              onErrorBlock:(void (^)(NSError *))errorBlock
            onSuccessBlock:(void (^)(DPVkontakteUserAccount *))acceptedBlock;

@end
