//
//  main.m
//  Code Logging Creator
//
//  Created by Colin Campbell on 7/21/15.
//  Copyright (c) 2015 Colin Campbell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLCInterface.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        CLCInterface *interface = [[CLCInterface alloc] init];
        [interface interpetArguments:argv];
    }
    
    return 0;
}
