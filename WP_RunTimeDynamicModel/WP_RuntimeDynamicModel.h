//
//  WP_RuntimeDynamicModel.h
//  WP_RunTimeDynamicModel
//
//  Created by Wangpu_IOS on 16/3/9.
//  Copyright © 2016年 Wangpu_IOS. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol WPRuntimeEmptyProperty <NSObject>
/**
 *  设置一个默认值，如果取出来为nil的时候，我们会自动默认值为空
 */
-(NSDictionary*)WP_defaultEmptyValueForProperty;


@end
@interface WP_RuntimeDynamicModel : NSObject<WPRuntimeEmptyProperty>
//定义测试的属性
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSNumber *count;
@property (nonatomic, assign) int    commentCount;
@property (nonatomic, strong) NSArray *summaries;
@property (nonatomic, strong) NSDictionary *parameters;
@property (nonatomic, strong) NSSet *results;
//
@property(nonatomic,strong)WP_RuntimeDynamicModel*TestModel;
//只读属性
@property(nonatomic,assign,readonly)NSString*CalssVesrion;
// 通过这个方法来实现自动生成model
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
// 转换成字典
- (NSDictionary *)toDictionary;

// 测试
-(void)test;
@end
