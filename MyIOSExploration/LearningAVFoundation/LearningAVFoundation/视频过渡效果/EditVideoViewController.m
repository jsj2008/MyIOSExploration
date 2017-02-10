//
//  EditVideoViewController.m
//  LearningAVFoundation
//
//  Created by fang wang on 17/2/10.
//  Copyright © 2017年 wdy. All rights reserved.
//

#import "EditVideoViewController.h"
#import "SimpleEditor.h"
#import "VideoMaker.h"

@interface EditVideoViewController ()
@property (nonatomic, strong) SimpleEditor		*editor;
@property (nonatomic, strong) NSMutableArray   *clips;
@property (nonatomic, strong) NSMutableArray	*clipTimeRanges;
@property (nonatomic, assign) float  transitionDuration;
@property (nonatomic, assign) BOOL	   transitionsEnabled;
@property (nonatomic, strong)AVPlayerItem *item;
@property (nonatomic, strong)AVQueuePlayer *player;
@end

@implementation EditVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.editor = [[SimpleEditor alloc] init];
    self.clips = [[NSMutableArray alloc] init];
    self.clipTimeRanges = [[NSMutableArray alloc] init];
    
    self.transitionDuration = 2.0; // 默认变换时间
    self.transitionsEnabled = YES;
    
    [self setupEditingAndPlayback];
    
    UIButton* btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 100, 30);
    btn.center = self.view.center;
    [btn setBackgroundColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.view addSubview:btn];
    kWeakSelf(self)
    [btn addActionHandler:^{
        kStrongSelf(self)
       [self.editor beginExport];
    }];
}

- (void)setupEditingAndPlayback
{
    AVAsset* asset1 = [AVAsset assetWithURL:[VideoMaker createVideoWithImage:kImage(@"image1.jpg")]];
    AVAsset* asset2 = [AVAsset assetWithURL:[VideoMaker createVideoWithImage:kImage(@"image2.jpg")]];
    AVAsset* asset3 = [AVAsset assetWithURL:[VideoMaker createVideoWithImage:kImage(@"image3.jpg")]];
    AVAsset* asset4 = [AVAsset assetWithURL:[VideoMaker createVideoWithImage:kImage(@"image4.jpg")]];
    AVAsset* asset5 = [AVAsset assetWithURL:[VideoMaker createVideoWithImage:kImage(@"image5.jpg")]];
    
    dispatch_group_t dispatchGroup = dispatch_group_create();
    NSArray *assetKeysToLoadAndTest = @[@"tracks", @"duration", @"composable"];
    
    // 加载视频
    [self loadAsset:asset1 withKeys:assetKeysToLoadAndTest usingDispatchGroup:dispatchGroup];
    [self loadAsset:asset2 withKeys:assetKeysToLoadAndTest usingDispatchGroup:dispatchGroup];
    [self loadAsset:asset3 withKeys:assetKeysToLoadAndTest usingDispatchGroup:dispatchGroup];
    [self loadAsset:asset4 withKeys:assetKeysToLoadAndTest usingDispatchGroup:dispatchGroup];
    [self loadAsset:asset5 withKeys:assetKeysToLoadAndTest usingDispatchGroup:dispatchGroup];
    
    // 等待就绪
    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^(){
        [self synchronizeWithEditor];
    });
}

- (void)loadAsset:(AVAsset *)asset withKeys:(NSArray *)assetKeysToLoad usingDispatchGroup:(dispatch_group_t)dispatchGroup
{
    dispatch_group_enter(dispatchGroup);
    kWeakSelf(self)
    [asset loadValuesAsynchronouslyForKeys:assetKeysToLoad completionHandler:^(){
        kStrongSelf(self)
        // 测试是否成功加载
        BOOL bSuccess = YES;
        for (NSString *key in assetKeysToLoad) {
            NSError *error;
            if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
                NSLog(@"Key value loading failed for key:%@ with error: %@", key, error);
                bSuccess = NO;
                break;
            }
        }
        if (![asset isComposable]) {
            NSLog(@"Asset is not composable");
            bSuccess = NO;
        }
        
        if (bSuccess && CMTimeGetSeconds(asset.duration) > 3) {
            
            float assetDurtion = CMTimeGetSeconds(asset.duration);
            CMTime startTime = CMTimeMakeWithSeconds(0, 1);
            CMTime endTime = CMTimeMakeWithSeconds(assetDurtion, 1);
            CMTimeRange timeRange = CMTimeRangeMake(startTime, endTime);
            NSValue *value = [NSValue valueWithCMTimeRange:timeRange];
            
            NSLog(@"asset.duration = %@, bSuccess = %@, value = %@", @(assetDurtion), @(bSuccess), value);
            
            [self.clips addObject:asset];
            [self.clipTimeRanges addObject:value];
        } else {
            NSLog(@"error ");
        }
        dispatch_group_leave(dispatchGroup);
    }];
}
- (void)synchronizeWithEditor
{
    // Clips
    [self synchronizeEditorClipsWithOurClips];
    [self synchronizeEditorClipTimeRangesWithOurClipTimeRanges];
    
    
    self.editor.transitionDuration = CMTimeMakeWithSeconds(2.0, 600);
    self.editor.transitionType = (EditorTransitionType*)malloc(sizeof(int) * self.editor.clips.count);
    for (int i = 0; i < self.editor.clips.count; i ++) {
        NSLog(@"transitionType = %@", @([self getRandomNumber:EditorTransitionTypeNone to:EditorTransitionTypeCustom]));
        self.editor.transitionType[i] = [self getRandomNumber:EditorTransitionTypeNone to:EditorTransitionTypeCustom];
    }
    [self.editor buildCompositionObjectsForPlayback];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self play];
    });
}

-(int)getRandomNumber:(int)from to:(int)to
{
    return (int)(from + (arc4random() % (to - from + 1)));
}

- (void)play{
    AVQueuePlayer *player = [AVQueuePlayer playerWithPlayerItem:self.editor.playerItem];
    player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    AVPlayerViewController *vc = [[AVPlayerViewController alloc] init];
    vc.player = player;
    vc.view.frame = CGRectMake(0, 200, kScreenWidth, 300);
    vc.view.backgroundColor = [UIColor blackColor];
    vc.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view addSubview:vc.view];
    
    [player play];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playEnd)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    self.item = self.editor.playerItem;
    self.player = player;
}

- (void)playEnd{
    [self.item seekToTime:kCMTimeZero];
    [self.player pause];
}

- (void)applicationWillResignActive{
    [self.player pause];
}


- (void)synchronizeEditorClipsWithOurClips
{
    NSMutableArray *validClips = [NSMutableArray array];
    for (AVURLAsset *asset in self.clips) {
        if (![asset isKindOfClass:[NSNull class]]) {
            [validClips addObject:asset];
        }
    }
    
    self.editor.clips = validClips;
}
- (void)synchronizeEditorClipTimeRangesWithOurClipTimeRanges
{
    NSMutableArray *validClipTimeRanges = [NSMutableArray array];
    for (NSValue *timeRange in self.clipTimeRanges) {
        if (! [timeRange isKindOfClass:[NSNull class]]) {
            [validClipTimeRanges addObject:timeRange];
        }
    }
    self.editor.clipTimeRanges = validClipTimeRanges;
}

- (void)dealloc{
    
    NSLog(@"%s", __func__);
}


@end
