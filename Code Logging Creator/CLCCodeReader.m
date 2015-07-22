//
//  NSDictionary+CLCCodeReader.m
//  clc
//
//  Created by Colin Campbell on 7/16/15.
//  Copyright (c) 2015 Colin Campbell. All rights reserved.
//

#import "CLCCodeReader.h"

@interface CLCCodeReader()
- (MethodObject *)objectForMethod:(NSString *)method;
@end

@implementation CLCCodeReader

- (NSMutableArray *)classObjectsWithContentsOfHeaderFile:(NSString *)path {
    NSMutableArray *objects = nil;
    
    NSError *error = nil;
    NSString *input = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    if ((error == nil) && (input != nil)) {
        objects = [[NSMutableArray alloc] init];
        
        NSScanner *scanner = [[NSScanner alloc] initWithString:input];
        scanner.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        
        while (!scanner.atEnd) {
            // Find class names
            [scanner scanUpToString:@"@interface" intoString:NULL];
            if ([scanner scanString:@"@interface" intoString:NULL]) {
                if (!scanner.isAtEnd) {
                    NSString *className = nil;
                    
                    if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@":{\n"] intoString:&className]) {
                        ClassObject *object = [[ClassObject alloc] init];
                        object.name = [className stringByReplacingOccurrencesOfString:@" " withString:@""];
                        
                        //printf("%s\n", className.UTF8String);
                        
                        // Find methods
                        BOOL foundClassEnd = NO;
                        while (!foundClassEnd) {
                            if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"+-@"] intoString:NULL]) {
                                unichar currentCharacter = [scanner.string characterAtIndex:scanner.scanLocation];
                                
                                if (currentCharacter == '@') {
                                    if ([scanner scanString:@"@end" intoString:NULL]) {
                                        [objects addObject:object];
                                        foundClassEnd = YES;
                                    }
                                    else {
                                        [scanner scanString:@"@" intoString:NULL];
                                    }
                                }
                                else if ((currentCharacter == '+') || (currentCharacter == '-')) {
                                    NSString *preString = nil;
                                    if ([scanner scanString:@"+(" intoString:NULL]) {
                                        preString = @"+(";
                                    }
                                    else if ([scanner scanString:@"-(" intoString:NULL]) {
                                        preString = @"-(";
                                    }
                                    else {
                                        [scanner scanString:@"-" intoString:NULL];
                                    }
                                    
                                    if (preString != nil) {
                                        NSString *method = nil;
                                        if ([scanner scanUpToString:@";" intoString:&method]) {
                                            MethodObject *methodObject = [self objectForMethod:[preString stringByAppendingString:method]];
                                            
                                            if (methodObject != nil) {
                                                [object.methods addObject:methodObject];
                                            }
                                            else {
                                                printf("Error reading portion of file.\n");
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    else {
        if (error != nil) {
            printf("Error: %s\n\n", error.localizedDescription.UTF8String);
        }
        else if (path != nil) {
            printf("Error getting contents of the file %s\n\n", path.UTF8String);
        }
        else {
            printf("Error getting contents of file.\n\n");
        }
    }
    
    return objects;
}




#pragma mark - Private methods

- (MethodObject *)objectForMethod:(NSString *)method {
    //printf("%s\n", method.UTF8String);
    
    MethodObject *methodObject = [[MethodObject alloc] init];
    NSScanner *methodScanner = [[NSScanner alloc] initWithString:method];
    BOOL correctFormat = YES;
    
    if ([methodScanner scanString:@"+" intoString:NULL]) {
        methodObject.isClassMethod = YES;
    }
    else if ([methodScanner scanString:@"-" intoString:NULL]) {
        methodObject.isClassMethod = NO;
    }
    else {
        methodObject = nil;
        correctFormat = NO;
    }
    
    if (correctFormat && !methodScanner.isAtEnd) {
        if ([methodScanner scanString:@"(" intoString:NULL]) {
            NSString *t = nil;
            if ([methodScanner scanUpToString:@")" intoString:&t]) {
                [methodScanner scanString:@")" intoString:NULL];
                
                methodObject.type = t; // Got method return type
                
                while (!methodScanner.isAtEnd) {
                    MethodPiece *piece = [[MethodPiece alloc] init];
                    
                    NSString *pn = nil;
                    if ([methodScanner scanUpToString:@":" intoString:&pn]) {
                        [methodScanner scanString:@":" intoString:NULL];
                        
                        piece.name = pn; // Got piece name
                        
                        if ([methodScanner scanString:@"(" intoString:NULL]) {
                            
                            NSString *pt = nil;
                            if ([methodScanner scanUpToString:@")" intoString:&pt]) {
                                [methodScanner scanString:@")" intoString:NULL];
                                
                                piece.type = pt; // Got piece type
                                
                                [methodObject.pieces addObject:piece];
                                
                                if ([methodScanner scanUpToString:@" " intoString:NULL]) {
                                    [methodScanner scanString:@" " intoString:NULL];
                                }
                            }
                            else {
                                [methodObject.pieces addObject:piece];
                            }
                        }
                        else {
                            [methodObject.pieces addObject:piece];
                        }
                    }
                }
            }
            else {
                methodObject = nil;
            }
        }
        else {
            methodObject = nil;
        }
    }
    
    return methodObject;
}

@end




@implementation ClassObject

- (id)initWithName:(NSString *)name {
    if (self = [super init]) {
        _name = name;
    }
    return self;
}

- (NSMutableArray *)methods {
    if (_methods == nil) {
        _methods = [[NSMutableArray alloc] init];
    }
    return _methods;
}
@end




@implementation MethodObject

- (NSMutableArray *)pieces {
    if (_pieces == nil) {
        _pieces = [[NSMutableArray alloc] init];
    }
    return _pieces;
}

@end




@implementation MethodPiece

- (id)initWithName:(NSString *)name type:(NSString *)type {
    if (self = [super init]) {
        _name = name;
        _type = type;
    }
    return self;
}

@end
