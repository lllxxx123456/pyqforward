#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - 微信类声明

// 插件管理
@interface WCPluginsMgr : NSObject
+ (instancetype)sharedInstance;
- (void)registerControllerWithTitle:(NSString *)title version:(NSString *)version controller:(NSString *)controller;
@end

// 设置界面表格组件
@interface WCTableViewCellManager : NSObject
+ (id)switchCellForSel:(SEL)arg1 target:(id)arg2 title:(id)arg3 on:(BOOL)arg4;
+ (id)normalCellForSel:(SEL)arg1 target:(id)arg2 title:(id)arg3 rightValue:(id)arg4;
@end
@interface WCTableViewSectionManager : NSObject
+ (id)sectionWithHeader:(NSString *)header;
+ (id)sectionWithFooter:(NSString *)footer;
+ (id)sectionWithHeader:(NSString *)header Footer:(NSString *)footer;
- (void)addCell:(id)arg1;
@end
@interface WCTableViewManager : NSObject
- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style;
@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, weak) id delegate;
- (void)clearAllSection;
- (void)addSection:(id)arg1;
- (id)cellInfoAtIndexPath:(NSIndexPath *)indexPath;
- (void)reloadTableView;
@end

// 朋友圈数据模型
@interface WCDataItem : NSObject <NSCoding>
- (id)contentObj;
@property (retain, nonatomic) id locationInfo;
@end

// 朋友圈操作浮窗
@interface WCOperateFloatViewParams : NSObject
+ (id)defaultParams;
@end
@interface WCOperateFloatView : UIView
@property (readonly, nonatomic) UIButton *m_likeBtn;
@property (readonly, nonatomic) UIButton *m_commentBtn;
@property (readonly, nonatomic) WCDataItem *m_item;
@property (nonatomic, weak) UINavigationController *navigationController;
- (id)initWithParams:(WCOperateFloatViewParams *)params;
- (void)showWithItemData:(WCDataItem *)item tipPoint:(CGPoint)point;
- (double)buttonWidth:(UIButton *)button;
@end

// 朋友圈转发控制器（仅适用于图文/链接转发，视频转发请走重新上传流程）
@interface WCForwardViewController : UIViewController
- (instancetype)initWithDataItem:(WCDataItem *)dataItem;
@end

// 朝友圈发布 VC（视频发布入口）——为 hook 中的 self 提供完整接口声明，避免前向声明导致的 forward declaration 编译错误
@interface WCNewCommitViewController : UIViewController
@property (nonatomic) BOOL hasClickDone;
- (BOOL)dd_isLaunchedByForward;
- (void)dd_dismissForwardLaunched;
- (void)dd_startWatchHasClickDone;
- (void)didFinishCommiting;
- (void)didCancelCommiting;
- (void)OnReturn;
- (void)OnDone;
- (void)doExit;
- (void)viewDidAppear:(BOOL)animated;
@end

// 朋友圈内容与媒体
@interface WCContentItem : NSObject
- (NSArray *)mediaList;
@end
@interface WCMediaItem : NSObject
- (BOOL)hasData;
- (BOOL)hasSight;
- (id)pathForSightData;
- (id)pathForOriginalSightData;
- (id)pathForOriginalSightThumbImage;
- (id)pathForSightThumbImage;
- (id)thumbImage;
@end

// 媒体下载器
@interface WCMediaDownloader : NSObject
- (instancetype)initWithDataItem:(WCDataItem *)dataItem mediaItem:(WCMediaItem *)mediaItem;
- (void)startDownloadWithCompletionHandler:(void (^)(NSError *))completion;
@end

// 加载提示视图
@interface MMLoadingView : UIView
@property (nonatomic, getter=isLoading) BOOL loading;
@property (nonatomic) BOOL ignoreInteractionEventsWhenLoading;
@property (retain, nonatomic) NSString *text;
- (void)startLoading;
- (void)stopLoading;
@end

// 微信内部菜单项（用于获取图标）
@interface MMMenuItem : NSObject
@property (nonatomic, retain) UIImage *iconImage;
@end

#pragma mark - DD 转发分类方法声明（避免跨 category 调用的未声明方法警告）

@class WCDataItem;
@interface NSObject (DDForward)
+ (UIWindow *)currentKeyWindow;
- (void)showLoadingHUD;
- (void)hideLoadingHUD;
- (void)dd_showSimpleAlert:(NSString *)message;
- (void)downloadAllMediaForDataItem:(WCDataItem *)dataItem completion:(void (^)(void))completion;
- (BOOL)dd_dataItemContainsSight:(WCDataItem *)dataItem;
- (id)dd_firstSightMediaItemForDataItem:(WCDataItem *)dataItem;
- (NSString *)dd_localVideoPathForMediaItem:(id)mediaItem;
- (UIImage *)dd_localThumbImageForMediaItem:(id)mediaItem;
- (Class)dd_findSightEditVCClass;
- (UIViewController *)dd_instantiateSightEditVC:(Class)editCls localPath:(NSString *)localPath thumbImage:(UIImage *)thumbImage;
- (id)dd_buildSightDraftItemWithLocalPath:(NSString *)localPath thumbImage:(UIImage *)thumbImage;
- (id)dd_buildSightDraftWithLocalPath:(NSString *)localPath thumbImage:(UIImage *)thumbImage;
- (BOOL)dd_presentEditVC:(UIViewController *)editVC;
- (BOOL)dd_tryForwardSightWithLocalPath:(NSString *)localPath thumbImage:(UIImage *)thumbImage;
- (BOOL)dd_isLaunchedByForward;
- (void)dd_dismissForwardLaunched;
- (void)dd_startWatchHasClickDone;
- (void)xxx_forwordTimeLine:(UIButton *)sender;
@end

#pragma mark - 配置管理

static NSString * const kDDForwardEnabledKey = @"DDForward_Enabled";
static NSString * const kDDRemoveLocationKey = @"DDForward_RemoveLocation";

@interface DDForwardConfig : NSObject
+ (instancetype)sharedConfig;
@property (assign, nonatomic) BOOL forwardEnabled;
@property (assign, nonatomic) BOOL removeLocationEnabled;
@end

@implementation DDForwardConfig

+ (instancetype)sharedConfig {
    static DDForwardConfig *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ config = [DDForwardConfig new]; });
    return config;
}

- (instancetype)init {
    if (self = [super init]) {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        _forwardEnabled = [ud boolForKey:kDDForwardEnabledKey];
        _removeLocationEnabled = [ud boolForKey:kDDRemoveLocationKey];
    }
    return self;
}

- (void)setForwardEnabled:(BOOL)forwardEnabled {
    _forwardEnabled = forwardEnabled;
    [[NSUserDefaults standardUserDefaults] setBool:forwardEnabled forKey:kDDForwardEnabledKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setRemoveLocationEnabled:(BOOL)removeLocationEnabled {
    _removeLocationEnabled = removeLocationEnabled;
    [[NSUserDefaults standardUserDefaults] setBool:removeLocationEnabled forKey:kDDRemoveLocationKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

#pragma mark - 设置界面

@interface DDForwardSettingsViewController : UIViewController <UITableViewDelegate>
@property (nonatomic, strong) WCTableViewManager *tableViewManager;
@end

@implementation DDForwardSettingsViewController {
    id<UITableViewDelegate> _originalDelegate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"DD朋友圈转发";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    _tableViewManager = [[objc_getClass("WCTableViewManager") alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    _tableViewManager.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableViewManager.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    [self.view addSubview:_tableViewManager.tableView];
    
    _originalDelegate = _tableViewManager.delegate;
    _tableViewManager.delegate = self;
    
    [self buildTable];
}

- (void)buildTable {
    [_tableViewManager clearAllSection];
    DDForwardConfig *cfg = [DDForwardConfig sharedConfig];
    
    WCTableViewSectionManager *section = [objc_getClass("WCTableViewSectionManager") sectionWithHeader:@"转发设置"];
    [section addCell:[objc_getClass("WCTableViewCellManager") switchCellForSel:@selector(onForwardEnabledChanged:) target:self title:@"启用朋友圈转发" on:cfg.forwardEnabled]];
    if (cfg.forwardEnabled) {
        [section addCell:[objc_getClass("WCTableViewCellManager") switchCellForSel:@selector(onRemoveLocationChanged:) target:self title:@"↳移除原始位置" on:cfg.removeLocationEnabled]];
    }
    [_tableViewManager addSection:section];
    [_tableViewManager reloadTableView];
}

- (void)onForwardEnabledChanged:(UISwitch *)sender {
    [DDForwardConfig sharedConfig].forwardEnabled = sender.on;
    [self buildTable];
}

- (void)onRemoveLocationChanged:(UISwitch *)sender {
    [DDForwardConfig sharedConfig].removeLocationEnabled = sender.on;
}

#pragma mark - UITableViewDelegate 转发

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_originalDelegate && [_originalDelegate respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
        [_originalDelegate tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_originalDelegate && [_originalDelegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [_originalDelegate tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_originalDelegate && [_originalDelegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
        return [_originalDelegate tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    return UITableViewAutomaticDimension;
}

@end

#pragma mark - 辅助方法

@implementation NSObject (ForwardHelper)

+ (UIWindow *)currentKeyWindow {
    UIWindowScene *scene = (UIWindowScene *)[UIApplication sharedApplication].connectedScenes.allObjects.firstObject;
    return scene.keyWindow;
}

- (void)showLoadingHUD {
    dispatch_async(dispatch_get_main_queue(), ^{
        Class MMLoadingViewClass = objc_getClass("MMLoadingView");
        UIWindow *keyWindow = [NSObject currentKeyWindow];
        if (!MMLoadingViewClass || !keyWindow) return;
        
        UIView *existing = [keyWindow viewWithTag:10086];
        if (existing && [existing isKindOfClass:MMLoadingViewClass]) {
            [(id)existing startLoading];
            return;
        }
        
        id loadingView = [[MMLoadingViewClass alloc] initWithFrame:keyWindow.bounds];
        [loadingView setTag:10086];
        [loadingView setText:@"正在准备转发..."];
        [loadingView setIgnoreInteractionEventsWhenLoading:YES];
        [keyWindow addSubview:loadingView];
        [loadingView startLoading];
    });
}

- (void)hideLoadingHUD {
    dispatch_async(dispatch_get_main_queue(), ^{
        Class MMLoadingViewClass = objc_getClass("MMLoadingView");
        UIView *loadingView = [[NSObject currentKeyWindow] viewWithTag:10086];
        if (loadingView && [loadingView isKindOfClass:MMLoadingViewClass]) {
            [(id)loadingView stopLoading];
            [loadingView removeFromSuperview];
        }
    });
}

- (void)dd_showSimpleAlert:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [NSObject currentKeyWindow];
        UIViewController *root = keyWindow.rootViewController;
        while (root.presentedViewController) root = root.presentedViewController;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"DD朋友圈转发"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
        [root presentViewController:alert animated:YES completion:nil];
    });
}

- (void)downloadAllMediaForDataItem:(WCDataItem *)dataItem completion:(void (^)(void))completion {
    id contentObj = [dataItem contentObj];
    if (![contentObj respondsToSelector:@selector(mediaList)]) {
        if (completion) completion();
        return;
    }
    
    NSArray *mediaList = [contentObj mediaList];
    if (mediaList.count == 0) {
        if (completion) completion();
        return;
    }
    
    NSMutableArray *needDownload = [NSMutableArray array];
    for (id item in mediaList) {
        BOOL hasData = NO;
        if ([item respondsToSelector:@selector(hasData)]) {
            hasData = [item hasData];
        }
        BOOL needDl = !hasData;
        // 对视频(sight)，hasData 为图片缩略图状态，必须额外校验 hasSight
        if ([item respondsToSelector:@selector(hasSight)]) {
            BOOL hasSight = [item hasSight];
            if (!hasSight) needDl = YES;
        }
        if (needDl) {
            [needDownload addObject:item];
        }
    }
    
    if (needDownload.count == 0) {
        if (completion) completion();
        return;
    }
    
    dispatch_group_t group = dispatch_group_create();
    Class downloaderClass = objc_getClass("WCMediaDownloader");
    for (id item in needDownload) {
        dispatch_group_enter(group);
        id downloader = [[downloaderClass alloc] initWithDataItem:dataItem mediaItem:item];
        [downloader startDownloadWithCompletionHandler:^(NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completion) completion();
    });
}

#pragma mark - 视频判定 / 本地路径 / 视频转发

- (BOOL)dd_dataItemContainsSight:(WCDataItem *)dataItem {
    id contentObj = [dataItem contentObj];
    if (![contentObj respondsToSelector:@selector(mediaList)]) return NO;
    NSArray *mediaList = [contentObj mediaList];
    for (id item in mediaList) {
        if ([item respondsToSelector:@selector(hasSight)] && [item hasSight]) return YES;
        @try {
            NSNumber *t = [item valueForKey:@"m_dataType"];
            if ([t isKindOfClass:[NSNumber class]] && t.intValue == 6) return YES;
        } @catch (__unused NSException *e) {}
        @try {
            NSNumber *t = [item valueForKey:@"m_uiType"];
            if ([t isKindOfClass:[NSNumber class]] && t.intValue == 6) return YES;
        } @catch (__unused NSException *e) {}
    }
    return NO;
}

- (id)dd_firstSightMediaItemForDataItem:(WCDataItem *)dataItem {
    id contentObj = [dataItem contentObj];
    if (![contentObj respondsToSelector:@selector(mediaList)]) return nil;
    NSArray *mediaList = [contentObj mediaList];
    for (id item in mediaList) {
        if ([item respondsToSelector:@selector(hasSight)] && [item hasSight]) return item;
    }
    return mediaList.firstObject;
}

- (NSString *)dd_localVideoPathForMediaItem:(id)mediaItem {
    NSArray *selCandidates = @[
        @"pathForSightData",
        @"pathForOriginalSightData",
        @"sightLocalPath",
        @"localPath",
    ];
    for (NSString *selStr in selCandidates) {
        SEL s = NSSelectorFromString(selStr);
        if ([mediaItem respondsToSelector:s]) {
            id ret = ((id (*)(id, SEL))objc_msgSend)(mediaItem, s);
            if ([ret isKindOfClass:[NSString class]] && [(NSString *)ret length] > 0
                && [[NSFileManager defaultManager] fileExistsAtPath:(NSString *)ret]) {
                return (NSString *)ret;
            }
        }
    }
    NSArray *ivarKeys = @[@"m_videoLocalPath", @"m_localPath", @"m_sightPath"];
    for (NSString *k in ivarKeys) {
        @try {
            id v = [mediaItem valueForKey:k];
            if ([v isKindOfClass:[NSString class]] && [(NSString *)v length] > 0
                && [[NSFileManager defaultManager] fileExistsAtPath:(NSString *)v]) {
                return (NSString *)v;
            }
        } @catch (__unused NSException *e) {}
    }
    return nil;
}

- (UIImage *)dd_localThumbImageForMediaItem:(id)mediaItem {
    NSArray *imgSelCandidates = @[@"thumbImage", @"sightThumbImage", @"realThumbImage"];
    for (NSString *selStr in imgSelCandidates) {
        SEL s = NSSelectorFromString(selStr);
        if ([mediaItem respondsToSelector:s]) {
            id ret = ((id (*)(id, SEL))objc_msgSend)(mediaItem, s);
            if ([ret isKindOfClass:[UIImage class]]) return (UIImage *)ret;
        }
    }
    NSArray *pathSelCandidates = @[@"pathForOriginalSightThumbImage", @"pathForSightThumbImage", @"pathForThumbImage"];
    for (NSString *selStr in pathSelCandidates) {
        SEL s = NSSelectorFromString(selStr);
        if ([mediaItem respondsToSelector:s]) {
            id ret = ((id (*)(id, SEL))objc_msgSend)(mediaItem, s);
            if ([ret isKindOfClass:[NSString class]] && [(NSString *)ret length] > 0) {
                UIImage *img = [UIImage imageWithContentsOfFile:(NSString *)ret];
                if (img) return img;
            }
        }
    }
    return nil;
}

- (Class)dd_findSightEditVCClass {
    NSArray *candidates = @[
        @"WCNewCommitViewController",          // 新版微信朋友圈统一发布 VC（FLEX 实测）
        @"SightMomentEditViewController",      // 老版微信现拍发布
        @"WCSightMomentEditViewController",
        @"WCSnsSightUploadViewController",
        @"WCSnsSightForwardViewController",
        @"WCSnsSightPublishViewController",
        @"MMSightUploadViewController",
        @"MMSightMomentEditViewController",
    ];
    for (NSString *cn in candidates) {
        Class c = NSClassFromString(cn);
        if (c) return c;
    }
    return nil;
}

- (UIViewController *)dd_instantiateSightEditVC:(Class)editCls localPath:(NSString *)localPath thumbImage:(UIImage *)thumbImage {
    // 不同版本可能存在不同的 init 签名，按"信息越完整越优先"顺序尝试
    NSDictionary *sightInfoDict = @{
        @"moviePath": localPath ?: @"",
        @"realMoviePath": localPath ?: @"",
        @"videoPath": localPath ?: @"",
        @"sightPath": localPath ?: @"",
        @"thumbImage": thumbImage ?: [NSNull null],
        @"realThumbImage": thumbImage ?: [NSNull null],
    };
    
    UIViewController *vc = nil;
    
    // 1) initWithSightInfo:
    SEL sel1 = NSSelectorFromString(@"initWithSightInfo:");
    if ([editCls instancesRespondToSelector:sel1]) {
        @try {
            vc = ((id (*)(id, SEL, id))objc_msgSend)([editCls alloc], sel1, sightInfoDict);
        } @catch (__unused NSException *e) {}
    }
    
    // 2) initWithSightVideo:thumbImage:
    if (!vc) {
        SEL sel2 = NSSelectorFromString(@"initWithSightVideo:thumbImage:");
        if ([editCls instancesRespondToSelector:sel2]) {
            @try {
                vc = ((id (*)(id, SEL, id, id))objc_msgSend)([editCls alloc], sel2, localPath, thumbImage);
            } @catch (__unused NSException *e) {}
        }
    }
    
    // 3) initWithMoviePath:thumbImage:
    if (!vc) {
        SEL sel3 = NSSelectorFromString(@"initWithMoviePath:thumbImage:");
        if ([editCls instancesRespondToSelector:sel3]) {
            @try {
                vc = ((id (*)(id, SEL, id, id))objc_msgSend)([editCls alloc], sel3, localPath, thumbImage);
            } @catch (__unused NSException *e) {}
        }
    }
    
    // 4) initWithCommitType:（统一发布 VC，type=1 通常表示"视频"）
    if (!vc) {
        SEL sel4 = NSSelectorFromString(@"initWithCommitType:");
        if ([editCls instancesRespondToSelector:sel4]) {
            @try {
                vc = ((id (*)(id, SEL, NSInteger))objc_msgSend)([editCls alloc], sel4, (NSInteger)1);
            } @catch (__unused NSException *e) {}
        }
    }
    
    // 5) 兜底 init
    if (!vc) {
        @try {
            vc = [[editCls alloc] init];
        } @catch (__unused NSException *e) {}
    }
    return vc;
}

#pragma mark - SightDraftItem / SightDraft 构造器（严格对齐 8.0.71 微信头文件签名）

// 构造 SightDraftItem（视频项，包含路径/缩略图/mode）
- (id)dd_buildSightDraftItemWithLocalPath:(NSString *)localPath thumbImage:(UIImage *)thumbImage {
    Class itemCls = NSClassFromString(@"SightDraftItem");
    if (!itemCls || localPath.length == 0) return nil;
    
    id item = nil;
    
    // 首选类方法：draftItemWithThumbImg:andPath:inMode:  (mode=0 为默认原始视频)
    SEL clsSel = NSSelectorFromString(@"draftItemWithThumbImg:andPath:inMode:");
    if ([itemCls respondsToSelector:clsSel]) {
        @try {
            item = ((id (*)(Class, SEL, id, id, unsigned long long))objc_msgSend)(
                itemCls, clsSel,
                thumbImage ?: (id)[NSNull null],
                localPath,
                (unsigned long long)0
            );
        } @catch (__unused NSException *e) {}
    }
    
    // 兜底：手动 init + KVC 注入
    if (!item) {
        @try { item = [[itemCls alloc] init]; } @catch (__unused NSException *e) {}
        if (item) {
            // 根据头文件：videoPath / moviePath / thumbImg / thumbPath / mode
            @try { [item setValue:localPath forKey:@"videoPath"]; } @catch (__unused NSException *e) {}
            @try { [item setValue:localPath forKey:@"moviePath"]; } @catch (__unused NSException *e) {}
            @try { [item setValue:localPath forKey:@"videoDraftPath"]; } @catch (__unused NSException *e) {}
            if (thumbImage) {
                @try { [item setValue:thumbImage forKey:@"thumbImg"]; } @catch (__unused NSException *e) {}
            }
            @try { [item setValue:@(0) forKey:@"mode"]; } @catch (__unused NSException *e) {}
        }
    }
    
    return item;
}

- (id)dd_buildSightDraftWithLocalPath:(NSString *)localPath thumbImage:(UIImage *)thumbImage {
    Class draftCls = NSClassFromString(@"SightDraft");
    if (!draftCls || localPath.length == 0) return nil;
    
    NSURL *videoURL = [NSURL fileURLWithPath:localPath];
    id draft = nil;
    
    // 首选类方法：draftWithVideoURL:thumbImage:（头文件中选过的标准入口）
    if (thumbImage) {
        SEL sel1 = NSSelectorFromString(@"draftWithVideoURL:thumbImage:");
        if ([draftCls respondsToSelector:sel1]) {
            @try {
                draft = ((id (*)(Class, SEL, id, id))objc_msgSend)(draftCls, sel1, videoURL, thumbImage);
            } @catch (__unused NSException *e) {}
        }
    }
    
    // 其次：draftWithVideoURL:
    if (!draft) {
        SEL sel2 = NSSelectorFromString(@"draftWithVideoURL:");
        if ([draftCls respondsToSelector:sel2]) {
            @try {
                draft = ((id (*)(Class, SEL, id))objc_msgSend)(draftCls, sel2, videoURL);
            } @catch (__unused NSException *e) {}
        }
    }
    
    // 兜底：手动构造 SightDraft + addItem: 加入一个 SightDraftItem
    if (!draft) {
        @try { draft = [[draftCls alloc] init]; } @catch (__unused NSException *e) {}
        if (draft) {
            id item = [self dd_buildSightDraftItemWithLocalPath:localPath thumbImage:thumbImage];
            if (item) {
                SEL addSel = NSSelectorFromString(@"addItem:");
                if ([draft respondsToSelector:addSel]) {
                    @try {
                        ((void (*)(id, SEL, id))objc_msgSend)(draft, addSel, item);
                    } @catch (__unused NSException *e) {}
                } else {
                    // 直接在 itemAry 里追加
                    @try {
                        NSMutableArray *ary = [draft valueForKey:@"itemAry"];
                        if (![ary isKindOfClass:[NSMutableArray class]]) {
                            ary = [NSMutableArray array];
                            @try { [draft setValue:ary forKey:@"itemAry"]; } @catch (__unused NSException *e) {}
                        }
                        [ary addObject:item];
                    } @catch (__unused NSException *e) {}
                }
            }
        }
    }
    
    // 补充 draftItemVideoPath（头文件中的顶层决策路径）
    if (draft) {
        @try { [draft setValue:localPath forKey:@"draftItemVideoPath"]; } @catch (__unused NSException *e) {}
    }
    
    return draft;
}

- (BOOL)dd_presentEditVC:(UIViewController *)editVC {
    UIViewController *presenter = nil;
    UINavigationController *nav = nil;
    @try { nav = [self valueForKey:@"navigationController"]; } @catch (__unused NSException *e) {}
    if (nav) {
        presenter = nav;
    } else {
        UIWindow *kw = [NSObject currentKeyWindow];
        presenter = kw.rootViewController;
        while (presenter.presentedViewController) presenter = presenter.presentedViewController;
    }
    if (!presenter) return NO;
    
    if ([presenter isKindOfClass:[UINavigationController class]]) {
        [(UINavigationController *)presenter pushViewController:editVC animated:YES];
    } else {
        UINavigationController *wrap = [[UINavigationController alloc] initWithRootViewController:editVC];
        wrap.modalPresentationStyle = UIModalPresentationFullScreen;
        [presenter presentViewController:wrap animated:YES completion:nil];
    }
    return YES;
}

- (BOOL)dd_tryForwardSightWithLocalPath:(NSString *)localPath thumbImage:(UIImage *)thumbImage {
    Class commitCls = NSClassFromString(@"WCNewCommitViewController");
    if (!commitCls) return NO;
    
    // 1) 构造 SightDraft（8.0.71 头文件确认为视频发布的标准载体）
    id sightDraft = [self dd_buildSightDraftWithLocalPath:localPath thumbImage:thumbImage];
    if (!sightDraft) return NO;
    
    // 2) 用 -initWithSightDraft: 启动 VC（8.0.71 头文件确认的唯一视频专用 init）
    SEL initSel = NSSelectorFromString(@"initWithSightDraft:");
    if (![commitCls instancesRespondToSelector:initSel]) return NO;
    
    UIViewController *editVC = nil;
    @try {
        editVC = ((id (*)(id, SEL, id))objc_msgSend)([commitCls alloc], initSel, sightDraft);
    } @catch (__unused NSException *e) {}
    if (!editVC) return NO;
    
    // 3) 如果 initWithSightDraft: 内部未主动 set，手动补上 sightDraft
    SEL setDraftSel = NSSelectorFromString(@"setSightDraft:");
    if ([editVC respondsToSelector:setDraftSel]) {
        @try { ((void (*)(id, SEL, id))objc_msgSend)(editVC, setDraftSel, sightDraft); } @catch (__unused NSException *e) {}
    }
    
    // 4) type 在头文件中为 unsigned long long，FLEX 实测发布页 type=3 表示视频模式
    @try { [editVC setValue:@((unsigned long long)3) forKey:@"type"]; } @catch (__unused NSException *e) {}
    
    // 5) 缩略图不需手动设置：sightDraft 已包含 thumbImg，VC 会从 draft 里读
    
    // 6) 打标：标记此 VC 是由转发流程启动，hook 中据此强制退出（避免发布后卡死）
    objc_setAssociatedObject(editVC, "dd_isForwardLaunched", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return [self dd_presentEditVC:editVC];
}

@end

#pragma mark - 转发响应

@implementation NSObject (ForwardHandler)

- (void)xxx_forwordTimeLine:(UIButton *)sender {
    WCDataItem *dataItem = [self valueForKey:@"m_item"];
    if (!dataItem) return;
    
    DDForwardConfig *cfg = [DDForwardConfig sharedConfig];
    if (!cfg.forwardEnabled) return;
    
    [self showLoadingHUD];
    [self downloadAllMediaForDataItem:dataItem completion:^{
        BOOL hasSight = [self dd_dataItemContainsSight:dataItem];
        
        if (hasSight) {
            // 视频朋友圈：使用本地视频文件重新走"发布朋友圈"流程，迫使微信重新上传
            // 否则微信只把原作者服务端视频URL随朋友圈一起发布，导致他人无访问权限看不到
            id sightItem = [self dd_firstSightMediaItemForDataItem:dataItem];
            NSString *localPath = [self dd_localVideoPathForMediaItem:sightItem];
            UIImage *thumbImage = [self dd_localThumbImageForMediaItem:sightItem];
            
            [self hideLoadingHUD];
            
            if (!localPath) {
                [self dd_showSimpleAlert:@"视频本地缓存未就绪：请先点击进入这条朋友圈让视频自动下载完成后再次尝试转发。"];
                return;
            }
            
            BOOL ok = [self dd_tryForwardSightWithLocalPath:localPath thumbImage:thumbImage];
            if (!ok) {
                [self dd_showSimpleAlert:@"未匹配到当前微信版本的视频发布入口类。\n请使用 FLEX 抓取实际类名后反馈给开发者补全适配。"];
            }
            return;
        }
        
        // 图文/链接朋友圈：保留原 WCForwardViewController 流程
        [self hideLoadingHUD];
        
        NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:dataItem requiringSecureCoding:NO error:nil];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:archivedData error:nil];
        unarchiver.requiresSecureCoding = NO;
        WCDataItem *copiedItem = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
        [unarchiver finishDecoding];
        
        if (cfg.removeLocationEnabled && [copiedItem respondsToSelector:@selector(setLocationInfo:)]) {
            copiedItem.locationInfo = nil;
        }
        
        Class forwardVCClass = objc_getClass("WCForwardViewController");
        if (forwardVCClass) {
            WCForwardViewController *forwardVC = [[forwardVCClass alloc] initWithDataItem:copiedItem];
            UINavigationController *nav = [self valueForKey:@"navigationController"];
            if (nav) {
                [nav pushViewController:forwardVC animated:YES];
            }
        }
    }];
}

@end

#pragma mark - Hook 添加转发按钮

%hook WCOperateFloatView

- (id)initWithParams:(WCOperateFloatViewParams *)params {
    self = %orig;
    if (self) {
        UIButton *likeBtn = self.m_likeBtn;
        if (likeBtn) {
            static UIImage *forwardIcon = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                Class itemCls = NSClassFromString(@"MMMenuItem");
                SEL initSvg = sel_registerName("initWithTitle:svgName:target:action:");
                id tempItem = ((id (*)(id, SEL, NSString *, NSString *, id, SEL))objc_msgSend)(
                    [itemCls alloc], initSvg, @"", @"icons_outlined_share", nil, NULL
                );
                forwardIcon = [tempItem iconImage];
            });
            
            UIButton *shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [shareBtn setTitle:@" 转发" forState:UIControlStateNormal];
            shareBtn.titleLabel.font = likeBtn.titleLabel.font;
            [shareBtn setImage:forwardIcon forState:UIControlStateNormal];
            [shareBtn addTarget:self action:@selector(xxx_forwordTimeLine:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:shareBtn];
            objc_setAssociatedObject(self, @selector(forwardButton), shareBtn, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        // 复制分割线（保持原有逻辑）
        Ivar lineIvar = class_getInstanceVariable([self class], "m_lineView");
        UIImageView *originalLine = lineIvar ? object_getIvar(self, lineIvar) : nil;
        if ([originalLine isKindOfClass:UIImageView.class]) {
            UIImageView *cloned = [[UIImageView alloc] initWithImage:originalLine.image];
            [self addSubview:cloned];
            objc_setAssociatedObject(self, @selector(clonedLineView), cloned, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    return self;
}

- (void)showWithItemData:(WCDataItem *)item tipPoint:(CGPoint)point {
    %orig;
}

- (void)layoutSubviews {
    %orig;
    
    if (![DDForwardConfig sharedConfig].forwardEnabled) return;
    
    UIButton *shareBtn = objc_getAssociatedObject(self, @selector(forwardButton));
    UIButton *likeBtn = self.m_likeBtn;
    UIButton *commentBtn = self.m_commentBtn;
    
    if (!shareBtn || !likeBtn || !commentBtn) return;
    if (shareBtn.superview != self) return;
    
    CGFloat likeW = [self buttonWidth:likeBtn];
    CGFloat commentW = [self buttonWidth:commentBtn];
    CGFloat spacing = commentBtn.frame.origin.x - (likeBtn.frame.origin.x + likeW);
    if (spacing <= 0) spacing = 8.0;
    
    shareBtn.frame = CGRectMake(commentBtn.frame.origin.x + commentW + spacing,
                                commentBtn.frame.origin.y,
                                commentW,
                                commentBtn.frame.size.height);
    
    UIImageView *clonedLine = objc_getAssociatedObject(self, @selector(clonedLineView));
    if (clonedLine && clonedLine.superview == self) {
        CGFloat commentRightCenter = commentBtn.frame.origin.x + commentW;
        CGFloat lineX = commentRightCenter + spacing / 2 - clonedLine.frame.size.width / 2;
        CGFloat lineY = commentBtn.frame.origin.y + (commentBtn.frame.size.height - clonedLine.frame.size.height) / 2;
        clonedLine.frame = CGRectMake(lineX, lineY,
                                      clonedLine.frame.size.width, clonedLine.frame.size.height);
    }
    
    CGFloat totalW = shareBtn.frame.origin.x + commentW + spacing;
    CGRect frame = self.frame;
    frame.size.width = totalW;
    self.frame = frame;
    
    if (self.superview) {
        self.center = CGPointMake(self.superview.bounds.size.width / 2, self.center.y);
    }
}

%end

#pragma mark - Hook 视频发布 VC：转发启动的实例发布/取消/返回时自动退出（避免卡死）

%hook WCNewCommitViewController

// 工具：检测当前 VC 是否由本 tweak 转发流程启动
%new
- (BOOL)dd_isLaunchedByForward {
    id flag = objc_getAssociatedObject(self, "dd_isForwardLaunched");
    return [flag isKindOfClass:[NSNumber class]] && [(NSNumber *)flag boolValue];
}

// 工具：强制退出 VC（兼容 push 与 modal 两种呈现方式）
%new
- (void)dd_dismissForwardLaunched {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 1) 先清理可能挂在 keyWindow/window 上的悬浮 view，这是“列表卡死”的真正元凶
        // 根据 WCNewCommitViewController 头文件，以下几个是发布完成后可能仍留在 keyWindow 上的独立 view
        NSArray *floatingKeys = @[@"deleteBarView", @"animatedFireworksView", @"tigerToastView", @"poiStarView", @"m_sightFullScreenPreviewView", @"ecsView", @"dragTipView"];
        for (NSString *k in floatingKeys) {
            @try {
                id v = [self valueForKey:k];
                if ([v isKindOfClass:[UIView class]]) {
                    [(UIView *)v removeFromSuperview];
                }
            } @catch (__unused NSException *e) {}
        }
        
        // 2) 关闭保存提示弹窗（MMTipsViewController，可能 modal present 在全局上）
        @try {
            id alertVC = [self valueForKey:@"savingAlertView"];
            if ([alertVC isKindOfClass:[UIViewController class]]) {
                [(UIViewController *)alertVC dismissViewControllerAnimated:NO completion:nil];
            }
        } @catch (__unused NSException *e) {}
        
        // 3) 停掉烟花/动画计时器（VC 头文件中 _fireTimer）
        @try {
            id timer = [self valueForKey:@"_fireTimer"];
            if ([timer respondsToSelector:@selector(invalidate)]) {
                [(NSTimer *)timer invalidate];
            }
        } @catch (__unused NSException *e) {}
        
        // 4) 兑底清掉 keyWindow 上任何“集中全屏遮罩”（alpha 在透明区间、frame 覆盖整个窗口、且不是 rootViewController.view）
        UIWindow *kw = [NSObject currentKeyWindow];
        if (kw) {
            UIView *rootView = kw.rootViewController.view;
            for (UIView *sv in [kw.subviews copy]) {
                if (sv == rootView) continue;
                CGRect f = sv.frame;
                BOOL fullscreen = (CGRectGetWidth(f) >= CGRectGetWidth(kw.bounds) - 1
                                   && CGRectGetHeight(f) >= CGRectGetHeight(kw.bounds) - 1);
                BOOL semi = (sv.alpha > 0.0 && sv.alpha < 1.0);
                if (fullscreen && semi) {
                    [sv removeFromSuperview];
                }
            }
        }
        
        // 5) 退出 VC 自身：使用 popToViewController 把 self 及其上可能 push 进去的子页（ImageSelectorController 等）一起退出
        UINavigationController *nav = self.navigationController;
        if (nav) {
            NSArray *vcs = nav.viewControllers;
            NSInteger idx = [vcs indexOfObject:(UIViewController *)self];
            if (idx != NSNotFound && idx > 0) {
                [nav popToViewController:vcs[idx - 1] animated:YES];
            } else if (idx == 0) {
                if (nav.presentingViewController) {
                    [nav dismissViewControllerAnimated:YES completion:nil];
                } else {
                    [nav popViewControllerAnimated:YES];
                }
            } else {
                // self 不在 nav 栈里（已被 pop）——仅需保证上一层 nav 上的子页被 pop
                if (vcs.count > 1) {
                    [nav popToRootViewControllerAnimated:YES];
                }
            }
        } else if (self.presentingViewController) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    });
}

- (void)didFinishCommiting {
    if ([self dd_isLaunchedByForward]) {
        // 转发场景：baseResultDelegate / imageSelectorController 都为 nil，微信原生
        // 路径 dismiss 会错乲到上游列表（表现为 window 调上残留遮罩导致点击无响应），
        // 这里直接走清理+退出路径，不调 %orig。
        [self dd_dismissForwardLaunched];
        return;
    }
    %orig;
}

- (void)didCancelCommiting {
    if ([self dd_isLaunchedByForward]) {
        [self dd_dismissForwardLaunched];
        return;
    }
    %orig;
}

- (void)OnReturn {
    if ([self dd_isLaunchedByForward]) {
        // 转发流程不走原 OnReturn 的状态机/弹窗，直接强制退出
        [self dd_dismissForwardLaunched];
        return;
    }
    %orig;
}

- (void)doExit {
    BOOL isForward = [self dd_isLaunchedByForward];
    %orig;
    if (isForward) {
        [self dd_dismissForwardLaunched];
    }
}

// 主路径：用户点击导航栏右上“发表”按钮 → OnDone → 发布任务提交后发生。
// 转发启动的 VC 因缺少 baseResultDelegate/imageSelectorController 上游持有者，
// 原生 didFinishCommiting 隔该代理 dismiss 不会生效，这里不依赖它，改为在
// %orig 运行后延迟主动强制 dismiss，与后台 SnsService 上传完全解耦。
- (void)OnDone {
    BOOL isForward = [self dd_isLaunchedByForward];
    %orig;
    if (isForward) {
        __weak __typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) [strongSelf dd_dismissForwardLaunched];
        });
    }
}

// 兑底：如果某些版本 "发表" 按钮不走 OnDone 而是别的 selector，轮询 hasClickDone
// hasClickDone 是 WCNewCommitViewController 内部表示“已点发表”的状态位，发表被点击后被置为 YES
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if ([self dd_isLaunchedByForward]) {
        [self dd_startWatchHasClickDone];
    }
}

%new
- (void)dd_startWatchHasClickDone {
    static const char *kWatcherKey = "dd_hasClickDoneTimer";
    if (objc_getAssociatedObject(self, kWatcherKey)) return; // 已启动过
    __weak __typeof(self) weakSelf = self;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *t) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { [t invalidate]; return; }
        BOOL clicked = NO;
        @try {
            id v = [strongSelf valueForKey:@"hasClickDone"];
            clicked = [v respondsToSelector:@selector(boolValue)] ? [v boolValue] : NO;
        } @catch (__unused NSException *e) {}
        if (clicked) {
            [t invalidate];
            objc_setAssociatedObject(strongSelf, kWatcherKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            __weak __typeof(strongSelf) weakInner = strongSelf;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                __strong __typeof(weakInner) inner = weakInner;
                if (inner) [inner dd_dismissForwardLaunched];
            });
        }
    }];
    objc_setAssociatedObject(self, kWatcherKey, timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end

#pragma mark - 插件注册

%ctor {
    @autoreleasepool {
        Class mgr = objc_getClass("WCPluginsMgr");
        if (mgr) {
            [[mgr sharedInstance] registerControllerWithTitle:@"DD朋友圈转发"
                                                      version:@"1.0.1"
                                                   controller:@"DDForwardSettingsViewController"];
        }
    }
}