//
//  ASAVkontakteCommunicator.m
//
//  Created by Andrew Shmig on 18.12.12.
//

#import "ASAVkontakteCommunicator.h"
#import "ASAVkontakteUserAccount.h"

#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation ASAVkontakteCommunicator
{
    const NSString *_app_id;
    const NSString *_settings;
    NSString *_redirect_url;
    NSString *_display;

    UIWebView *_inner_web_view;
    UIActivityIndicatorView *_activity_indicator;

    void (^_cancel_block) (void);
    void (^_accepted_block) (ASAVkontakteUserAccount *);
}

#pragma mark - Init methods

- (id)initWithWebView:(UIWebView *)webView
{
    DDLogVerbose(@"%s", __FUNCTION__);
    
    self = [super init];

    if (self) {
        // init
        _app_id = kVkontakteAppId;
        _settings = kVkontaktePermissionList;
        _redirect_url = @"https://oauth.vk.com/blank.html";
        _display = @"touch";

        _inner_web_view = webView;
        [_inner_web_view setDelegate:self];

        CGPoint centerPoint = [_inner_web_view center];
        CGRect frame = CGRectMake(centerPoint.x - 20, centerPoint.y - 50, 30, 30);
        _activity_indicator = [[UIActivityIndicatorView alloc]
                                                        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_activity_indicator setColor:[UIColor darkGrayColor]];
        [_activity_indicator setFrame:frame];
        [_activity_indicator setHidesWhenStopped:YES];
        [_activity_indicator setHidden:NO];

        [_inner_web_view addSubview:_activity_indicator];
    }

    return self;
}

#pragma mark - Public ASAVkontakteCommunicator Methods

- (void)startOnCancelBlock:(void (^)(void))cancelBlock
            onSuccessBlock:(void (^)(ASAVkontakteUserAccount *))acceptedBlock
{
    DDLogVerbose(@"%s", __FUNCTION__);

    _cancel_block = [cancelBlock copy];
    _accepted_block = [acceptedBlock copy];

    // формируем УРЛ на который необходимо переадресовать пользователя для авторизации нашего приложения
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://oauth.vk.com/authorize?client_id=%@&redirect_uri=%@&scope=%@&response_type=token&display=%@",
                                                                 _app_id,
                                                                 _redirect_url,
                                                                 _settings,
                                                                 _display]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    [_inner_web_view loadRequest:request];
}

#pragma mark - WebView Delegate Methods

- (BOOL)           webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
            navigationType:(UIWebViewNavigationType)navigationType
{
    DDLogVerbose(@"%s", __FUNCTION__);

    NSString *url = [NSString stringWithFormat:@"%@", [request URL]];
    DDLogVerbose(@"url: %@", url);

    // проверяем какой УРЛ мы сейчас обрабатываем
    if ([url hasPrefix:_redirect_url]) {
        NSString *query_string = [url substringFromIndex:[_redirect_url length] + 1];

        // проверим, какой запрос был возвращен - согласен ли пользователь дать доступ к своему профилю или нет
        if ([query_string hasPrefix:@"access_token"]) {
            NSArray *parts = [query_string componentsSeparatedByString:@"&"];

            // согласен, обрабатываем
            NSString *access_token = [parts[0] componentsSeparatedByString:@"="][1];
            NSInteger expiration_time = [[parts[1] componentsSeparatedByString:@"="][1] integerValue];
            NSInteger user_id = [[parts[2] componentsSeparatedByString:@"="][1] integerValue];

            DDLogVerbose(@"accessToken: %@", access_token);
            DDLogVerbose(@"expirationTime: %i", expiration_time);
            DDLogVerbose(@"userId: %i", user_id);

            ASAVkontakteUserAccount *user_account = [[ASAVkontakteUserAccount alloc]
                                                                            initUserAccountWithAccessToken:access_token
                                                                                            expirationTime:expiration_time
                                                                                                    userId:user_id];
            // ура! мы получили доступ к пользовательскому аккаунту
            _accepted_block(user_account);

        } else {
            // пользователь отказал в доступе нашего приложения к своему профилю
            _cancel_block();

        }
    }

    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    DDLogVerbose(@"%s", __FUNCTION__);

    // отображаем индикатор загрузки
    [_activity_indicator stopAnimating];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    DDLogVerbose(@"%s", __FUNCTION__);

    // прячем индикатор загрузки
    [_activity_indicator startAnimating];
}

@end
