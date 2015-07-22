//
//  CLCCodeWriter.h
//  clc
//
//  Created by Colin Campbell on 7/16/15.
//  Copyright (c) 2015 Colin Campbell. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLCCodeWriter;
@protocol CLCCodeWriterDelegate <NSObject>
- (void)codeWriter:(CLCCodeWriter *)writer wroteCodeToPath:(NSString *)path;
- (void)codeWriter:(CLCCodeWriter *)writer createdCode:(NSString *)code;
@end

@interface CLCCodeWriter : NSObject

@property (nonatomic, assign) id<CLCCodeWriterDelegate> delegate;

- (NSError *)createCode:(NSArray *)formattedCode atPath:(NSString *)path includeInterfaceDeclarations:(BOOL)interfaceDeclarations includeClassDeclarations:(BOOL)classDeclarations createLogos:(BOOL)logos createCH:(BOOL)cptHk;

@end
