/*
 MIT License

Copyright (c) 2022 JD.com, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

#import "XHViewController.h"
#import "JDWebViewController.h"
#import "JDCacheViewController.h"
#import "JDXSLViewController.h"

@interface XHViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) NSMutableArray <NSDictionary *>* dataSource;
@end

@implementation XHViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"JDHybrid-demo";
    
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
        [appearance configureWithDefaultBackground];
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    }
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    __weak typeof(self)weakSelf = self;
    [self addGroupTitle:@"JDHybrid" subTitles:@[
        @"JDWebView&JDBridge", @"JDCache",@"JDXSL"
    ] actionBlock:^(NSInteger index) {
        __strong typeof(weakSelf)self = weakSelf;
        if (!self) return;
        switch (index) {
            case 0:
            {
                JDWebViewController *vc = [JDWebViewController new];
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            case 1:
            {
                JDCacheViewController *vc = [JDCacheViewController new];
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            case 2:
            {
                JDXSLViewController *vc = [JDXSLViewController new];
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
        }
        
    }];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)addGroupTitle:(NSString*)title
            subTitles:(NSArray<NSString*>*)subTitles
          actionBlock:(void (^)(NSInteger index))actionBlock{
    [self.dataSource addObject:@{
        @"title":title?:@"",
        @"subTitles":subTitles?:@"",
        @"action":actionBlock?:^(NSInteger index){}
    }];
}

#pragma mark -

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
    label.text = [NSString stringWithFormat:@"%@",self.dataSource[section][@"title"]];
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


#pragma mark -
- (UITableView *)tableView {
    if (!_tableView) {
        CGFloat y = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
        CGSize size = UIScreen.mainScreen.bounds.size;
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, y, size.width, size.height - y) style:UITableViewStylePlain];
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _tableView;
}

- (NSMutableArray<NSDictionary *> *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
