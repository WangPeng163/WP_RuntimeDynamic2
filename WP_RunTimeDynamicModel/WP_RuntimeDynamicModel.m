//
//  WP_RuntimeDynamicModel.m
//  WP_RunTimeDynamicModel
//
//  Created by Wangpu_IOS on 16/3/9.
//  Copyright © 2016年 Wangpu_IOS. All rights reserved.
//

#import "WP_RuntimeDynamicModel.h"
#import <objc/runtime.h>
#import <objc/message.h>
/**
 *  首先介绍本三方库用于动态的添加字段为属性，然后利用Runtime运行时期转化为模型
 *
 */
@implementation WP_RuntimeDynamicModel


- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        for (NSString *key in dictionary.allKeys) {
            id value = [dictionary objectForKey:key];
            /**
             *  模型中有模型属性
             
             对于本demo中，模型中还有模型属性，那么我们应该如何来赋值呢？其实，我们需要注意一点，一定要给模型属性分配内存，否则看起来赋值了，但是对象还是空
             */
            /**
             *  模型属性转换成字典
             
             我们这里的模型有一个属性也是一个模型，因此我们需要额外处理一下：
             */
            if ([key isEqualToString:@"TestModel"]) {
                WP_RuntimeDynamicModel *testModel = [[WP_RuntimeDynamicModel alloc] initWithDictionary:value];
                value = testModel;
                self.TestModel = testModel;
                /**
                 *  这里是在for循环中的，我们一定要注意加上continue，否则下边可能会将其值设置为空哦。
                 */
                continue;
            }
            
            SEL setter = [self propertySetterWithKey:key];
            if (setter != nil) {
                /**
                 *  我们需要明确一点，objc_msgSend函数是用于发送消息的，而这个函数是可以很多个参数的，但是我们必须手动转换成对应类型参数，比如上面我们就是强制转换objc_msgSend函数类型为带三个参数且返回值为void函数，然后才能传三个参数。如果我们直接通过objc_msgSend(self, setter, value)是报错，说参数过多。
                 
                 (void (*)(id, SEL, id)这是C语言中的函数指针，如果不了解C，没有关系，我们只需要记住参数列表前面是一个(*)这样的就是对应函数指针了。
                 *
                 *
                 */
                ((void (*)(id, SEL, id))objc_msgSend)(self, setter, value);
            }
        }
    }
    
    return self;
}

- (NSDictionary *)toDictionary {
    /**
     *  模型转字典
     
     首先，我们需要先获取所有的属性，以便获取属性值：
     */
    unsigned int outCount = 0;
    /**
     *  objc_property_t类型代表属性，它是一个结构体。通过函数class_copyPropertyList可以获取对象的属性列表及属性的个数。
     *
     *  @param class]   <#class] description#>
     *  @param outCount <#outCount description#>
     *
     *  @return <#return value description#>
     */
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    
    if (outCount != 0) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:outCount];
        
        for (unsigned int i = 0; i < outCount; ++i) {
            /**
             *  在遍历属性列表时，我们通过这样获取名称：
             */
            objc_property_t property = properties[i];
            const void *propertyName = property_getName(property);
            NSString *key = [NSString stringWithUTF8String:propertyName];
            
            // 继承于NSObject的类都会有这几个在NSObject中的属性
            if ([key isEqualToString:@"description"]
                || [key isEqualToString:@"debugDescription"]
                || [key isEqualToString:@"hash"]
                || [key isEqualToString:@"superclass"]) {
                continue;
            }
            
            // 我们只是测试，不做通用封装，因此这里不额外写方法做通用处理，只是写死测试一下效果
            if ([key isEqualToString:@"testModel"]) {
                if ([self respondsToSelector:@selector(toDictionary)]) {
                    id testModel = [self.TestModel toDictionary];
                    if (testModel != nil) {
                        [dict setObject:testModel forKey:key];
                    }
                    continue;
                }
            }
            /**
             *  调用getter方法获取值
             
             我们要通过runtime获取值，常用的有两种方式：
             
             通过performSelector方法
             通过NSInvocation对象
             下面是通过NSInvocation的方法，流程可以这样：先获取方法签名，然后根据方法签名生成NSInvocation对象，设置target、SEL，然后调用，最后获取返回值：
             */
            SEL getter = [self propertyGetterWithKey:key];
            if (getter != nil) {
                // 获取方法的签名
                NSMethodSignature *signature = [self methodSignatureForSelector:getter];
                
                // 根据方法签名获取NSInvocation对象
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                // 设置target
                [invocation setTarget:self];
                // 设置selector
                [invocation setSelector:getter];
                
                // 方法调用
                [invocation invoke];
                
                // 接收返回的值
                __unsafe_unretained NSObject *propertyValue = nil;
                [invocation getReturnValue:&propertyValue];
                /**
                 *  如果是通过performSelector方式，一行代码就可以了，但是会提示有内存泄露的风险，通常使用上面这种方式，而不是直接使用下面这种方式：
                 */
                //        id propertyValue = [self performSelector:getter];
                
                /**
                 *  我们这里还做了额外的处理，当属性值获取到是空的时候，我们可以通过协议指定默认值。当值为空时，我们就会使用默认值：
                 */
                if (propertyValue == nil) {
                    if ([self respondsToSelector:@selector(WP_defaultEmptyValueForProperty)]) {
                        NSDictionary *defaultValueDict = [self WP_defaultEmptyValueForProperty];
                        
                        id defaultValue = [defaultValueDict objectForKey:key];
                        propertyValue = defaultValue;
                    }
                }
                
                if (propertyValue != nil) {
                    [dict setObject:propertyValue forKey:key];
                }
            }
        }
        
        free(properties);
        
        return dict;
    }
    
    free(properties);
    return nil;
}
/**
 *  生成Getter方法
 
 我们可以通过NSSelectorFromString函数来生成SEL选择器，当然我们也可以通过@selector()生成SEL选择器，但是我们这里只能使用前者：
 *
 *  @param key <#key description#>
 *
 *  @return <#return value description#>
 */
- (SEL)propertyGetterWithKey:(NSString *)key {
    if (key != nil) {
        SEL getter = NSSelectorFromString(key);
        
        if ([self respondsToSelector:getter]) {
            return getter;
        }
    }
    
    return nil;
}
/**
 *  我们要通过objc_msgSend函数来发送消息给对象，然后通过属性的setter方法来赋值，那么我们要生成setter选择器：
 *这里就是生成属性的setter选择器。我们知道，系统生成属性的setter方法的规范是setKey:这样的格式，因此我们只要按照同样的规则生成setter就可以了。另外我们还需要判断是否可以响应此setter方法。
 

 *  @param key <#key description#>
 *
 *  @return <#return value description#>
 */
- (SEL)propertySetterWithKey:(NSString *)key {
    NSString *propertySetter = key.capitalizedString;
    propertySetter = [NSString stringWithFormat:@"set%@:", propertySetter];
    
    // 生成setter方法
    SEL setter = NSSelectorFromString(propertySetter);
    
    if ([self respondsToSelector:setter]) {
        return setter;
    }
    
    return nil;
}
#pragma mark - HYBEmptyPropertyProperty
- (NSDictionary *)WP_defaultEmptyValueForProperty {
    return @{@"name" : [NSNull null],
             @"title" : [NSNull null],
             @"count" : @(1),
             @"commentCount" : @(1),
             @"classVersion" : @"0.0.1"};
}
- (void)test {
    NSMutableSet *set = [NSMutableSet setWithArray:@[@"可变集合", @"字典->不可变集合->可变集合"]];
    NSDictionary *dict = @{@"name"  : @"标哥的技术博客",
                           @"title" : @"http://www.henishuo.com",
                           @"count" : @(11),
                           @"results" : [NSSet setWithObjects:@"集合值1", @"集合值2", set , nil],
                           @"summaries" : @[@"sm1", @"sm2", @{@"keysm": @{@"stkey": @"字典->数组->字典->字典"}}],
                           @"parameters" : @{@"key1" : @"value1", @"key2": @{@"key11" : @"value11", @"key12" : @[@"三层", @"字典->字典->数组"]}},
                           @"classVersion" : @(1.1),
                           @"testModel" : @{@"name"  : @"标哥的技术博客",
                                            @"title" : @"http://www.henishuo.com",
                                            @"count" : @(11),
                                            @"results" : [NSSet setWithObjects:@"集合值1", @"集合值2", set , nil],
                                            @"summaries" : @[@"sm1", @"sm2", @{@"keysm": @{@"stkey": @"字典->数组->字典->字典"}}],
                                            @"parameters" : @{@"key1" : @"value1", @"key2": @{@"key11" : @"value11", @"key12" : @[@"三层", @"字典->字典->数组"]}},
                                            @"classVersion" : @(1.1)}};
    WP_RuntimeDynamicModel *model = [[WP_RuntimeDynamicModel alloc] initWithDictionary:dict];
    
    NSLog(@"%@", model);
    
    NSLog(@"model->dict: %@", [model toDictionary]);
}
@end
