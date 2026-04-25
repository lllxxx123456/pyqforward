#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <stdarg.h>
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
- (void)postNewItemForSight;
- (void)doExit;
- (void)viewWillDisappear:(BOOL)animated;
- (void)viewDidDisappear:(BOOL)animated;
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

@class DDForwardDebugWindow;
@class DDForwardDebugPanel;
static NSMutableString *gDDForwardDebugBuffer = nil;
static DDForwardDebugWindow *gDDForwardDebugWindow = nil;
static DDForwardDebugPanel *gDDForwardDebugPanel = nil;
static BOOL gDDForwardDebugUserClosed = NO;
static void DDDebugStartSession(NSString *reason);
static void DDDebugLog(NSString *format, ...);
static void DDDebugCaptureState(NSString *reason);
static void DDDebugScheduleCaptures(NSString *reason);
static void DDDebugShow(void);
static void DDDebugHide(void);
static NSString *DDObjectSummary(id obj);
static NSString *DDKVCValueSummary(id obj, NSString *key);

static NSTimeInterval gDDForwardSightResidueCleanupDeadline = 0;

static void DDEnableForwardSightResidueCleanupWindow(NSTimeInterval seconds) {
    NSTimeInterval deadline = [[NSDate date] timeIntervalSince1970] + seconds;
    if (deadline > gDDForwardSightResidueCleanupDeadline) {
        gDDForwardSightResidueCleanupDeadline = deadline;
    }
}

static BOOL DDShouldCleanForwardSightResidueNow(void) {
    return gDDForwardSightResidueCleanupDeadline > 0
        && [[NSDate date] timeIntervalSince1970] <= gDDForwardSightResidueCleanupDeadline;
}

static BOOL DDViewTreeContainsClassName(UIView *view, NSSet *classNames) {
    if (!view) return NO;
    if ([classNames containsObject:NSStringFromClass([view class])]) return YES;
    for (UIView *subview in [view.subviews copy]) {
        if (DDViewTreeContainsClassName(subview, classNames)) return YES;
    }
    return NO;
}

static BOOL DDViewHasAncestorClassName(UIView *view, NSSet *classNames) {
    UIView *ancestor = view.superview;
    while (ancestor) {
        if ([classNames containsObject:NSStringFromClass([ancestor class])]) return YES;
        ancestor = ancestor.superview;
    }
    return NO;
}

static BOOL DDIsForwardSightResidueContainer(UIView *view, UIWindow *window) {
    if (!view || !window || view == window || view == window.rootViewController.view) return NO;
    if (![NSStringFromClass([view class]) isEqualToString:@"UIView"]) return NO;

    UIResponder *responder = view.nextResponder;
    NSString *responderClassName = responder ? NSStringFromClass([responder class]) : nil;
    if ([responderClassName hasSuffix:@"ViewController"]) return NO;

    CGRect rect = [view convertRect:view.bounds toView:window];
    BOOL fullscreenSize = CGRectGetWidth(rect) >= CGRectGetWidth(window.bounds) - 2.0
                       && CGRectGetHeight(rect) >= CGRectGetHeight(window.bounds) - 2.0;
    if (!fullscreenSize) return NO;

    NSSet *timelineAncestorNames = [NSSet setWithObjects:@"UITableViewCellContentView", @"MMTableViewCell", @"WCListHeaderView", @"WCTimeLineTableView", @"WCTimelineTableView", nil];
    if (!DDViewHasAncestorClassName(view, timelineAncestorNames)) return NO;

    NSSet *previewNames = [NSSet setWithObjects:@"WCPostSightImageView", @"SightIconView", nil];
    if (!DDViewTreeContainsClassName(view, previewNames)) return NO;

    NSSet *assetCellNames = [NSSet setWithObjects:@"UICollectionViewCell", nil];
    if (!DDViewTreeContainsClassName(view, assetCellNames)) return NO;

    NSSet *normalTimelineNames = [NSSet setWithObjects:@"WCTimeLineCellView", @"WCTimeLineTableView", @"WCTimelineTableView", @"MMTableViewCell", nil];
    if (DDViewTreeContainsClassName(view, normalTimelineNames)) return NO;

    return YES;
}

static void DDCollectForwardSightResidueContainers(UIView *view, UIWindow *window, NSMutableArray *result) {
    if (!view) return;
    if (DDIsForwardSightResidueContainer(view, window)) {
        [result addObject:view];
        return;
    }
    for (UIView *subview in [view.subviews copy]) {
        DDCollectForwardSightResidueContainers(subview, window, result);
    }
}

static void DDRemoveForwardSightResiduePreviewViews(void) {
    NSMutableArray *targets = [NSMutableArray array];
    NSMutableArray *windows = [NSMutableArray array];
    UIWindow *keyWindow = [NSObject currentKeyWindow];
    if (keyWindow) [windows addObject:keyWindow];
    for (UIScene *scene in [[UIApplication sharedApplication].connectedScenes copy]) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *window in [((UIWindowScene *)scene).windows copy]) {
            if (!window || window.hidden || window.alpha <= 0.0 || [windows containsObject:window]) continue;
            [windows addObject:window];
        }
    }
    for (UIWindow *window in windows) {
        for (UIView *subview in [window.subviews copy]) {
            DDCollectForwardSightResidueContainers(subview, window, targets);
        }
    }
    for (UIView *target in targets) {
        DDDebugLog(@"remove residue target: %@", DDObjectSummary(target));
        [target removeFromSuperview];
    }
}

static void DDScheduleForwardSightResiduePreviewCleanup(void) {
    DDEnableForwardSightResidueCleanupWindow(20.0);
    DDRemoveForwardSightResiduePreviewViews();
    NSArray *delays = @[@0.15, @0.45, @0.9, @1.6, @2.6, @4.0];
    for (NSNumber *delay in delays) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([delay doubleValue] * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            DDRemoveForwardSightResiduePreviewViews();
        });
    }
}

@interface DDForwardDebugWindow : UIWindow
@end

@interface DDForwardDebugPanel : UIView
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIButton *minButton;
@property (nonatomic, assign) BOOL minimized;
- (void)refreshText;
@end

@implementation DDForwardDebugWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (!hit || hit == self) return nil;
    if (gDDForwardDebugPanel && !gDDForwardDebugPanel.hidden) {
        CGPoint p = [gDDForwardDebugPanel convertPoint:point fromView:self];
        if ([gDDForwardDebugPanel pointInside:p withEvent:event]) return hit;
    }
    return nil;
}

@end

@implementation DDForwardDebugPanel

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.82];
        self.layer.cornerRadius = 10.0;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.35].CGColor;
        self.clipsToBounds = YES;

        NSArray *titles = @[@"最小", @"抓取", @"复制", @"清空", @"关闭"];
        NSArray *actions = @[
            NSStringFromSelector(@selector(onMinimize)),
            NSStringFromSelector(@selector(onCapture)),
            NSStringFromSelector(@selector(onCopy)),
            NSStringFromSelector(@selector(onClear)),
            NSStringFromSelector(@selector(onClose))
        ];
        for (NSUInteger i = 0; i < titles.count; i++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            [btn setTitle:titles[i] forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
            btn.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
            btn.layer.cornerRadius = 5.0;
            [btn addTarget:self action:NSSelectorFromString(actions[i]) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn];
            if (i == 0) self.minButton = btn;
        }

        self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
        self.textView.editable = NO;
        self.textView.selectable = YES;
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.textColor = [UIColor colorWithWhite:0.96 alpha:1.0];
        self.textView.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
        self.textView.alwaysBounceVertical = YES;
        [self addSubview:self.textView];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat pad = 8.0;
    CGFloat buttonH = 28.0;
    CGFloat gap = 5.0;
    CGFloat buttonW = (self.bounds.size.width - pad * 2 - gap * 4) / 5.0;
    NSUInteger index = 0;
    for (UIView *subview in self.subviews) {
        if (![subview isKindOfClass:[UIButton class]]) continue;
        subview.frame = CGRectMake(pad + index * (buttonW + gap), pad, buttonW, buttonH);
        index++;
    }
    self.textView.frame = CGRectMake(pad, pad + buttonH + pad, self.bounds.size.width - pad * 2, self.bounds.size.height - buttonH - pad * 3);
}

- (void)refreshText {
    self.textView.text = gDDForwardDebugBuffer ? gDDForwardDebugBuffer : @"";
    if (self.textView.text.length > 0) {
        [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length - 1, 1)];
    }
}

- (void)onMinimize {
    self.minimized = !self.minimized;
    CGRect f = self.frame;
    if (self.minimized) {
        f.size.height = 44.0;
        self.textView.hidden = YES;
        [self.minButton setTitle:@"展开" forState:UIControlStateNormal];
    } else {
        f.size.height = 300.0;
        self.textView.hidden = NO;
        [self.minButton setTitle:@"最小" forState:UIControlStateNormal];
    }
    self.frame = f;
    [self setNeedsLayout];
}

- (void)onCapture {
    DDDebugCaptureState(@"manual-capture");
}

- (void)onCopy {
    [UIPasteboard generalPasteboard].string = gDDForwardDebugBuffer ? gDDForwardDebugBuffer : @"";
}

- (void)onClear {
    [gDDForwardDebugBuffer setString:@""];
    [self refreshText];
}

- (void)onClose {
    gDDForwardDebugUserClosed = YES;
    DDDebugHide();
}

- (void)onPan:(UIPanGestureRecognizer *)pan {
    CGPoint delta = [pan translationInView:self.superview];
    self.center = CGPointMake(self.center.x + delta.x, self.center.y + delta.y);
    [pan setTranslation:CGPointZero inView:self.superview];
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        CGRect bounds = self.superview.bounds;
        CGRect f = self.frame;
        f.origin.x = MAX(6.0, MIN(f.origin.x, bounds.size.width - f.size.width - 6.0));
        f.origin.y = MAX(40.0, MIN(f.origin.y, bounds.size.height - f.size.height - 20.0));
        self.frame = f;
    }
}

@end

static NSString *DDFrameString(UIView *view) {
    if (!view) return @"nil";
    return NSStringFromCGRect(view.frame);
}

static UIViewController *DDNearestViewControllerForView(UIView *view) {
    UIResponder *responder = view.nextResponder;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) return (UIViewController *)responder;
        responder = responder.nextResponder;
    }
    return nil;
}

static NSString *DDObjectSummary(id obj) {
    if (!obj) return @"nil";
    NSString *className = NSStringFromClass([obj class]);
    NSString *ptr = [NSString stringWithFormat:@"%p", obj];
    if ([obj isKindOfClass:[UIView class]]) {
        UIView *v = (UIView *)obj;
        UIViewController *vc = DDNearestViewControllerForView(v);
        return [NSString stringWithFormat:@"%@<%@> frame=%@ hidden=%d alpha=%.2f user=%d super=%@ next=%@ nearVC=%@",
                className, ptr, NSStringFromCGRect(v.frame), v.hidden, v.alpha, v.userInteractionEnabled,
                v.superview ? NSStringFromClass([v.superview class]) : @"nil",
                v.nextResponder ? NSStringFromClass([v.nextResponder class]) : @"nil",
                vc ? NSStringFromClass([vc class]) : @"nil"];
    }
    if ([obj isKindOfClass:[UIViewController class]]) {
        UIViewController *vc = (UIViewController *)obj;
        return [NSString stringWithFormat:@"%@<%@> view=%@ nav=%@ presenting=%@ presented=%@",
                className, ptr, DDFrameString(vc.view),
                vc.navigationController ? NSStringFromClass([vc.navigationController class]) : @"nil",
                vc.presentingViewController ? NSStringFromClass([vc.presentingViewController class]) : @"nil",
                vc.presentedViewController ? NSStringFromClass([vc.presentedViewController class]) : @"nil"];
    }
    return [NSString stringWithFormat:@"%@<%@>", className, ptr];
}

static NSString *DDKVCValueSummary(id obj, NSString *key) {
    if (!obj || key.length == 0) return @"nil";
    @try {
        id value = [obj valueForKey:key];
        if (!value) return @"nil";
        if ([value isKindOfClass:[NSString class]]) return (NSString *)value;
        if ([value isKindOfClass:[NSNumber class]]) return [(NSNumber *)value stringValue];
        if ([value isKindOfClass:[NSArray class]]) return [NSString stringWithFormat:@"%@ count=%lu", NSStringFromClass([value class]), (unsigned long)[(NSArray *)value count]];
        return DDObjectSummary(value);
    } @catch (__unused NSException *e) {
        return @"<KVC failed>";
    }
}

static void DDAppendViewTree(NSMutableString *out, UIView *view, NSUInteger depth, NSUInteger maxDepth) {
    if (!view || depth > maxDepth) return;
    NSMutableString *indent = [NSMutableString string];
    for (NSUInteger i = 0; i < depth; i++) [indent appendString:@"  "];
    UIViewController *vc = DDNearestViewControllerForView(view);
    [out appendFormat:@"%@- %@ frame=%@ hidden=%d alpha=%.2f user=%d next=%@ nearVC=%@\n",
     indent,
     NSStringFromClass([view class]),
     NSStringFromCGRect(view.frame),
     view.hidden,
     view.alpha,
     view.userInteractionEnabled,
     view.nextResponder ? NSStringFromClass([view.nextResponder class]) : @"nil",
     vc ? NSStringFromClass([vc class]) : @"nil"];
    for (UIView *subview in [view.subviews copy]) {
        DDAppendViewTree(out, subview, depth + 1, maxDepth);
    }
}

static BOOL DDViewLooksRelevantForForwardDebug(UIView *view) {
    if (!view) return NO;
    NSSet *names = [NSSet setWithObjects:@"WCPostSightImageView", @"SightIconView", @"WCAssetStateView", @"UICollectionViewCell", @"WCListHeaderView", @"WCTimelineTableView", @"WCTimeLineTableView", @"WCNewCommitViewController", nil];
    if (DDViewTreeContainsClassName(view, names)) return YES;
    if ([names containsObject:NSStringFromClass([view class])]) return YES;
    return NO;
}

static void DDCollectRelevantViews(UIView *view, NSMutableArray *result) {
    if (!view) return;
    if (DDViewLooksRelevantForForwardDebug(view)) {
        [result addObject:view];
    }
    for (UIView *subview in [view.subviews copy]) {
        DDCollectRelevantViews(subview, result);
    }
}

static void DDDebugShow(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gDDForwardDebugUserClosed) return;
        if (!gDDForwardDebugBuffer) gDDForwardDebugBuffer = [NSMutableString string];
        if (!gDDForwardDebugWindow) {
            UIWindow *base = [NSObject currentKeyWindow];
            CGRect bounds = base ? base.bounds : [UIScreen mainScreen].bounds;
            gDDForwardDebugWindow = [[DDForwardDebugWindow alloc] initWithFrame:bounds];
            if (base && base.windowScene) {
                gDDForwardDebugWindow.windowScene = base.windowScene;
            }
            gDDForwardDebugWindow.windowLevel = UIWindowLevelAlert + 300;
            gDDForwardDebugWindow.backgroundColor = [UIColor clearColor];
            gDDForwardDebugWindow.hidden = NO;
            gDDForwardDebugPanel = [[DDForwardDebugPanel alloc] initWithFrame:CGRectMake(10, 90, bounds.size.width - 20, 300)];
            [gDDForwardDebugWindow addSubview:gDDForwardDebugPanel];
        }
        gDDForwardDebugWindow.hidden = NO;
        [gDDForwardDebugPanel refreshText];
    });
}

static void DDDebugHide(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        gDDForwardDebugWindow.hidden = YES;
    });
}

static void DDDebugLog(NSString *format, ...) {
    if (!format) return;
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!gDDForwardDebugBuffer) gDDForwardDebugBuffer = [NSMutableString string];
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"HH:mm:ss.SSS";
        [gDDForwardDebugBuffer appendFormat:@"[%@] %@\n", [fmt stringFromDate:[NSDate date]], message];
        if (gDDForwardDebugBuffer.length > 60000) {
            [gDDForwardDebugBuffer deleteCharactersInRange:NSMakeRange(0, gDDForwardDebugBuffer.length - 60000)];
        }
        DDDebugShow();
        [gDDForwardDebugPanel refreshText];
    });
}

static void DDDebugStartSession(NSString *reason) {
    gDDForwardDebugUserClosed = NO;
    if (!gDDForwardDebugBuffer) gDDForwardDebugBuffer = [NSMutableString string];
    [gDDForwardDebugBuffer setString:@""];
    DDDebugShow();
    DDDebugLog(@"==== DDForward debug start: %@ ====", reason ? reason : @"unknown");
    DDDebugLog(@"deviceScale=%.2f screen=%@ keyWindow=%@", [UIScreen mainScreen].scale, NSStringFromCGRect([UIScreen mainScreen].bounds), DDObjectSummary([NSObject currentKeyWindow]));
}

static void DDDebugCaptureState(NSString *reason) {
    dispatch_async(dispatch_get_main_queue(), ^{
        DDDebugLog(@"---- capture: %@ ----", reason ? reason : @"unknown");
        NSMutableString *snapshot = [NSMutableString string];
        UIWindow *keyWindow = [NSObject currentKeyWindow];
        [snapshot appendFormat:@"keyWindow: %@\n", DDObjectSummary(keyWindow)];
        NSMutableArray *windows = [NSMutableArray array];
        if (keyWindow) [windows addObject:keyWindow];
        for (UIScene *scene in [[UIApplication sharedApplication].connectedScenes copy]) {
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *window in [((UIWindowScene *)scene).windows copy]) {
                if (window == gDDForwardDebugWindow) continue;
                if (!window || [windows containsObject:window]) continue;
                [windows addObject:window];
            }
        }
        NSUInteger wi = 0;
        for (UIWindow *window in windows) {
            [snapshot appendFormat:@"window[%lu]: %@\n", (unsigned long)wi, DDObjectSummary(window)];
            NSMutableArray *targets = [NSMutableArray array];
            for (UIView *subview in [window.subviews copy]) {
                DDCollectRelevantViews(subview, targets);
            }
            NSUInteger ti = 0;
            for (UIView *target in targets) {
                [snapshot appendFormat:@"target[%lu.%lu]: %@ residue=%d\n", (unsigned long)wi, (unsigned long)ti, DDObjectSummary(target), DDIsForwardSightResidueContainer(target, window)];
                DDAppendViewTree(snapshot, target, 1, 4);
                ti++;
                if (ti >= 12) break;
            }
            wi++;
        }
        DDDebugLog(@"%@", snapshot);
    });
}

static void DDDebugScheduleCaptures(NSString *reason) {
    DDDebugCaptureState(reason);
    NSArray *delays = @[@0.25, @0.8, @1.5, @2.5, @4.0, @7.0, @10.0];
    for (NSNumber *delay in delays) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([delay doubleValue] * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            DDDebugCaptureState([NSString stringWithFormat:@"%@ +%@s", reason ? reason : @"capture", delay]);
        });
    }
}

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
        @"moviePath": localPath ? localPath : @"",
        @"realMoviePath": localPath ? localPath : @"",
        @"videoPath": localPath ? localPath : @"",
        @"sightPath": localPath ? localPath : @"",
        @"thumbImage": thumbImage ? thumbImage : [NSNull null],
        @"realThumbImage": thumbImage ? thumbImage : [NSNull null],
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
    DDDebugLog(@"build SightDraftItem class=%@ localPath=%@ thumb=%@", itemCls ? NSStringFromClass(itemCls) : @"nil", localPath ? localPath : @"nil", DDObjectSummary(thumbImage));
    if (!itemCls || localPath.length == 0) return nil;
    
    id item = nil;
    
    // 首选类方法：draftItemWithThumbImg:andPath:inMode:  (mode=0 为默认原始视频)
    SEL clsSel = NSSelectorFromString(@"draftItemWithThumbImg:andPath:inMode:");
    if ([itemCls respondsToSelector:clsSel]) {
        @try {
            item = ((id (*)(Class, SEL, id, id, unsigned long long))objc_msgSend)(
                itemCls, clsSel,
                thumbImage ? thumbImage : (id)[NSNull null],
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
    
    DDDebugLog(@"SightDraftItem result=%@ videoPath=%@ moviePath=%@ videoDraftPath=%@ thumbImg=%@ mode=%@",
               DDObjectSummary(item),
               DDKVCValueSummary(item, @"videoPath"),
               DDKVCValueSummary(item, @"moviePath"),
               DDKVCValueSummary(item, @"videoDraftPath"),
               DDKVCValueSummary(item, @"thumbImg"),
               DDKVCValueSummary(item, @"mode"));
    return item;
}

- (id)dd_buildSightDraftWithLocalPath:(NSString *)localPath thumbImage:(UIImage *)thumbImage {
    Class draftCls = NSClassFromString(@"SightDraft");
    DDDebugLog(@"build SightDraft class=%@ localPath=%@ thumb=%@", draftCls ? NSStringFromClass(draftCls) : @"nil", localPath ? localPath : @"nil", DDObjectSummary(thumbImage));
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
    
    DDDebugLog(@"SightDraft result=%@ itemAry=%@ sightDraft=%@ draftItemVideoPath=%@ type=%@",
               DDObjectSummary(draft),
               DDKVCValueSummary(draft, @"itemAry"),
               DDKVCValueSummary(draft, @"sightDraft"),
               DDKVCValueSummary(draft, @"draftItemVideoPath"),
               DDKVCValueSummary(draft, @"type"));
    return draft;
}

- (BOOL)dd_presentEditVC:(UIViewController *)editVC {
    UIViewController *presenter = nil;
    UINavigationController *sourceNav = nil;
    @try { sourceNav = [self valueForKey:@"navigationController"]; } @catch (__unused NSException *e) {}
    DDDebugLog(@"presentEditVC begin editVC=%@ sourceNav=%@", DDObjectSummary(editVC), DDObjectSummary(sourceNav));
    if (sourceNav) {
        presenter = sourceNav;
        while (presenter.presentedViewController) presenter = presenter.presentedViewController;
    } else {
        UIWindow *kw = [NSObject currentKeyWindow];
        presenter = kw.rootViewController;
        while (presenter.presentedViewController) presenter = presenter.presentedViewController;
    }
    if (!presenter) return NO;
    
    Class navCls = NSClassFromString(@"MMUINavigationController");
    if (!navCls) navCls = [UINavigationController class];
    UINavigationController *wrap = nil;
    @try {
        wrap = [[navCls alloc] initWithRootViewController:editVC];
    } @catch (__unused NSException *e) {}
    if (!wrap) {
        wrap = [[UINavigationController alloc] initWithRootViewController:editVC];
    }
    wrap.modalPresentationStyle = UIModalPresentationFullScreen;
    objc_setAssociatedObject(wrap, "dd_isForwardModalNavigationController", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    DDDebugLog(@"presentEditVC presenter=%@ wrap=%@ wrapRoot=%@", DDObjectSummary(presenter), DDObjectSummary(wrap), DDObjectSummary(editVC));
    [presenter presentViewController:wrap animated:YES completion:^{
        DDDebugLog(@"presentEditVC completion editVC=%@ nav=%@", DDObjectSummary(editVC), DDObjectSummary(editVC.navigationController));
        DDDebugScheduleCaptures(@"after-present-editVC");
    }];
    return YES;
}

- (BOOL)dd_tryForwardSightWithLocalPath:(NSString *)localPath thumbImage:(UIImage *)thumbImage {
    Class commitCls = NSClassFromString(@"WCNewCommitViewController");
    DDDebugLog(@"tryForwardSight commitCls=%@ localPath=%@ thumb=%@", commitCls ? NSStringFromClass(commitCls) : @"nil", localPath ? localPath : @"nil", DDObjectSummary(thumbImage));
    if (!commitCls) return NO;
    
    // 1) 构造 SightDraft（8.0.71 头文件确认为视频发布的标准载体）
    id sightDraft = [self dd_buildSightDraftWithLocalPath:localPath thumbImage:thumbImage];
    if (!sightDraft) return NO;
    
    // 2) 用 -initWithSightDraft: 启动 VC（8.0.71 头文件确认的唯一视频专用 init）
    SEL initSel = NSSelectorFromString(@"initWithSightDraft:");
    DDDebugLog(@"tryForwardSight initWithSightDraft exists=%d", [commitCls instancesRespondToSelector:initSel]);
    if (![commitCls instancesRespondToSelector:initSel]) return NO;
    
    UIViewController *editVC = nil;
    @try {
        editVC = ((id (*)(id, SEL, id))objc_msgSend)([commitCls alloc], initSel, sightDraft);
    } @catch (__unused NSException *e) {}
    if (!editVC) return NO;
    DDDebugLog(@"tryForwardSight editVC=%@ sightDraft=%@ vc.sightDraft=%@ vc.type=%@",
               DDObjectSummary(editVC),
               DDObjectSummary(sightDraft),
               DDKVCValueSummary(editVC, @"sightDraft"),
               DDKVCValueSummary(editVC, @"type"));
    
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
    DDDebugLog(@"tryForwardSight marked editVC forward flag; type=%@ hasClickDone=%@", DDKVCValueSummary(editVC, @"type"), DDKVCValueSummary(editVC, @"hasClickDone"));
    
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

    DDDebugStartSession(@"tap-forward-button");
    DDDebugLog(@"forward entry self=%@ sender=%@ dataItem=%@ contentObj=%@ mediaList=%@ nav=%@",
               DDObjectSummary(self),
               DDObjectSummary(sender),
               DDObjectSummary(dataItem),
               DDObjectSummary([dataItem contentObj]),
               DDKVCValueSummary([dataItem contentObj], @"mediaList"),
               DDKVCValueSummary(self, @"navigationController"));
    DDDebugScheduleCaptures(@"forward-entry");
    
    [self showLoadingHUD];
    [self downloadAllMediaForDataItem:dataItem completion:^{
        BOOL hasSight = [self dd_dataItemContainsSight:dataItem];
        DDDebugLog(@"download completion hasSight=%d dataItem=%@ contentObj=%@", hasSight, DDObjectSummary(dataItem), DDObjectSummary([dataItem contentObj]));
        
        if (hasSight) {
            // 视频朋友圈：使用本地视频文件重新走"发布朋友圈"流程，迫使微信重新上传
            // 否则微信只把原作者服务端视频URL随朋友圈一起发布，导致他人无访问权限看不到
            id sightItem = [self dd_firstSightMediaItemForDataItem:dataItem];
            NSString *localPath = [self dd_localVideoPathForMediaItem:sightItem];
            UIImage *thumbImage = [self dd_localThumbImageForMediaItem:sightItem];
            DDDebugLog(@"sight media item=%@ localPath=%@ fileExists=%d thumb=%@ hasData=%@ hasSight=%@",
                       DDObjectSummary(sightItem),
                       localPath ? localPath : @"nil",
                       localPath ? [[NSFileManager defaultManager] fileExistsAtPath:localPath] : NO,
                       DDObjectSummary(thumbImage),
                       DDKVCValueSummary(sightItem, @"hasData"),
                       DDKVCValueSummary(sightItem, @"hasSight"));
            
            [self hideLoadingHUD];
            
            if (!localPath) {
                DDDebugLog(@"abort: localPath nil");
                [self dd_showSimpleAlert:@"视频本地缓存未就绪：请先点击进入这条朋友圈让视频自动下载完成后再次尝试转发。"];
                return;
            }
            
            BOOL ok = [self dd_tryForwardSightWithLocalPath:localPath thumbImage:thumbImage];
            DDDebugLog(@"tryForwardSight returned=%d", ok);
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

#pragma mark - Hook UIView：发布后精准清理朋友圈表头残留的视频预览覆盖层

%hook UIView

- (void)didMoveToSuperview {
    %orig;
    if (!DDShouldCleanForwardSightResidueNow()) return;
    if (![NSStringFromClass([self class]) isEqualToString:@"UIView"]) return;

    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !DDShouldCleanForwardSightResidueNow()) return;
        UIWindow *window = strongSelf.window;
        if (!window) window = [NSObject currentKeyWindow];
        if (DDIsForwardSightResidueContainer(strongSelf, window)) {
            DDDebugLog(@"UIView didMoveToSuperview residue hit: %@", DDObjectSummary(strongSelf));
            DDDebugCaptureState(@"residue-hit-before-remove");
            [strongSelf removeFromSuperview];
            DDDebugCaptureState(@"residue-hit-after-remove");
        }
    });
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
        UINavigationController *nav = self.navigationController;
        UIView *commitView = self.view;
        UIView *navView = nav.view;
        BOOL isForwardModalNav = nav ? [objc_getAssociatedObject(nav, "dd_isForwardModalNavigationController") boolValue] : NO;
        DDDebugLog(@"dismissForwardLaunched begin self=%@ nav=%@ navView=%@ commitView=%@ modalNav=%d presenting=%@",
                   DDObjectSummary(self),
                   DDObjectSummary(nav),
                   DDObjectSummary(navView),
                   DDObjectSummary(commitView),
                   isForwardModalNav,
                   DDObjectSummary(nav.presentingViewController));
        DDDebugScheduleCaptures(@"dismiss-begin");
        void (^cleanupCommittedView)(void) = ^{
            DDDebugLog(@"dismiss cleanupCommittedView commitView=%@ navView=%@", DDObjectSummary(commitView), DDObjectSummary(navView));
            [commitView removeFromSuperview];
            if (isForwardModalNav) {
                [navView removeFromSuperview];
            }
            DDScheduleForwardSightResiduePreviewCleanup();
            DDDebugScheduleCaptures(@"dismiss-cleanup");
        };

        DDScheduleForwardSightResiduePreviewCleanup();

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
        if (nav) {
            NSArray *vcs = nav.viewControllers;
            NSUInteger idx = [vcs indexOfObject:(UIViewController *)self];
            DDDebugLog(@"dismiss nav stack count=%lu idx=%lu vcs=%@", (unsigned long)vcs.count, (unsigned long)idx, vcs);
            void (^finishCleanup)(void) = ^{
                cleanupCommittedView();
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), cleanupCommittedView);
            };
            if (nav.presentingViewController && (isForwardModalNav || idx == 0)) {
                [nav dismissViewControllerAnimated:NO completion:finishCleanup];
            } else if (idx != NSNotFound && idx > 0) {
                UIViewController *target = [vcs objectAtIndex:idx - 1];
                [nav popToViewController:target animated:NO];
                finishCleanup();
            } else if (idx == 0) {
                if (nav.presentingViewController) {
                    [nav dismissViewControllerAnimated:NO completion:finishCleanup];
                } else {
                    [nav popViewControllerAnimated:NO];
                    finishCleanup();
                }
            } else {
                // self 不在 nav 栈里（已被 pop）——仅需保证上一层 nav 上的子页被 pop
                cleanupCommittedView();
            }
        } else if (self.presentingViewController) {
            [self.presentingViewController dismissViewControllerAnimated:NO completion:cleanupCommittedView];
        } else {
            cleanupCommittedView();
        }
    });
}

- (void)didFinishCommiting {
    if ([self dd_isLaunchedByForward]) {
        DDDebugLog(@"didFinishCommiting forward self=%@ hasClickDone=%@ type=%@ sightDraft=%@",
                   DDObjectSummary(self),
                   DDKVCValueSummary(self, @"hasClickDone"),
                   DDKVCValueSummary(self, @"type"),
                   DDKVCValueSummary(self, @"sightDraft"));
        DDDebugScheduleCaptures(@"didFinishCommiting");
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
        DDDebugLog(@"didCancelCommiting forward self=%@", DDObjectSummary(self));
        DDDebugScheduleCaptures(@"didCancelCommiting");
        [self dd_dismissForwardLaunched];
        return;
    }
    %orig;
}

- (void)OnReturn {
    if ([self dd_isLaunchedByForward]) {
        DDDebugLog(@"OnReturn forward self=%@", DDObjectSummary(self));
        DDDebugScheduleCaptures(@"OnReturn");
        // 转发流程不走原 OnReturn 的状态机/弹窗，直接强制退出
        [self dd_dismissForwardLaunched];
        return;
    }
    %orig;
}

- (void)doExit {
    if ([self dd_isLaunchedByForward]) {
        DDDebugLog(@"doExit forward self=%@", DDObjectSummary(self));
        DDDebugScheduleCaptures(@"doExit");
        [self dd_dismissForwardLaunched];
        return;
    }
    %orig;
}

// 主路径：用户点击导航栏右上“发表”按钮 → OnDone → 发布任务提交后发生。
// 转发启动的 VC 因缺少 baseResultDelegate/imageSelectorController 上游持有者，
// 原生 didFinishCommiting 隔该代理 dismiss 不会生效，这里不依赖它，改为在
// %orig 运行后延迟主动强制 dismiss，与后台 SnsService 上传完全解耦。
- (void)OnDone {
    BOOL isForward = [self dd_isLaunchedByForward];
    if (isForward) {
        DDDebugLog(@"OnDone before orig self=%@ hasClickDone=%@ type=%@ sightDraft=%@ baseResultDelegate=%@ imageSelectorController=%@",
                   DDObjectSummary(self),
                   DDKVCValueSummary(self, @"hasClickDone"),
                   DDKVCValueSummary(self, @"type"),
                   DDKVCValueSummary(self, @"sightDraft"),
                   DDKVCValueSummary(self, @"baseResultDelegate"),
                   DDKVCValueSummary(self, @"imageSelectorController"));
        DDDebugScheduleCaptures(@"OnDone-before-orig");
        DDScheduleForwardSightResiduePreviewCleanup();
    }
    %orig;
    if (isForward) {
        DDDebugLog(@"OnDone after orig self=%@ hasClickDone=%@", DDObjectSummary(self), DDKVCValueSummary(self, @"hasClickDone"));
        DDDebugScheduleCaptures(@"OnDone-after-orig");
        __weak __typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                DDScheduleForwardSightResiduePreviewCleanup();
                [strongSelf dd_dismissForwardLaunched];
            }
        });
    }
}

- (void)postNewItemForSight {
    BOOL isForward = [self dd_isLaunchedByForward];
    if (isForward) {
        DDDebugLog(@"postNewItemForSight before orig self=%@ hasClickDone=%@ type=%@ sightDraft=%@ text=%@",
                   DDObjectSummary(self),
                   DDKVCValueSummary(self, @"hasClickDone"),
                   DDKVCValueSummary(self, @"type"),
                   DDKVCValueSummary(self, @"sightDraft"),
                   DDKVCValueSummary(self, @"textView"));
        DDDebugScheduleCaptures(@"postNewItemForSight-before-orig");
        DDScheduleForwardSightResiduePreviewCleanup();
    }
    %orig;
    if (isForward) {
        DDDebugLog(@"postNewItemForSight after orig self=%@ hasClickDone=%@", DDObjectSummary(self), DDKVCValueSummary(self, @"hasClickDone"));
        DDDebugScheduleCaptures(@"postNewItemForSight-after-orig");
        __weak __typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                DDScheduleForwardSightResiduePreviewCleanup();
                [strongSelf dd_dismissForwardLaunched];
            }
        });
    }
}

// 兑底：如果某些版本 "发表" 按钮不走 OnDone 而是别的 selector，轮询 hasClickDone
// hasClickDone 是 WCNewCommitViewController 内部表示“已点发表”的状态位，发表被点击后被置为 YES
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if ([self dd_isLaunchedByForward]) {
        DDDebugLog(@"viewDidAppear forward self=%@ nav=%@ view=%@ hasClickDone=%@ type=%@",
                   DDObjectSummary(self),
                   DDObjectSummary(self.navigationController),
                   DDObjectSummary(self.view),
                   DDKVCValueSummary(self, @"hasClickDone"),
                   DDKVCValueSummary(self, @"type"));
        DDDebugScheduleCaptures(@"viewDidAppear");
        [self dd_startWatchHasClickDone];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if ([self dd_isLaunchedByForward]) {
        DDDebugLog(@"viewWillDisappear forward animated=%d self=%@ nav=%@ view=%@",
                   animated,
                   DDObjectSummary(self),
                   DDObjectSummary(self.navigationController),
                   DDObjectSummary(self.view));
        DDDebugScheduleCaptures(@"viewWillDisappear");
    }
    %orig;
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    if ([self dd_isLaunchedByForward]) {
        DDDebugLog(@"viewDidDisappear forward animated=%d self=%@ nav=%@ view=%@",
                   animated,
                   DDObjectSummary(self),
                   DDObjectSummary(self.navigationController),
                   DDObjectSummary(self.view));
        DDDebugScheduleCaptures(@"viewDidDisappear");
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
            DDScheduleForwardSightResiduePreviewCleanup();
            __weak __typeof(strongSelf) weakInner = strongSelf;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                __strong __typeof(weakInner) inner = weakInner;
                if (inner) {
                    DDScheduleForwardSightResiduePreviewCleanup();
                    [inner dd_dismissForwardLaunched];
                }
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