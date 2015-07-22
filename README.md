# Code Logging Creator

Code Logging Creator (clc) is a command line utility that reads an Objective-C header file and creates a `xm` file to be compilied by the jailbreak development tool Theos and/or a `mm` file to be use with the CaptainHook framework. It writes hook methos and logs method of the classes specified. It optionally includes `@class` and `@interface` declarations and allows the user to select which classes should be used. It is an alternative to Logify which can be obtained by installing Theos.

## 


## Usage

```
./clc [arguments] <inputFile> <outputFileName>
```

### Arguments (optional)
Argument|Description
--------|-----------
`-h` | Show the help screen.
`-v` | Print the current version number.
`-c` | Include class declarations in code.
`-i` | Include interface declarations in code.
`-l` | Create Logos code file.
`-ch` | Create CaptainHook code file.

### Input file
A valid Objective-C header file.

### Output file name (optional)

The name and location of the file to write to. If this value is not passed, then the created code is printed on-screen.

## Example
Entering the following in Terminal reads the file `ExampleHeader.h` and prints a list of its classes on-screen.

```
./clc -i ExampleHeader.h
Reading header file...

ClassA
ClassB
ClassC
```

The user is prompted to enter a space-separated list of classes, or `[ALL]` to include all classes.

```
Enter a list of classes separated by spaces to log (Enter [ALL] to use every class): ClassA ClassC
```

A `xm` file is created and printed on-screen (or saved to file if a name is specified).

``` obj-c
@interface ClassA
- (void)methodA;
@end

%hook ClassA

- (void)methodA {
  %log;
  %orig;
}

%end

@interface ClassC
- (id)methodC:(int)arg;
@end

%hook ClassC

- (id)methodC:(int)arg {
  %log;
  return %orig(arg);
}

%end
```
