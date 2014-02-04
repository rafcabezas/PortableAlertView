//
//  PortableAlertView
//
//
//  Created by Raf Cabezas on 2013.
//

#import <Cocoa/Cocoa.h>
#import "PortableAlertView.h"
#import <objc/runtime.h>

#define kNO_WINDOW_ID @"__NO-Window-Id__"
NSMutableDictionary *g_portableAlertStackDict  = nil;
NSMutableDictionary *g_AlertIsUpDict           = nil;

@interface PortableAlertView () <NSAlertDelegate>

@end

@implementation PortableAlertView

// Designated initializer
- (id)initWithTitle:(NSString *)title message:(NSString *)message onWindow:(id)window
{
    if ((self = [super init])) {
        self.buttons     = [[NSMutableArray alloc] init];
        self.textFields  = [[NSMutableArray alloc] init];
        
        self.title = title;
        self.message = message;
        self.window = window;
        
        self.context = [[NSAlert alloc] init];
        
        NSAlert *alert = (NSAlert *)self.context;
        if (title && [title length]) {
            [alert setMessageText:title];
            if (message && [message length])
                [alert setInformativeText:message];
        }
        else {
            [alert setMessageText:message];
        }
        [alert setAlertStyle:NSWarningAlertStyle];
    }
    
    return self;
}

- (id) getDictKey
{
    NSValue *box = nil;
    if (self.window) {
        box = [NSValue valueWithPointer:(__bridge const void *)(self.window)];
    }
    else
        box = [NSValue valueWithPointer:kNO_WINDOW_ID];
    
    return box;
}

- (NSMutableDictionary *) alertStackDict
{
    if (!g_portableAlertStackDict) {
        g_portableAlertStackDict = [[NSMutableDictionary alloc] init];
    }
    
    return g_portableAlertStackDict;
}

- (NSMutableArray *) alertStack
{
    NSMutableArray *portableAlertStack = [g_portableAlertStackDict objectForKey:[self getDictKey]];
    if (!portableAlertStack) {
        portableAlertStack = [[NSMutableArray alloc] init];
        [[self alertStackDict] setObject:portableAlertStack forKey:[self getDictKey]];
    }
    
    return portableAlertStack;
}

// Is any alert up
+ (BOOL) isUp
{
    return (g_AlertIsUpDict!=nil);
}

// Is this alert up (self)
- (BOOL) alertIsUp
{
    if (!g_AlertIsUpDict) {
        g_AlertIsUpDict = [[NSMutableDictionary alloc] init];
        [g_AlertIsUpDict setObject:[NSNumber numberWithBool:NO] forKey:[self getDictKey]];
    }
    
    return [[g_AlertIsUpDict objectForKey:[self getDictKey]] boolValue];
}

- (void) setAlertIsUp:(BOOL)value
{
    if (!g_AlertIsUpDict) {
        g_AlertIsUpDict = [[NSMutableDictionary alloc] init];
    }
    
    [g_AlertIsUpDict setObject:[NSNumber numberWithBool:value] forKey:[self getDictKey]];
}

- (void)dealloc
{
    NSLog(@"PortableAlert dealloc");
}

// Use this method to add an arbitrary number of buttons to the alert view.
// The block, if present, will be invoked when the corresponding button is pressed.
- (void)addButtonWithTitle:(NSString *)title block:(PortableAlertViewBlock)block
{
    //NSAlert *alert = (NSAlert *)self.context;
    
    NSMutableDictionary *buttonInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  title, @"title"
                                , [block copy], @"block"
                                , [NSNumber numberWithBool:NO], @"isCancel"
                                , nil];
    [self.buttons addObject:buttonInfo];
}

// Use this method to set the title and action for the cancel button,
// which may have a different visual style than a normal button
- (void)setCancelButtonBlock:(PortableAlertViewBlock)block
{
   // NSAlert *alert = (NSAlert *)self.context;
    NSString *title = NSLocalizedString(@"Cancel", nil);

    NSMutableDictionary *buttonInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  title, @"title"
                                , [block copy], @"block"
                                , nil];
    self.cancelButton = buttonInfo;
}

- (void)setOKButtonBlock:(PortableAlertViewBlock)block
{
    // NSAlert *alert = (NSAlert *)self.context;
    NSString *title = NSLocalizedString(@"OK", nil);
    
    NSMutableDictionary *buttonInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                title, @"title"
                                , [block copy], @"block"
                                , nil];
    self.okButton = buttonInfo;
}

// Show the alert with the current presentation style
- (void)show
{
    [[self alertStack] addObject:self];

    if (![self alertIsUp]) {
        NSAlert *alert = (NSAlert *)self.context;
        
        if (self.okButton) {
            [self.buttons insertObject:self.okButton atIndex:0];
        }
        
        for (NSMutableDictionary *buttonInfo in self.buttons) {
            NSString *title = [buttonInfo objectForKey:@"title"];
            [alert addButtonWithTitle:title];
        }
        if (self.cancelButton) {
            NSString *title = [self.cancelButton objectForKey:@"title"];
            PortableAlertViewBlock block = [self.cancelButton objectForKey:@"block"];
            [alert addButtonWithTitle:title];
            
            NSMutableDictionary *buttonInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        title, @"title"
                                        , [block copy], @"block"
                                        , [NSNumber numberWithBool:YES], @"isCancel"
                                        , nil];
            [self.buttons addObject:buttonInfo];
        }
        
        /* set the button indices */
        int nextButtonIndex = NSAlertFirstButtonReturn;
        for (NSMutableDictionary *buttonInfo in self.buttons) {
            [buttonInfo setObject:[NSNumber numberWithInt:nextButtonIndex++] forKey:@"index"];
        }
        
        switch(self.alertViewStyle)
        {
            case PortableAlertViewStylePlainTextInput:
            {
                NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
                [input setStringValue:@""];
                [alert setAccessoryView:input];
                [self.textFields addObject:input];
                break;
            }
            case PortableAlertViewStyleSecureTextInput:
            {
                NSSecureTextField *input = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
                [input setStringValue:@""];
                [alert setAccessoryView:input];
                [self.textFields addObject:input];
                break;
            }
            case PortableAlertViewStyleLoginAndPasswordInput:
            {
                NSView *accessoryView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 200, 55)];
                NSTextField *userField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 30, 200, 24)];
                [self.textFields addObject:userField];
                NSTextField *passField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
                [self.textFields addObject:passField];
                [accessoryView addSubview:userField];
                [accessoryView addSubview:passField];
                
                [userField setStringValue:@"username"];
                [passField setStringValue:@"password"];
                
                [alert setAccessoryView:accessoryView];
                break;
            }
            default:
                break;
        }
        
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:nil];
    
        [self setAlertIsUp:YES];
    }
}

- (NSString *) textAtIndex:(NSInteger)textFieldIndex
{
    return [[self.textFields objectAtIndex:textFieldIndex] stringValue];
}

#pragma mark NSAlertDelegate Methods:
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    int selectedIndex = returnCode;// - NSAlertFirstButtonReturn;
    
    for (NSTextField *tf in self.textFields) {
        [tf validateEditing];
    }
    
    for (NSMutableDictionary *buttonInfo in self.buttons) {
        int buttonIndex = [[buttonInfo objectForKey:@"index"] intValue];
        PortableAlertViewBlock block = [buttonInfo objectForKey:@"block"];
        if (buttonIndex == selectedIndex) {
            if (block) {
                //Do this in a dispatch queue so it happens after the alert closes!
                dispatch_async(dispatch_get_main_queue(), block);
            }
        }
    }
    

    double delayInSeconds = 0.25; //Give UI time to remove current alert
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

        [[self alertStack] removeObject:self];
        [self setAlertIsUp:NO];
        
        if ([[self alertStack] count] == 0) {
            [[self alertStackDict] removeObjectForKey:[self getDictKey]];
        }
        else
            [[[self alertStack] objectAtIndex:0] show];
        
    });
}

@end
