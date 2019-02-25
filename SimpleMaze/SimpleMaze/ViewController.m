//
//  ViewController.m
//  SimpleMaze
//
//  Created by everyu on 2019/2/22.
//  Copyright © 2019 everyu. All rights reserved.
//

#import "ViewController.h"
#import "MazeAlgorithm.h"

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

#define HasBangs ([[UIApplication sharedApplication] statusBarFrame].size.height > 20)
#define ViewSize ((ScreenWidth-2)/Column - 2)
#define Padding 2
#define Row (HasBangs ? 41 : 31)  //需要为奇数
#define Column 21 //需要为奇数
#define ViewTag 1000

@interface MazeView : UIImageView

@property (nonatomic) int i;
@property (nonatomic) int j;
@property (nonatomic) int index;
@property (nonatomic) UIImageView *icon;
@end

@implementation MazeView

- (instancetype)initWithFrame:(CGRect)frame
{
    
    self = [super initWithFrame:frame];
    if (self) {
        self.icon = [[UIImageView alloc] initWithFrame:self.bounds];
        self.icon.hidden = YES;
        self.icon.image = [UIImage imageNamed:@"famer"];
        [self addSubview:self.icon];
    }
    return self;
}

- (int)index
{
    return self.i * Column + self.j + ViewTag;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%d - %d",_i,_j];
}

@end

@interface ViewController ()<MazeDelegate>


@property (nonatomic) UIView *contentView;
@property (nonatomic) UIButton *reloadBtn;
@property (nonatomic) UIButton *passingBtn;
@property (nonatomic, strong) NSMutableArray *viewArr; //记录所有mazeView视图

@property (nonatomic, strong) NSMutableArray *passedPoints; //记录通过迷宫的路径
@property (nonatomic) NSInteger currentPointIndex; //记录演示通过迷宫时的index

@property (nonatomic) MazeAlgorithm *mazeData;
@property (nonatomic, strong) CADisplayLink *link;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupSubviews];
}

- (void)setupMazePath
{
    [self.viewArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [(MazeView *)obj icon].hidden = YES;
    }];
    [self.mazeData invalidateLink];

    self.mazeData = [[MazeAlgorithm alloc] init];
    self.mazeData.delegate = self;
    self.mazeData.row = Row;
    self.mazeData.column = Column;
    [self.mazeData generateRandomMazePath];
}

- (void)setupSubviews
{
    self.view.backgroundColor = [UIColor whiteColor];
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(1, 34, ScreenWidth-2, Row * (ViewSize + Padding))];
    self.contentView.layer.borderColor = [UIColor redColor].CGColor;
    self.contentView.layer.borderWidth = 2;
    [self.view addSubview:self.contentView];
    
    self.reloadBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.reloadBtn.frame = CGRectMake(40, CGRectGetMaxY(self.contentView.frame) + 2, 80, 40);
    [self.reloadBtn setTitle:@"生成迷宫" forState:UIControlStateNormal];
    [self.reloadBtn addTarget:self action:@selector(clickedOnReloadBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.reloadBtn];
    
    self.passingBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.passingBtn.frame = CGRectMake(ScreenWidth - 120, CGRectGetMaxY(self.contentView.frame) + 2, 80, 40);
    [self.passingBtn setTitle:@"通过迷宫" forState:UIControlStateNormal];
    [self.passingBtn addTarget:self action:@selector(clickedOnPassingBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.passingBtn setEnabled:NO];
    [self.view addSubview:self.passingBtn];
}

- (void)showPassingPathAnimation
{
    self.currentPointIndex = 0;
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(showPath)];
    self.link.preferredFramesPerSecond = 5;
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
}

- (void)showPath
{
    if (self.currentPointIndex >= self.passedPoints.count) {
        [self.link invalidate];
        self.reloadBtn.enabled = YES;
        return;
    }
    
    MapPoint *point = [self.passedPoints objectAtIndex:self.currentPointIndex];
    MazeView *view = [self.viewArr objectAtIndex:point.i * Column + point.j];
    view.icon.hidden = NO;
    self.currentPointIndex ++;
}

#pragma mark - action
- (void)clickedOnReloadBtn:(UIButton *)sender
{
    sender.enabled = NO;
    [self setupMazePath];
}

- (void)clickedOnPassingBtn:(UIButton *)sender
{
    sender.enabled = NO;
    self.passedPoints = [NSMutableArray array];
    self.currentPointIndex = 0;
    [self.mazeData generatePassingPathCompletion:^(NSArray<__kindof MapPoint *> * _Nonnull arr) {
        [self.passedPoints addObjectsFromArray:arr];
        [self showPassingPathAnimation];
    }];
}

#pragma mark - delegate
- (void)generatingMazeMapDidChanged:(NSArray <__kindof MapPoint *> *)arr completion:(BOOL)completed;
{
    [arr enumerateObjectsUsingBlock:^(__kindof MapPoint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MazeView *view = [self.viewArr objectAtIndex:obj.i*Column + obj.j];
        if (obj.type == 1) {
            if (obj.status == 0) {
                view.image = [UIImage imageNamed:@"grass"];
            }else{
                view.image = [UIImage imageNamed:@"grass"];
            }
        }else {
            if (obj.status == 1) {
                view.image = [UIImage imageNamed:@"water"];
            }else {
                view.image = [UIImage imageNamed:@"question"];
            }
        }
    }];
    
    if (completed) {
        self.passingBtn.enabled = YES;
    }
}

#pragma mark - getter
- (NSMutableArray *)viewArr
{
    if (_viewArr == nil) {
        _viewArr = [NSMutableArray array];
        for (int i = 0; i < Row; i ++) {
            for (int j = 0; j < Column; j ++) {
                MazeView *view = [[MazeView alloc] initWithFrame:CGRectMake(j * (ViewSize+Padding), i * (ViewSize+Padding), ViewSize, ViewSize)];
                view.i = i;
                view.j = j;
                [_viewArr addObject:view];
                [self.contentView addSubview:view];
            }
        }
    }
    return _viewArr;
}
@end
