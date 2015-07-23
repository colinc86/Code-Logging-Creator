//
//  CLCInterface.m
//  clc
//
//  Created by Colin Campbell on 7/16/15.
//  Copyright (c) 2015 Colin Campbell. All rights reserved.
//

#import "CLCInterface.h"
#import "CLCCodeReader.h"
#import "CLCCodeWriter.h"

@interface CLCInterface() <CLCCodeWriterDelegate>
@property (nonatomic, assign) BOOL interfaceDeclarations;
@property (nonatomic, assign) BOOL classDeclarations;
@property (nonatomic, assign) BOOL createLogosCode;
@property (nonatomic, assign) BOOL createCaptainHookCode;
@property (nonatomic, assign) const char *inFile;
@property (nonatomic, assign) const char *outFile;

- (void)createCode;

- (void)printHelpText;
- (void)printInputErrorText;
- (void)printClassPrompt:(NSMutableArray *)classObjects;
@end

@implementation CLCInterface

- (id)init {
    self = [super init];
    if (self) {
        _interfaceDeclarations = NO;
        _classDeclarations = NO;
        _createLogosCode = NO;
        _createCaptainHookCode = NO;
        _inFile = NULL;
        _outFile = NULL;
    }
    return self;
}

- (void)interpetArguments:(const char **)arguments {
    BOOL didCheckFlags = NO;
    BOOL finished = NO;
    BOOL inputError = NO;
    
    // Iterate through arguments while ignoring the first (./clc)
    int i = 1;
    while (arguments[i] != NULL) {
        const char *argument = arguments[i];
        char firstCharacter = argument[0];
        
        if (firstCharacter == '-') {
            // If the argument is a flag
            
            if (!didCheckFlags) {
                if (strcmp(argument, ARGUMENT_HELP) == 0) {
                    // Show help
                    finished = YES;
                    [self printHelpText];
                    break;
                }
                else if (strcmp(argument, ARGUMENT_INTERFACE) == 0) {
                    self.interfaceDeclarations = YES;
                }
                else if (strcmp(argument, ARGUMENT_CLASS) == 0) {
                    self.classDeclarations = YES;
                }
                else if (strcmp(argument, ARGUMENT_LOGOS) == 0) {
                    self.createLogosCode = YES;
                }
                else if (strcmp(argument, ARGUMENT_CAPTAIN_HOOK) == 0) {
                    self.createCaptainHookCode = YES;
                }
                else {
                    inputError = YES;
                    break;
                }
            }
            else {
                inputError = YES;
                break;
            }
        }
        else {
            didCheckFlags = YES;
            
            if (self.inFile == NULL) {
                self.inFile = argument;
            }
            else if (self.outFile == NULL) {
                self.outFile = argument;
            }
            else {
                inputError = YES;
                break;
            }
        }
        
        i++;
    }
    
    if (!finished) {
        if (inputError) {
            [self printInputErrorText];
        }
        else {
            if (i == 1) {
                [self printHelpText];
            }
            else {
                if (self.inFile != NULL) {
                    [self createCode];
                }
                else {
                    [self printInputErrorText];
                }
            }
        }
    }
}




#pragma mark - Private methods

- (void)createCode {
    printf("Reading header file...\n");
    
    NSString *inputPath = [self formatPath:[NSString stringWithUTF8String:self.inFile] isInputFile:YES];
    NSMutableArray *classObjects = [[[CLCCodeReader alloc] init] classObjectsWithContentsOfHeaderFile:inputPath];
    
    if (classObjects != nil) {
        // If the file was successfully read
        
        if (classObjects.count > 0) {
            // Check code to create and set default if necessary
            if (!self.createLogosCode && !self.createCaptainHookCode) {
                self.createLogosCode = YES;
            }
            
            // Print the objects and edit array based on response to prompt
            [self printClassPrompt:classObjects];
            
            // Get the output path and write the code to file(s)
            NSString *outputPath = nil;
            if (self.outFile != NULL) {
                outputPath = [self formatPath:[NSString stringWithUTF8String:self.outFile] isInputFile:NO];
            }
            
            CLCCodeWriter *writer = [[CLCCodeWriter alloc] init];
            writer.delegate = self;
            
            NSError *error = [writer createCode:classObjects atPath:outputPath includeInterfaceDeclarations:self.interfaceDeclarations includeClassDeclarations:self.classDeclarations createLogos:self.createLogosCode createCH:self.createCaptainHookCode];
            
            if (error != nil) {
                printf("Error: %s\n\n", error.localizedDescription.UTF8String);
            }
            else {
                printf("\n");
            }
        }
        else {
            printf("No interface declarations were found.\n\n");
        }
    }
}

- (NSString *)formatPath:(NSString *)path isInputFile:(BOOL)inputFile {
    if (!inputFile) {
        // If this is the output file name, make sure the extension is not included.
        // The extension is added in the CLCCodeWriter object.
        path = [path stringByDeletingPathExtension];
    }
    
    if (![path containsString:@"/"]) {
        // If this is a file in the current working directory, get the directory path and append the file's path component.
        char dir[1024];
        if (getcwd(dir, sizeof(dir)) != NULL) {
            NSString *directoryString = [NSString stringWithUTF8String:dir];
            path = [directoryString stringByAppendingPathComponent:path];
        }
    }
    
    return path;
}




#pragma mark - Text output

- (void)printHelpText {
    printf("%s\n\n", CLC_NAME);
    
    printf("%s\n", USAGE_STRING);
    printf("%-20s %s\n", "[arguments]", "One or more arguments from the list below.");
    printf("%-20s %s\n", "<inputFilePath>", "The location of the header file to read from.");
    printf("%-20s %s\n", "<outputFileName>", "(Optional) The name of the file, not including extension, to be created.\n");
    
    printf("%-15s %s\n", "Argument", "Description");
    printf("%-15s %s\n", "========", "===========");
    printf("%-15s %s\n", "-h", "Print this help menu.");
    printf("%-15s %s\n", "-c", "Include class declarations.");
    printf("%-15s %s\n", "-i", "Include interface declarations.");
    printf("%-15s %s\n", "-l", "(Default) Create Logos code.");
    printf("%-15s %s\n", "-ch", "Create CaptainHook code.\n");
}

- (void)printInputErrorText {
    printf("%s\n\n", INPUT_ERROR_STRING);
}

- (void)printClassPrompt:(NSMutableArray *)classObjects {
    printf("\n");
    
    for (ClassObject *object in classObjects) {
        printf("%s\n", object.name.UTF8String);
    }
    
    printf("\n%s", INPUT_CLASS_PROMPT);
    
    char input[4096];
    fgets(input, 4096, stdin);
    
    if (input[strlen(input) - 1] == '\n') {
        input[strlen(input) - 1] = '\0';
    }
    
    char *command = strtok(input," ");
    const char *arguments[256];
    
    if (command != NULL) {
        int argumentIndex = 0;
        arguments[argumentIndex] = strtok(NULL, " ");
        
        while (arguments[argumentIndex] != NULL) {
            argumentIndex += 1;
            arguments[argumentIndex] = strtok(NULL, " ");
        }
    }
    else {
        command = "";
    }
    
    if (strcmp(command, "[ALL]") != 0) {
        NSMutableArray *tempObjectsArray = [[NSMutableArray alloc] init];
        
        for (ClassObject *object in classObjects) {
            BOOL found = NO;
            
            if (strcmp(command, object.name.UTF8String) == 0) {
                found = YES;
            }
            
            int index = 0;
            while ((arguments[index] != NULL) && !found) {
                if (strcmp(arguments[index], object.name.UTF8String) == 0) {
                    found = YES;
                    break;
                }
                
                index += 1;
            }
            
            if (!found) {
                [tempObjectsArray addObject:object];
            }
        }
        
        [classObjects removeObjectsInArray:tempObjectsArray];
    }
}




#pragma mark - CLCCodeWriterDelegate methods

- (void)codeWriter:(CLCCodeWriter *)writer wroteCodeToPath:(NSString *)path {
    printf("Created %s\n", path.UTF8String);
}

- (void)codeWriter:(CLCCodeWriter *)writer createdCode:(NSString *)code
{
    printf("%s\n\n", code.UTF8String);
}

@end