//
//  PortableAlertView
//
//
//  Created by Raf Cabezas on 2013.
//

typedef void (^PortableAlertViewBlock)();

typedef enum {
    PortableAlertViewStyleDefault = 0,
    PortableAlertViewStyleSecureTextInput,
    PortableAlertViewStylePlainTextInput,
    PortableAlertViewStyleLoginAndPasswordInput
    
} PortableAlertViewStyle;

typedef enum {
    PortableAlertViewKBTypeDefault = 0,
    PortableAlertViewKBTypeNumberPad,

} PortableAlertViewKBType;

typedef enum {
	PortableAlertViewPresentationStyleNone = 0,
	PortableAlertViewPresentationStylePop,
	PortableAlertViewPresentationStyleFade,
	PortableAlertViewPresentationStylePush
    
} PortableAlertViewPresentationStyle;

@interface PortableAlertView : NSObject
{
    NSString        *_title;
    NSString        *_message;
    BOOL             _visible;
    __unsafe_unretained id  _window;

    PortableAlertViewStyle  _alertViewStyle;
    PortableAlertViewKBType _kbtype;
    
    //Internal:
    id               _context;
    id               _okButton;
    id               _cancelButton;
    NSMutableArray  *_buttons;
    NSMutableArray  *_textFields;
    BOOL             _buttonClicked; //flag needed at least in iOS 7
}

@property (nonatomic, strong) id    context;

// This text is presented at the top of the alert view, if non-nil.
@property(nonatomic, copy) NSString *title;
// This text is presented below the title and above any other controls, if non-nil.
@property(nonatomic, copy) NSString *message;
// This property indicates whether the alert is currently displayed on the screen.
@property(nonatomic, readonly, assign, getter = isVisible) BOOL visible;
//
@property (nonatomic, assign) PortableAlertViewStyle alertViewStyle;
@property (nonatomic, assign) PortableAlertViewKBType kbtype;
//
@property (nonatomic, unsafe_unretained) id               window;
@property (nonatomic, strong) id               okButton;
@property (nonatomic, strong) id               cancelButton;
@property (nonatomic, strong) NSMutableArray  *buttons;
@property (nonatomic, strong) NSMutableArray  *textFields;
@property (nonatomic, assign) BOOL             buttonClicked;

// Designated initializer
- (id)initWithTitle:(NSString *)title message:(NSString *)message onWindow:(id)window;

// Use this method to add an arbitrary number of buttons to the alert view.
// The block, if present, will be invoked when the corresponding button is pressed.
- (void)addButtonWithTitle:(NSString *)title block:(PortableAlertViewBlock)block;
// Use this method to set the title and action for the cancel button,
// which may have a different visual style than a normal button
- (void)setCancelButtonBlock:(PortableAlertViewBlock)block;
- (void)setOKButtonBlock:(PortableAlertViewBlock)block;
// Show the alert with the current presentation style
- (void)show;
//
- (NSString *) textAtIndex:(NSInteger)textFieldIndex;

+ (BOOL) isUp; // Is any alert up?

@end
