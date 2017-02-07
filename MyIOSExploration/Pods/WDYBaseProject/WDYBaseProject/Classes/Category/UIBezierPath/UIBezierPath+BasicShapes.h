//
//  UIBezierPath+BasicShapes.h
//  Example
//
//  Created by Pierre Dulac on 26/02/13.
//  Copyright (c) 2013 Pierre Dulac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (BasicShapes)
// 💗型
+ (UIBezierPath *)heartShape:(CGRect)originalFrame;
// 人头像
+ (UIBezierPath *)userShape:(CGRect)originalFrame;
+ (UIBezierPath *)martiniShape:(CGRect)originalFrame;
+ (UIBezierPath *)beakerShape:(CGRect)originalFrame;
+ (UIBezierPath *)starShape:(CGRect)originalFrame;
+ (UIBezierPath *)stars:(NSUInteger)numberOfStars shapeInFrame:(CGRect)originalFrame;

@end