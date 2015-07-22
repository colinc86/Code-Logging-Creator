//
//  NSDictionary+CLCCodeReader.h
//  clc
//
//  Created by Colin Campbell on 7/16/15.
//  Copyright (c) 2015 Colin Campbell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLCCodeReader : NSObject
- (NSMutableArray *)classObjectsWithContentsOfHeaderFile:(NSString *)path;
@end




@interface ClassObject : NSObject
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSMutableArray *methods;
@end




@interface MethodObject : NSObject
@property (nonatomic, assign) BOOL isClassMethod;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSMutableArray *pieces;
@end




@interface MethodPiece : NSObject
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *type;
@end
