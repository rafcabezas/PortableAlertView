//
//  PortableAlertView
//
//
//  Created by Raf Cabezas on 2013.
//

#import <UIKit/UIKit.h>
#import "PortableAlertView.h"
#import <objc/runtime.h>

#define kNO_WINDOW_ID @"__NO-Window-Id__"
NSMutableDictionary *g_portableAlertStackDict  = nil;
NSMutableDictionary *g_AlertIsUpDict           = nil;
BOOL                 g_AlertIsAnyUp            = NO;

@interface PortableAlertView () <UIAlertViewDelegate, UITextFieldDelegate>

@end

@implementation PortableAlertView

// Designated initializer
- (id)initWithTitle:(NSString *)title message:(NSString *)message onWindow:(id)window
{
    if ((self = [super init])) {
        self.buttons     = [[NSMutableArray alloc] init];
        self.textFields  = [[NSMutableArray alloc] init];
        
        self.alertViewStyle = PortableAlertViewStyleDefault;
        self.kbtype = PortableAlertViewKBTypeDefault;
        
        self.title = title;
        self.message = message;
        self.window = window;
        
        self.context = nil;

        //To handle enter from kb
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processHWKeyEvent:) name:@"KeyEventCharactersNotification" object:nil];

    }
    
    return self;
}

- (void) dealloc
{
    NSLog(@"PortableAlert dealloc");
    
    //To handle enter from kb
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"KeyEventCharactersNotification" object:nil];
}

- (id) getDictKey
{
    return [NSValue valueWithPointer:(__bridge const void *)(self.window)]?:kNO_WINDOW_ID;
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
    return g_AlertIsAnyUp;
    /*
    __block BOOL isUp = NO;
    
    [[g_AlertIsUpDict allKeys] enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        isUp = obj?[obj boolValue]:NO;
        if (isUp) stop = YES;
    }];
    
    return isUp;
     */
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
    
    g_AlertIsAnyUp = value;
}


// Use this method to add an arbitrary number of buttons to the alert view.
// The block, if present, will be invoked when the corresponding button is pressed.
- (void)addButtonWithTitle:(NSString *)title block:(PortableAlertViewBlock)block
{
    NSDictionary *buttonInfo = [NSDictionary dictionaryWithObjectsAndKeys:
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
    NSString *title = NSLocalizedString(@"Cancel", nil);
    
    NSDictionary *buttonInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                title, @"title"
                                , [block copy], @"block"
                                , nil];
    self.cancelButton = buttonInfo;
}

- (void)setOKButtonBlock:(PortableAlertViewBlock)block
{
    NSString *title = NSLocalizedString(@"OK", nil);
    
    NSDictionary *buttonInfo = [NSDictionary dictionaryWithObjectsAndKeys:
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
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.title
                                                        message:self.message
                                                       delegate:self
                                              cancelButtonTitle:[self.cancelButton objectForKey:@"title"]
                                              otherButtonTitles:nil];
        
        self.context = alert;
        
        
        if (self.okButton)
            [self.buttons insertObject:self.okButton atIndex:0];
        
        // No buttons defined? Add a default OK button
        if ([self.buttons count] == 0) {
            [self setOKButtonBlock:^{}];
            [self.buttons insertObject:self.okButton atIndex:0];
        }
        
        for (NSDictionary *buttonInfo in self.buttons) {
            [alert addButtonWithTitle:[buttonInfo objectForKey:@"title"]];
        }
        
        if (self.cancelButton) {
            NSString *title = [self.cancelButton objectForKey:@"title"];
            PortableAlertViewBlock block = [self.cancelButton objectForKey:@"block"];
            
            NSDictionary *buttonInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                        title, @"title"
                                        , [block copy], @"block"
                                        , [NSNumber numberWithBool:YES], @"isCancel"
                                        , nil];
            [self.buttons addObject:buttonInfo];
        }
        
        switch(self.alertViewStyle)
        {
            case PortableAlertViewStylePlainTextInput:
            {
                [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
                /* Set up delegate so alert can be dismissed with Enter */
                UITextField *tf = [alert textFieldAtIndex:0];
                tf.delegate = self;
                
                [self.textFields addObject:tf];
                break;
            }
            case PortableAlertViewStyleSecureTextInput:
            {
                [alert setAlertViewStyle:UIAlertViewStyleSecureTextInput];
                /* Set up delegate so alert can be dismissed with Enter */
                UITextField *tf = [alert textFieldAtIndex:0];
                tf.delegate = self;
                
                [self.textFields addObject:tf];
                break;
            }
            case PortableAlertViewStyleLoginAndPasswordInput:
            {
                [alert setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];                /* Set up delegate so alert can be dismissed with Enter */
                /* Set up delegate so alert can be dismissed with Enter  */
                /* Enter already makes focus move from login to password */
                /* So we only need to worry about the passwd field (1)   */
                UITextField *tf = [alert textFieldAtIndex:1];
                tf.delegate = self;
                
                [self.textFields addObject:[alert textFieldAtIndex:0]];
                [self.textFields addObject:[alert textFieldAtIndex:1]];
                break;
            }
            default:
                break;
        }
        
        if (self.kbtype == PortableAlertViewKBTypeNumberPad) {
            UITextField *tf = [self.textFields objectAtIndex:0];
            [tf setKeyboardType:UIKeyboardTypeNumberPad];
        }
        
        [alert show];
        
        [self setAlertIsUp:YES];
    }
}

- (NSString *) textAtIndex:(NSInteger)textFieldIndex
{
    UIAlertView *alert = (UIAlertView *)self.context;
    //return [[self.textFields objectAtIndex:textFieldIndex] stringValue];
    return [alert textFieldAtIndex:textFieldIndex].text;
}

#pragma mark NSAlertDelegate Methods:
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // This block is to prevent double-handlings in iOS7
    if (self.buttonClicked)
        return;
    self.buttonClicked = YES;
    
    NSString *clickedButtonTitle = [alertView buttonTitleAtIndex:buttonIndex];

    // disable text field delegates now that we've handled the alert button (to prevent double 'handlings')
    for (UITextField *tf in self.textFields) {
        tf.delegate = nil;
    }
    
    PortableAlertViewBlock runBlock = nil;
    
    for (NSDictionary *buttonInfo in self.buttons) {
        NSString *buttonTitle = [buttonInfo objectForKey:@"title"];
        PortableAlertViewBlock block = [buttonInfo objectForKey:@"block"];
        if ([clickedButtonTitle isEqualToString:buttonTitle]) {
            if (block) {
                runBlock = block;
            }
            break;
        }
    }
    
    double delayInSeconds = 0.33; //Give UI time to remove current alert
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [[self alertStack] removeObject:self];
        [self setAlertIsUp:NO];
        
        if (runBlock)
            runBlock();
        
        if ([[self alertStack] count] == 0) {
            [[self alertStackDict] removeObjectForKey:[self getDictKey]];
        }
        else {
            PortableAlertView *alert = [[self alertStack] objectAtIndex:0];
            [alert show];
        }
        
    });
}

#pragma mark Text Field Delegate Fields:
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSString *text = textField.text;
    if (text && [text length]) {
        [self synthesizeFirstButton];
    }
}

- (void) synthesizeFirstButton
{
    int index = 0, i;
    UIAlertView *alert = (UIAlertView *)self.context;
    
    if ([self.buttons count]) {
        NSString *button0Title = [self.buttons[0] objectForKey:@"title"];
        
        for (i = 0; i < [alert numberOfButtons]; i++) {
            NSString *buttonTitle = [alert buttonTitleAtIndex:i];
            if ([buttonTitle isEqualToString:button0Title]) {
                index = i;
                break;
            }
        }
    }
    
    [self alertView:alert clickedButtonAtIndex:index];
    [alert dismissWithClickedButtonIndex:index animated:YES];
}

- (void) synthesizeCancel
{
    int index = -1, i;
    UIAlertView *alert = (UIAlertView *)self.context;
    NSString *button0Title = NSLocalizedString(@"Cancel", nil);
    
    for (i = 0; i < [alert numberOfButtons]; i++) {
        NSString *buttonTitle = [alert buttonTitleAtIndex:i];
        if ([buttonTitle isEqualToString:button0Title]) {
            index = i;
            break;
        }
    }
    
    if (index != -1) {
        [self alertView:alert clickedButtonAtIndex:index];
        [alert dismissWithClickedButtonIndex:index animated:YES];
    }
}

@end
