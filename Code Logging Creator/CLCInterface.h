//
//  CLCInterface.h
//  clc
//
//  Created by Colin Campbell on 7/16/15.
//  Copyright (c) 2015 Colin Campbell. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CLC_NAME                    "Class Log Creator"
#define USAGE_STRING                "Usage: ./clc [arguments] <inputFilePath> <outputFileName>"
#define MORE_INFORMATION_STRING     "Type ./clc -h (return) for more information."
#define INPUT_ERROR_STRING          "Input is in the wrong format."
#define INPUT_CLASS_PROMPT          "Enter a list of classes separated by spaces to log (Enter [ALL] to use every class): "

#define ARGUMENT_HELP               "-h"
#define ARGUMENT_INTERFACE          "-i"
#define ARGUMENT_CLASS              "-c"
#define ARGUMENT_LOGOS              "-l"
#define ARGUMENT_CAPTAIN_HOOK       "-ch"

@interface CLCInterface : NSObject

- (void)interpetArguments:(const char **)arguments;

@end


