//
//  JDCacheViewController.m
//  JDHybrid_Example
//
//  Created by wangxiaorui19 on 2023/3/9.
//  Copyright © 2023 maxiaoliang8. All rights reserved.
//

#import "JDCacheViewController.h"
#import "JDCacheWebViewController.h"

@interface JDCacheViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) NSMutableArray <NSDictionary *>* dataSource;
@end

@implementation JDCacheViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"JDCache";
    _dataSource = [NSMutableArray array];
    CGFloat y = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    CGSize size = UIScreen.mainScreen.bounds.size;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, y, size.width, size.height - y) style:UITableViewStylePlain];
    if (@available(iOS 13.0, *)) {
        _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
        [appearance configureWithDefaultBackground];
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    
    __weak typeof(self)weakSelf = self;
    [self addGroupTitle:@"非离线" subTitles:@[
        @"纯H5加载（非拦截）",
        @"纯H5加载（拦截走原生网络）"
    ] actionBlock:^(NSInteger index) {
        __strong typeof(weakSelf)self = weakSelf;
        if (!self) return;
        JDCacheWebViewController *vc = [JDCacheWebViewController new];
        switch(index){
            case 0:
            {
                vc.H5LoadType = JDCacheH5LoadTypePure;
            }
                break;
            case 1:
            {
                vc.H5LoadType = JDCacheH5LoadTypeNativeNetwork;
            }
                break;
        }
        [self.navigationController pushViewController:vc animated:YES];
    }];
    
    [self addGroupTitle:@"离线" subTitles:@[
        @"离线加载（包含HTML）",
        @"离线加载（HTML预加载）"
    ] actionBlock:^(NSInteger index) {
        __strong typeof(weakSelf)self = weakSelf;
        if (!self) return;
        JDCacheWebViewController *vc = [JDCacheWebViewController new];
        switch (index) {
            case 0:
            {
                vc.H5LoadType = JDCacheH5LoadTypeLocalResource;
            }
                break;
            case 1:
            {
                vc.H5LoadType = JDCacheH5LoadTypeLocalResourceAndPreload;
            }
                break;
            default:
                break;
        }
        [self.navigationController pushViewController:vc animated:YES];
    }];
    
    [self addGroupTitle:@"降级" subTitles:@[
        @"离线降级加载（1s后降级）"
    ] actionBlock:^(NSInteger index) {
        __strong typeof(weakSelf)self = weakSelf;
        if (!self) return;
        JDCacheWebViewController *vc = [JDCacheWebViewController new];
        switch (index) {
            case 0:
            {
                vc.H5LoadType = JDCacheH5LoadTypeLocalDegrade;
            }
                break;
            default:
                break;
        }
        [self.navigationController pushViewController:vc animated:YES];
    }];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *array = self.dataSource[section][@"subTitles"];
    return array.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"header"];
    if (!view) {
        view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"header"];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, UIScreen.mainScreen.bounds.size.width, 50)];
        [view.contentView addSubview:label];
        label.font = [UIFont boldSystemFontOfSize:20];
        label.tag = 50;
        label.textAlignment = NSTextAlignmentLeft;
    }
    UILabel *label = [view viewWithTag:50];
    label.text = [NSString stringWithFormat:@"Tips%ld--%@",section + 1,self.dataSource[section][@"title"]];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.01;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
    }
     
    cell.textLabel.text = self.dataSource[indexPath.section][@"subTitles"][indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    void(^block)(NSInteger) = self.dataSource[indexPath.section][@"action"];
    if (block) {
        block(indexPath.row);
    }
}

- (void)addGroupTitle:(NSString*)title subTitles:(NSArray<NSString*>*)subTitles actionBlock:(void (^)(NSInteger index))actionBlock{
    [self.dataSource addObject:@{
        @"title":title?:@"",
        @"subTitles":subTitles?:@"",
        @"action":actionBlock?:^(NSInteger index){}
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
