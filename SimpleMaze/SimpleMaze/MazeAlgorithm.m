//
//  MazeAlgorithm.m
//  SimpleMaze
//
//  Created by everyu on 2019/2/22.
//  Copyright © 2019 everyu. All rights reserved.
//

#import "MazeAlgorithm.h"
@implementation MapPoint
- (NSString *)description
{
    return [NSString stringWithFormat:@"%ld %ld %ld",(long)_i,(long)_j,(long)_type];
}


@end

@interface MazeAlgorithm ()
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, strong) NSMutableArray *allPoint;
@property (nonatomic, strong) NSMutableArray *pendingPoints; //待定的点

//破解路径
@property (nonatomic) BOOL success;
@property (nonatomic, strong) NSMutableArray *passedArr; // 用来记录已通过的路径
@property (nonatomic, copy) void(^passingCallback)(NSArray <__kindof MapPoint *>*);

@end

@implementation MazeAlgorithm
#pragma mark - 路径生成
- (void)dealloc
{
    NSLog(@"%@#######dealloc",self);
}

- (void)invalidateLink
{
    [self.link invalidate];
}

- (void)generateRandomMazePath
{
    self.allPoint = [NSMutableArray array];
    self.pendingPoints = [NSMutableArray array];
    
    for (int i = 0; i < self.row; i ++) {
        for (int j = 0; j < self.column; j ++) {
            MapPoint *point = [MapPoint new];
            point.i = i;
            point.j = j;
            if (i % 2 == 0 && j % 2 == 0) {
                point.type = 1;
                point.status = 0;
            }else{
                point.type = 0;
                point.status = 1;
            }
            [self.allPoint addObject:point];
        }
    }
    
    [self.allPoint enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx % (self.column) == 0) {
            printf("\n");
        }
        NSInteger status = [(MapPoint *)obj type];
        printf("%ld ",(long)status);
    }];
    
    
    //选择第一个起点
    MapPoint *point = [self pointI:0 J:0];
    point.status = 1; //确定陆地
    
    //设置周围点为待定
    [self setAroundPointStatus:point];
    
    if ([self.delegate respondsToSelector:@selector(generatingMazeMapDidChanged:completion:)]) {
        [self.delegate generatingMazeMapDidChanged:self.allPoint completion:NO];
    }
    
    //循环处理
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(runInLoop)];
    self.link.preferredFramesPerSecond = 10;
    [self.link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

//循环处理点
- (void)runInLoop;
{
    //随机选出一个待定点
    MapPoint *randomPendingP = [self randomPendingPoint];
    if (randomPendingP) {
        //标记待定点的状态
        [self markDesPointAroundPoint:randomPendingP];
        
        if ([self.delegate respondsToSelector:@selector(generatingMazeMapDidChanged:completion:)]) {
            [self.delegate generatingMazeMapDidChanged:self.allPoint completion:NO];
        }
    }else{
        //没有待定点则退出
        //success
        [self.link invalidate];
        if ([self.delegate respondsToSelector:@selector(generatingMazeMapDidChanged:completion:)]) {
            [self.delegate generatingMazeMapDidChanged:self.allPoint completion:YES];
        }
    }
}

//获取某index元素
- (MapPoint *)pointI:(NSInteger)i J:(NSInteger)j
{
    if (i < 0 || i >= self.row) {
        return nil;
    }
    if (j < 0 || j >= self.column) {
        return nil;
    }
    
    NSInteger index = i*self.column + j;
    return [self.allPoint objectAtIndex:index];
}

//
- (void)markDesPointAroundPoint:(MapPoint *)point
{
    MapPoint *point1, *point2;
    if (point.j % 2 == 0) { //偶数列 上下元素为陆地
        point1 = [self pointI:point.i - 1 J:point.j]; //up
        point2 = [self pointI:point.i + 1 J:point.j]; //down
        
    }else{ //奇数列左右元素为陆地
        point1 = [self pointI:point.i J:point.j - 1]; //left
        point2 = [self pointI:point.i J:point.j + 1]; //right
    }
    
    if (point1.status == 1 && point2.status == 1) {
        point.status = 1;
    }else {
        point.type = 1;
        point.status = 1;
        
        if (point1.status == 1) {
            point2.status = 1;
            [self setAroundPointStatus:point2];
            
        }else{
            point1.status = 1;
            [self setAroundPointStatus:point1];
        }
    }
    
    //该点从待确定表中移除
    [self.pendingPoints removeObject:point];
}


//随机获取一个待定点
- (MapPoint *)randomPendingPoint
{
    if (self.pendingPoints.count > 0) {
        NSInteger index = arc4random() % self.pendingPoints.count;
        return self.pendingPoints[index];
    }else{
        NSLog(@"finished");
        return nil;
    }
}

//设置周围元素为待定
- (void)setAroundPointStatus:(MapPoint *)point
{
    NSInteger i = point.i;
    NSInteger j = point.j;
    //up
    MapPoint *up = [self pointI:i - 1 J:j];
    if ([self pointCanMark:up]) {
        up.status = 0;
        [self.pendingPoints addObject:up];
    }
    
    //left
    MapPoint *left = [self pointI:i J:j - 1];
    if ([self pointCanMark:left]) {
        left.status = 0;
        [self.pendingPoints addObject:left];
    }
    
    //down
    MapPoint *down = [self pointI:i + 1 J:j];
    if ([self pointCanMark:down]) {
        down.status = 0;
        [self.pendingPoints addObject:down];
    }
    
    //right
    MapPoint *right = [self pointI:i J:j + 1];
    if ([self pointCanMark:right]) {
        right.status = 0;
        [self.pendingPoints addObject:right];
    }
    
//    NSLog(@"pending :%@",self.pendingPoints);
}

- (BOOL)pointCanMark:(MapPoint *)point
{
    if (point != nil && point.type == 0) {
        return YES;
    }
    
    return NO;
}

#pragma mark - 路径破解
- (void)generatePassingPathCompletion:(void (^)(NSArray<__kindof MapPoint *> * _Nonnull arr))callback
{
    self.passingCallback = callback;
    self.passedArr = [NSMutableArray array];
    
    MapPoint *startPoint = [self.allPoint firstObject];
    [self insertPassedPoint:startPoint];
    [self nextStepFromPoint:startPoint];
}

- (BOOL)checkIndexI:(NSInteger)i J:(NSInteger)j
{
    if (i >= self.row || i < 0 || j >= self.column || j < 0) {
        return NO;
    }else{
        return YES;
    }
}

- (void)nextStepFromPoint:(MapPoint *)point
{
    
    if (self.success) return;
    
    if (point.i == self.row - 1 && point.j == self.column - 1) {
        
        NSLog(@"EXIT SUCCESS!!!");
        
        self.success = YES;
        if (self.passingCallback) {
            self.passingCallback(self.passedArr);
            self.passingCallback = nil;
        }
        
        return;
    }
    
    NSInteger i = point.i;
    NSInteger j = point.j;
    NSInteger next_i, next_j;
    
    //右
    next_i = i;
    next_j = j + 1;
    if ([self checkIndexI:next_i J:next_j]) {
        MapPoint *nextPoint = [self.allPoint objectAtIndex:next_i * self.column + next_j];
        if (nextPoint.type == 0 || [self.passedArr containsObject:nextPoint]) {
            
        }else{
            [self insertPassedPoint:nextPoint];
            //继续下一步
            [self nextStepFromPoint:nextPoint];
        }
    }
    
    //下
    next_i = i + 1;
    next_j = j;
    if ([self checkIndexI:next_i J:next_j]) {
        MapPoint *nextPoint = [self.allPoint objectAtIndex:next_i * self.column + next_j];
        if (nextPoint.type == 0 || [self.passedArr containsObject:nextPoint]) {
            
        }else{
            [self insertPassedPoint:nextPoint];
            //继续下一步
            [self nextStepFromPoint:nextPoint];
        }
    }
    
    //左
    next_i = i;
    next_j = j - 1;
    if ([self checkIndexI:next_i J:next_j]) {
        MapPoint *nextPoint = [self.allPoint objectAtIndex:next_i * self.column + next_j];
        if (nextPoint.type == 0 || [self.passedArr containsObject:nextPoint]) {
            
        }else{
            [self insertPassedPoint:nextPoint];
            //继续下一步
            [self nextStepFromPoint:nextPoint];
        }
    }
    
    //上
    next_i = i - 1;
    next_j = j;
    if ([self checkIndexI:next_i J:next_j]) {
        MapPoint *nextPoint = [self.allPoint objectAtIndex:next_i * self.column + next_j];
        if (nextPoint.type == 0 || [self.passedArr containsObject:nextPoint]) {
            
        }else{
            [self insertPassedPoint:nextPoint];
            //继续下一步
            [self nextStepFromPoint:nextPoint];
        }
    }
    
    //到这里依然没有解，则该路径不合适
    [self deletePassedPoint:point];
}

- (void)insertPassedPoint:(MapPoint *)point
{
    if (self.success) return;
    
    [self.passedArr addObject:point];
//    NSLog(@"%@",self.passedArr);
}

- (void)deletePassedPoint:(MapPoint *)point
{
    if (self.success) return;
    
    [self.passedArr removeObject:point];
//    NSLog(@"%@",self.passedArr);
}

@end
