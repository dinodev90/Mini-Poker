//
//  BetSliderController.m
//  Mini-Poker
//
//  Created by Dinesh Kumar Vyas on 24/04/19.
//  Copyright © 2019 Dinesh Kumar Vyas. All rights reserved.
//

#import "BetSliderController.h"
#import "AppDelegate.h"

@interface BetSliderController ()
@property(nonatomic, retain) IBOutlet NSSlider*slider;
@property(nonatomic, retain) IBOutlet NSTextField*amount;
@property(nonatomic, retain) IBOutlet NSButton*confirmButton;
@property(nonatomic, retain) IBOutlet NSButton*plusButton;
@property(nonatomic, retain) IBOutlet NSButton*minusButton;
@end

@implementation BetSliderController

- (void)viewDidLoad {
	[super viewDidLoad];
}

-(void)viewDidAppear{
	[super viewDidAppear];
	[self setup];
}

-(IBAction)allInAction:(id)sender{
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"betConfirmNotification" object:nil userInfo:@{@"bet":[NSString stringWithFormat:@"%ld", app.totalCash]}];
	[self dismissController:self];
}

-(IBAction)confirmAction:(id)sender{
	NSString*mx = [NSString stringWithFormat:@"%ld", (long)[_slider integerValue]];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"betConfirmNotification" object:nil userInfo:@{@"bet":mx}];
	[self dismissController:self];
}

-(IBAction)cancelAction:(id)sender{
	[self dismissController:self];
}

-(IBAction)plus:(id)sender{
	_slider.integerValue = _slider.integerValue + 1;
	
	NSString*mx = [NSString stringWithFormat:@"$%ld", (long)[_slider integerValue]];
	_amount.stringValue = mx;
	_minusButton.enabled = true;
	
	if (_slider.doubleValue == _slider.maxValue) {
		_plusButton.enabled = false;
	}
}

-(IBAction)minus:(id)sender{
	_slider.integerValue = _slider.integerValue - 1;

	NSString*mx = [NSString stringWithFormat:@"$%ld", (long)[_slider integerValue]];
	_amount.stringValue = mx;
	_plusButton.enabled = true;
	if (_slider.doubleValue == _slider.minValue) {
		_minusButton.enabled = false;
	}
}

-(void)setup{
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	long betAmount = (app.minBet > app.minBetAmount) ? app.minBet : app.minBetAmount;
	_slider.minValue = betAmount;
	_slider.maxValue = app.totalCash;
	_amount.stringValue = [NSString stringWithFormat:@"$%ld", betAmount];
	_slider.integerValue = betAmount;
	_minusButton.enabled = false;
}

-(IBAction)valueChanged:(id)sender{
	NSString*mx = [NSString stringWithFormat:@"$%ld", (long)[(NSSlider*)sender integerValue]];
	_amount.stringValue = mx;
	if (_slider.doubleValue == _slider.minValue) {
		_minusButton.enabled = false;
	}else{
		_minusButton.enabled = true;
	}
}
@end
