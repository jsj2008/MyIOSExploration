//
//  Case14StairView.m
//  Masonry实践
//
//  Created by fang wang on 17/3/15.
//  Copyright © 2017年 com.LBE.Photo. All rights reserved.
//

#import "Case14StairView.h"

@interface Case14StairView ()
@property (nonatomic, strong) NSMutableArray <UILabel *> *itemViews;
@property (nonatomic, assign) CGSize contentSize;
@end

@implementation Case14StairView

- (void)setStairTitles:(NSArray<NSString *> *)titles{

    [self.itemViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // 重新创建
    _itemViews = [NSMutableArray new];
    
    // 循环创建新的Label
    for (NSString *title in titles) {
        UILabel *label = [UILabel new];
        label.text = title;
        label.font = [UIFont systemFontOfSize:12];
        label.layer.borderColor = [UIColor lightGrayColor].CGColor;
        label.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
        label.numberOfLines = 0;
        [self addSubview:label];
        [_itemViews addObject:label];
    }
    
    // 重新布局
    _contentSize = CGSizeZero;
    [self updateStairLayout];
}

/*
 UIView的intrinsicContentSize，就是获取这个View的固有的，内在的，本质的的内容大小。
 重写这个方法，返回自己的内容大小，交由Autolayout布局系统去计算布局。并且，这个大小是不能依赖外部的大小的。
 */
- (CGSize)intrinsicContentSize {
    [self updateStairLayout];
    return _contentSize;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateStairLayout];
}

- (void)updateStairLayout {
    if (_itemViews.count == 0) {
        // 没有设置内容，内容大小为零
        _contentSize = CGSizeZero;
        return;
    }
    
    // 计算每个Label的平均宽度
    CGFloat eachLabelWidth = CGRectGetWidth(self.bounds) / (CGFloat)_itemViews.count;
    CGFloat lastY = 0;
    CGFloat lastX = 0;
    
    for (UILabel *label in _itemViews) {
        // 根据内容、当前width计算高度
        label.preferredMaxLayoutWidth = eachLabelWidth;
        CGFloat height = [label sizeThatFits:CGSizeMake(eachLabelWidth, 0)].height;
        
        // 设置frame
        CGRect frame = CGRectMake(lastX, lastY, eachLabelWidth, height);
        label.frame = frame;
        
        // 更新下一轮
        lastX += eachLabelWidth;
        lastY += height;
    }
    
    // 更新contentSize
    CGSize newContentSize = CGSizeMake(CGRectGetWidth(self.bounds), lastY);
    
    // 判断内容大小是否有变化
    if (!CGSizeEqualToSize(newContentSize, _contentSize)) {
        // 更新contentSize
        _contentSize = newContentSize;
        
        // 通知外部IntrinsicContentSize失效
        [self invalidateIntrinsicContentSize];
    }
}


@end
