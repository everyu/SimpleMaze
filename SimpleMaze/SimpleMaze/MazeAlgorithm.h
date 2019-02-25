//
//  MazeAlgorithm.h
//  SimpleMaze
//
//  Created by everyu on 2019/2/22.
//  Copyright © 2019 everyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface MapPoint : NSObject
@property (nonatomic) NSInteger i;
@property (nonatomic) NSInteger j;
@property (nonatomic) NSInteger type; //0:障碍 1：陆地
@property (nonatomic) NSInteger status; //用来标识特征 1：已经认证过的, 0：待认证的
@end

@protocol MazeDelegate <NSObject>
/**
 迷宫生成过程的计算回调（这里回调只要是为了能够演示过程）
 
 @param arr 每一步的回调数据
 @param completed 是否结束
 */
- (void)generatingMazeMapDidChanged:(NSArray <__kindof MapPoint *> *)arr completion:(BOOL)completed;

@end

@interface MazeAlgorithm : NSObject

@property (nonatomic, weak) id<MazeDelegate> delegate;
@property (nonatomic) NSInteger row;
@property (nonatomic) NSInteger column;

/**
 随机生成迷宫路径（结果通过delegate回调获取）
 */
- (void)generateRandomMazePath;

/**
 生成破解迷宫数据(结果通过delegate回调获取)
 */
- (void)generatePassingPathCompletion:(void(^)(NSArray <__kindof MapPoint *> *arr))callback;

/**
 remove link
 */
- (void)invalidateLink;
@end

NS_ASSUME_NONNULL_END
