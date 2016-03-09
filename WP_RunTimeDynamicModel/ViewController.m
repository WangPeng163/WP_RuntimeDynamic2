//
//  ViewController.m
//  WP_RunTimeDynamicModel
//
//  Created by Wangpu_IOS on 16/3/9.
//  Copyright © 2016年 Wangpu_IOS. All rights reserved.
//

#import "ViewController.h"
#import "WP_RuntimeDynamicModel.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WP_RuntimeDynamicModel*model=[[WP_RuntimeDynamicModel alloc]init];
    [model test];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
