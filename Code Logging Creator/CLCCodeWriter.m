//
//  CLCCodeWriter.m
//  clc
//
//  Created by Colin Campbell on 7/16/15.
//  Copyright (c) 2015 Colin Campbell. All rights reserved.
//

#import "CLCCodeWriter.h"
#import "CLCCodeReader.h"
#import "stdlib.h"




@interface CLCCodeWriter()
- (NSString *)logosOutputForCode:(NSArray *)formattedCode includeInterfaceDeclarations:(BOOL)interfaceDeclarations includeClassDeclarations:(BOOL)classDelcarations;
- (NSString *)chOutputForCode:(NSArray *)formattedCode includeInterfaceDeclarations:(BOOL)interfaceDeclarations includeClassDeclarations:(BOOL)classDelcarations;
- (NSString *)formatType:(NSString *)type;
- (void)addHeader:(NSMutableString *)string;
- (void)addInterfaceDeclarations:(NSMutableString *)string forClassNames:(NSMutableArray *)classNames methodTypes:(NSMutableArray *)methodTypes currentObject:(ClassObject *)object;
- (void)addClassDeclarations:(NSMutableString *)string forClassNames:(NSArray *)classNames methodTypes:(NSArray *)methodTypes;
@end




@implementation CLCCodeWriter

- (NSError *)createCode:(NSArray *)formattedCode atPath:(NSString *)path includeInterfaceDeclarations:(BOOL)interfaceDeclarations includeClassDeclarations:(BOOL)classDeclarations createLogos:(BOOL)logos createCH:(BOOL)cptHk {
    NSError *error = nil;
    
    if (logos) {
        NSString *logosCode = [self logosOutputForCode:formattedCode includeInterfaceDeclarations:interfaceDeclarations includeClassDeclarations:classDeclarations];
        
        if (path == nil) {
            if ([self.delegate respondsToSelector:@selector(codeWriter:createdCode:)]) {
                [self.delegate codeWriter:self createdCode:logosCode];
            }
        }
        else {
            NSString *logosOutputPath = [[path stringByAppendingString:@"_logos"] stringByAppendingPathExtension:@"xm"];
            [logosCode writeToFile:logosOutputPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
            
            if ([self.delegate respondsToSelector:@selector(codeWriter:wroteCodeToPath:)] && (error == nil)) {
                [self.delegate codeWriter:self wroteCodeToPath:logosOutputPath];
            }
        }
    }
    
    if (cptHk) {
        NSString *chCode = [self chOutputForCode:formattedCode includeInterfaceDeclarations:interfaceDeclarations includeClassDeclarations:classDeclarations];
        
        if (path == nil) {
            if ([self.delegate respondsToSelector:@selector(codeWriter:createdCode:)]) {
                [self.delegate codeWriter:self createdCode:chCode];
            }
        }
        else {
            NSString *chOutputPath = [[path stringByAppendingString:@"_ch"] stringByAppendingPathExtension:@"mm"];
            [chCode writeToFile:chOutputPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
            
            if ([self.delegate respondsToSelector:@selector(codeWriter:wroteCodeToPath:)] && (error == nil)) {
                [self.delegate codeWriter:self wroteCodeToPath:chOutputPath];
            }
        }
    }
    
    return error;
}




#pragma mark - Private methods

- (NSString *)logosOutputForCode:(NSArray *)formattedCode includeInterfaceDeclarations:(BOOL)interfaceDeclarations includeClassDeclarations:(BOOL)classDeclarations {
    NSMutableString *output = [[NSMutableString alloc] initWithString:@""];
    NSMutableArray *classNames = [[NSMutableArray alloc] init];
    
    //
    // Create header
    //
    NSMutableArray *methodTypes = [[NSMutableArray alloc] init];
    for (int i = 0; i < formattedCode.count; i++) {
        ClassObject *object = (ClassObject *)[formattedCode objectAtIndex:i];
        
        // Check methods
        for (MethodObject *method in object.methods) {
            if (![methodTypes containsObject:method.type]) {
                [methodTypes addObject:method.type];
            }
        }
    }

    [self addHeader:output];
    
    if (classDeclarations) {
        [self addClassDeclarations:output forClassNames:classNames methodTypes:methodTypes];
    }
    
    
    //
    // Create hook methods
    //
    for (int i = 0; i < formattedCode.count; i++) {
        ClassObject *object = (ClassObject *)[formattedCode objectAtIndex:i];
        
        // Add interface declarations if needed
        if (interfaceDeclarations) {
            [self addInterfaceDeclarations:output forClassNames:classNames methodTypes:methodTypes currentObject:object];
        }
        
        // Hook methods
        if (object) {
            [output appendFormat:@"\n%%hook %@\n\n", object.name];
            
            for (int j = 0; j < object.methods.count; j++) {
                MethodObject *methodObject = (MethodObject *)[object.methods objectAtIndex:j];
                
                if (methodObject.isClassMethod) {
                    [output appendString:@"+"];
                }
                else {
                    [output appendString:@"-"];
                }
                
                [output appendFormat:@"(%@)", methodObject.type];
                
                for (int k = 0; k < methodObject.pieces.count; k++) {
                    MethodPiece *piece = (MethodPiece *)[methodObject.pieces objectAtIndex:k];
                    
                    [output appendString:piece.name];
                    
                    if (piece.type != nil) {
                        [output appendFormat:@":(%@)arg%d ", piece.type, (k + 1)];
                    }
                    else {
                        [output appendString:@" "];
                    }
                }
                
                [output appendString:@"{\n\t\%log;\n"];
                
                if (![methodObject.type isEqualToString:@"void"]) {
                    [output appendString:@"\treturn \%orig"];
                }
                else {
                    [output appendString:@"\t\%orig"];
                }
                
                if ([(MethodObject *)[methodObject.pieces firstObject] type] != nil) {
                    [output appendString:@"("];
                    
                    for (int l = 0; l < methodObject.pieces.count; l++) {
                        [output appendFormat:@"arg%d", (l + 1)];
                        
                        if (l == methodObject.pieces.count - 1) {
                            [output appendString:@");\n"];
                        }
                        else {
                            [output appendString:@", "];
                        }
                    }
                }
                else {
                    [output appendString:@";\n"];
                }
                
                [output appendString:@"}\n\n"];
            }
            
            [output appendString:@"\%end\n\n"];
        }
    }
    
    return output;
}

- (NSString *)chOutputForCode:(NSArray *)formattedCode includeInterfaceDeclarations:(BOOL)interfaceDeclarations includeClassDeclarations:(BOOL)classDelcarations {
    NSMutableString *output = [[NSMutableString alloc] initWithString:@""];
    NSMutableArray *classNames = [[NSMutableArray alloc] init];
    
    //
    // Create header
    //
    NSMutableArray *methodTypes = [[NSMutableArray alloc] init];
    for (int i = 0; i < formattedCode.count; i++) {
        ClassObject *object = (ClassObject *)[formattedCode objectAtIndex:i];
        
        // Check methods
        for (MethodObject *method in object.methods) {
            if (![methodTypes containsObject:method.type]) {
                [methodTypes addObject:method.type];
            }
        }
    }
    
    [self addHeader:output];
    
    [output appendString:@"#import <Foundation/Foundation.h>\n"];
    [output appendString:@"#import \"CaptainHook/CaptainHook.h\"\n\n"];
    
    if (classDelcarations) {
        [self addClassDeclarations:output forClassNames:classNames methodTypes:methodTypes];
    }
    
    
    //
    // Create hook methods
    //
    NSMutableString *constructorHooks = [[NSMutableString alloc] initWithString:@""];
    NSMutableString *lateClasses = [[NSMutableString alloc] initWithString:@""];
    
    for (int i = 0; i < formattedCode.count; i++) {
        ClassObject *object = (ClassObject *)[formattedCode objectAtIndex:i];
        
        [lateClasses appendFormat:@"\tCHLoadLateClass(%@);\n", object.name];
        
        // Add interface declarations if needed
        if (interfaceDeclarations) {
            [self addInterfaceDeclarations:output forClassNames:classNames methodTypes:methodTypes currentObject:object];
        }
        
        // Hook methods
        if (object) {
            [output appendFormat:@"CHDeclareClass(%@);\n\n", object.name];
            
            for (int j = 0; j < object.methods.count; j++) {
                MethodObject *method = (MethodObject *)[object.methods objectAtIndex:j];
                NSString *userFacingName = nil;
                NSMutableString *argumentString = [[NSMutableString alloc] initWithString:@""];
                NSMutableString *superArgumentString = [[NSMutableString alloc] initWithString:@""];
                int argumentCount = 0;
                 
                for (int k = 0; k < method.pieces.count; k++) {
                    MethodPiece *piece = (MethodPiece *)[method.pieces objectAtIndex:k];
                    
                    if (piece.name) {
                        if (piece.type == nil) {
                            if (userFacingName == nil) {
                                userFacingName = piece.name;
                                [argumentString appendFormat:@", %@", piece.name];
                                [superArgumentString appendFormat:@", %@", piece.name];
                            }
                            
                            break;
                        }
                        else {
                            if (userFacingName == nil) {
                                userFacingName = piece.name;
                            }
                            
                            [superArgumentString appendFormat:@", %@, arg%d", piece.name, (k + 1)];
                            [argumentString appendFormat:@", %@, %@, arg%d", piece.name, piece.type, (k + 1)];
                            argumentCount += 1;
                        }
                    }
                    else {
                        break;
                    }
                }
                
                [output appendFormat:@"CHMethod(%d, %@, %@%@) {\n", argumentCount, method.type, object.name, argumentString];
                [output appendFormat:@"\tNSLog(@\"%@: %@\");\n", object.name, userFacingName];
                
                if (![method.type isEqualToString:@"void"]) {
                    [output appendString:@"\treturn "];
                }
                else {
                    [output appendString:@"\t"];
                }
                
                [output appendFormat:@"CHSuper(%d, %@%@);\n", argumentCount, object.name, superArgumentString];
                [output appendString:@"}\n\n"];
                
                // Create CHHook code for constructor definition at the end of the file
                [constructorHooks appendFormat:@"\tCHHook(%d, %@", argumentCount, object.name];
                
                for (int k = 0; k < method.pieces.count; k++) {
                    MethodPiece *piece = (MethodPiece *)[method.pieces objectAtIndex:k];
                    [constructorHooks appendFormat:@", %@", piece.name];
                }
                
                [constructorHooks appendString:@");\n"];
            }
        }
    }
    
    // Add constructor definition
    [output appendString:@"CHConstructor {\n"];
    [output appendFormat:@"%@\n", lateClasses];
    [output appendFormat:@"%@", constructorHooks];
    [output appendString:@"}\n"];
    
    return output;
}

- (NSString *)formatType:(NSString *)type {
    NSString *formattedType = type;
    
    if ([type containsString:@"*"] && ![type containsString:@"<"] && ![type containsString:@"/"]) {
        formattedType = [formattedType stringByReplacingOccurrencesOfString:@" " withString:@""];
        formattedType = [formattedType stringByReplacingOccurrencesOfString:@"*" withString:@""];
    }
    else {
        formattedType = nil;
    }
    
    return formattedType;
}

- (void)addHeader:(NSMutableString *)string {
    [string appendString:@"\n// ********************************************\n"];
    [string appendString:@"// Created by Code Logging Creator (clc)\n"];
    [string appendString:@"// ********************************************\n\n"];
}

- (void)addInterfaceDeclarations:(NSMutableString *)string forClassNames:(NSMutableArray *)classNames methodTypes:(NSMutableArray *)methodTypes currentObject:(ClassObject *)object {
    // Create interface section
    [string appendFormat:@"@interface %@\n", object.name];
    
    if (![classNames containsObject:object.name]) {
        [classNames addObject:object.name];
    }
    
    for (MethodObject *method in object.methods) {
        NSMutableString *methodString = [[NSMutableString alloc] initWithString:@""];
        
        if (method.isClassMethod) {
            [methodString appendString:@"+"];
        }
        else {
            [methodString appendString:@"-"];
        }
        
        [methodString appendFormat:@"(%@)", method.type];
        
        for (int k = 0; k < method.pieces.count; k++) {
            MethodPiece *piece = (MethodPiece *)[method.pieces objectAtIndex:k];
            
            [methodString appendString:piece.name];
            
            if (piece.type != nil) {
                [methodString appendFormat:@":(%@)arg%d", piece.type, (k + 1)];
                
                if (k != method.pieces.count - 1) {
                    [methodString appendString:@" "];
                }
            }
        }
        
        [methodString appendString:@";\n"];
        
        [string appendString:methodString];
    }
    
    [string appendString:@"@end\n\n"];
}

- (void)addClassDeclarations:(NSMutableString *)string forClassNames:(NSArray *)classNames methodTypes:(NSArray *)methodTypes {
    for (NSString *type in methodTypes) {
        if (![classNames containsObject:type]) {
            NSString *formattedType = [self formatType:type];
            
            if (formattedType != nil) {
                [string appendFormat:@"@class %@;\n", formattedType];
            }
        }
    }
    
    [string appendString:@"\n"];
}

@end
