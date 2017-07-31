//
//  KUSSessionsViewController.m
//  Kustomer
//
//  Created by Daniel Amitay on 7/16/17.
//  Copyright © 2017 Kustomer. All rights reserved.
//

#import "KUSSessionsViewController.h"

#import "KUSAPIClient.h"
#import "KUSChatSessionsDataSource.h"
#import "KUSChatViewController.h"

#import "KUSAvatarTitleView.h"
#import "KUSColor.h"
#import "KUSImage.h"
#import "KUSChatPlaceholderTableViewCell.h"
#import "KUSChatSessionTableViewCell.h"

@interface KUSSessionsViewController () <KUSPaginatedDataSourceListener, UITableViewDataSource, UITableViewDelegate> {
    KUSAPIClient *_apiClient;

    KUSChatSessionsDataSource *_chatSessionsDataSource;
    BOOL _didHandleFirstLoad;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *createSessionButton;

@end

@implementation KUSSessionsViewController

#pragma mark - Lifecycle methods

- (instancetype)initWithAPIClient:(KUSAPIClient *)apiClient
{
    self = [super init];
    if (self) {
        _apiClient = apiClient;
    }
    return self;
}

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:self.navigationItem.backBarButtonItem.style
                                                                            target:nil
                                                                            action:nil];

    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                   target:self
                                                                                   action:@selector(_dismiss)];
    barButtonItem.style = UIBarButtonItemStyleDone;
    self.navigationItem.rightBarButtonItem = barButtonItem;

    self.navigationItem.titleView = [[KUSAvatarTitleView alloc] init];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 88.0;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    [self.view addSubview:self.tableView];

    CGFloat buttonRadius = 4.0;
    CGSize size = CGSizeMake(buttonRadius * 2.0, buttonRadius * 2.0);
    UIImage *circularImage = [KUSImage circularImageWithSize:size color:[KUSColor blueColor]];
    UIEdgeInsets capInsets = UIEdgeInsetsMake(buttonRadius, buttonRadius, buttonRadius, buttonRadius);
    UIImage *buttonImage = [circularImage resizableImageWithCapInsets:capInsets];

    // TODO: Encapsulate into class
    self.createSessionButton = [[UIButton alloc] init];
    self.createSessionButton.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin
                                                 | UIViewAutoresizingFlexibleLeftMargin
                                                 | UIViewAutoresizingFlexibleRightMargin);
    [self.createSessionButton setTitle:@"New Conversation" forState:UIControlStateNormal];
    self.createSessionButton.titleLabel.textColor = [UIColor whiteColor];
    self.createSessionButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
    [self.createSessionButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    self.createSessionButton.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    self.createSessionButton.layer.shadowOffset = CGSizeMake(1.0, 1.0);
    self.createSessionButton.layer.shadowRadius = 1.0;
    self.createSessionButton.layer.shadowOpacity = 0.5;
    [self.createSessionButton addTarget:self
                                 action:@selector(_createSession)
                       forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.createSessionButton];

    self.tableView.hidden = YES;
    self.createSessionButton.hidden = YES;

    _chatSessionsDataSource = [[KUSChatSessionsDataSource alloc] initWithAPIClient:_apiClient];
    [_chatSessionsDataSource addListener:self];
    [_chatSessionsDataSource fetchLatest];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [_chatSessionsDataSource fetchLatest];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    self.tableView.frame = self.view.bounds;

    // TODO: Extract layout constants
    CGSize createSessionButtonSize = CGSizeMake(182.0, 44.0);
    self.createSessionButton.frame = (CGRect) {
        .origin.x = (self.view.bounds.size.width - createSessionButtonSize.width) / 2.0,
        .origin.y = self.view.bounds.size.height - createSessionButtonSize.height - self.bottomLayoutGuide.length - 23.0,
        .size = createSessionButtonSize
    };
}

#pragma mark - Interface element methods

- (void)_createSession
{
    KUSChatViewController *chatViewController = [[KUSChatViewController alloc] initWithAPIClient:_apiClient
                                                                     forNewSessionWithBackButton:YES];
    [self.navigationController pushViewController:chatViewController animated:YES];
}

- (void)_dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Internal methods

- (void)_handleFirstLoadIfNecessary
{
    if (_didHandleFirstLoad) {
        return;
    }
    _didHandleFirstLoad = YES;

    if (_chatSessionsDataSource.count == 0) {
        // If there are no existing chat sessions, go directly to new chat screen
        KUSChatViewController *chatViewController = [[KUSChatViewController alloc] initWithAPIClient:_apiClient
                                                                         forNewSessionWithBackButton:NO];
        [self.navigationController pushViewController:chatViewController animated:NO];
    } else if (_chatSessionsDataSource.count == 1) {
        // If there is exactly one chat session, go directly to it
        KUSChatSession *chatSession = [_chatSessionsDataSource firstObject];
        KUSChatViewController *chatViewController = [[KUSChatViewController alloc] initWithAPIClient:_apiClient
                                                                                      forChatSession:chatSession];
        [self.navigationController pushViewController:chatViewController animated:NO];
    }
}

#pragma mark - KUSPaginatedDataSourceListener methods

- (void)paginatedDataSourceDidLoad:(KUSPaginatedDataSource *)dataSource
{
    [self.tableView reloadData];
    self.tableView.hidden = NO;
    self.createSessionButton.hidden = NO;

    [self _handleFirstLoadIfNecessary];
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    CGFloat visibleTableHeight = tableView.bounds.size.height - tableView.contentInset.top - tableView.contentInset.bottom;
    CGFloat rowCountThatFitsHeight = visibleTableHeight / tableView.rowHeight;
    NSUInteger minimumRowCount = (NSUInteger)floor(rowCountThatFitsHeight);
    return MAX(_chatSessionsDataSource.count, minimumRowCount);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isSessionRow = indexPath.row < _chatSessionsDataSource.count;
    if (isSessionRow) {
        static NSString *kSessionCellIdentifier = @"SessionCell";
        KUSChatSessionTableViewCell *cell = (KUSChatSessionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kSessionCellIdentifier];
        if (cell == nil) {
            cell = [[KUSChatSessionTableViewCell alloc] initWithReuseIdentifier:kSessionCellIdentifier apiClient:_apiClient];
        }

        KUSChatSession *chatSession = [_chatSessionsDataSource objectAtIndex:indexPath.row];
        [cell setChatSession:chatSession];

        return cell;
    }

    static NSString *kPlaceholderCellIdentifier = @"PlaceholderCell";
    KUSChatPlaceholderTableViewCell *cell = (KUSChatPlaceholderTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kPlaceholderCellIdentifier];
    if (cell == nil) {
        cell = [[KUSChatPlaceholderTableViewCell alloc] initWithReuseIdentifier:kPlaceholderCellIdentifier];
    }
    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    KUSChatSession *chatSession = [_chatSessionsDataSource objectAtIndex:indexPath.row];
    KUSChatViewController *chatViewController = [[KUSChatViewController alloc] initWithAPIClient:_apiClient forChatSession:chatSession];
    [self.navigationController pushViewController:chatViewController animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isSessionRow = indexPath.row < _chatSessionsDataSource.count;
    return isSessionRow;
}

@end