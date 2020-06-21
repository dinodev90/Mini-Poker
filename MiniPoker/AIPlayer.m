//
//  AIPlayer.m
//  Mini-Poker
//
//  Created by Dinesh Kumar Vyas on 24/04/19.
//  Copyright © 2019 Dinesh Kumar Vyas. All rights reserved.
//

#import "AIPlayer.h"
#import "PokerHelper.h"
#import "AppDelegate.h"
#import "PokerController.h"

@interface AIPlayer()
@property(nonatomic, retain) PokerHelper*helper;
@property(nonatomic, retain) PokerController*controller;
@end

@implementation AIPlayer

- (instancetype)initWithPokerHelper:(PokerHelper*)helper pokerController:(PokerController*)controller {
	
	self = [super init];
	
	if (self) {
		_helper = helper;
		_controller = controller;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(betCallNotification:) name:@"betCallNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(betRaiseNotification:) name:@"betRaiseNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(betFoldNotification:) name:@"betFoldNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(betCheckNotification:) name:@"betCheckNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(betNotification:) name:@"betNotification" object:nil];
		
	}
	return self;
}
-(void)AIPlay {
	
	dispatch_async(dispatch_get_main_queue(), ^(void){
		self.controller.bottomBox.hidden = false;
	});
	
	if (_controller.isFinished) {
		return;
	}
	
	if (!_controller.isStarted) {
		[self betMinimum];
		_controller.isStarted = true;
	} else {
		
		AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
		
		if (app.totalCash == 0) {
			[self betCall];
		}else if((app.totalCash+[self betDiff]) <= _controller.lastBet && app.totalCash >= app.minBet){
			[self betAmount:app.totalCash + [self betDiff]];
		}else if((app.totalCash+[self betDiff]) <= _controller.lastBet && app.totalCash < app.minBet){
			[self betCall];
		}else if ([self betDiff] == 0) {
			[self bet:50];
		}else{
			[self betRaise:50];
		}
	}
}

-(long)betDiff{
	return MAX(_controller.currentBet, _currentBet) - MIN(_controller.currentBet, _currentBet);
}

-(void)betMinimum{
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	long bet = app.minBet;
	_currentBet += bet;
	[_controller AIStatusUpdate:[NSString stringWithFormat:@"Bet $%ld", bet]];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AIbetNotification" object:nil userInfo:@{@"bet":[NSString stringWithFormat:@"%ld", bet]}];
}

-(void)bet:(int)per{
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	long bet = app.minBet + (app.minBet*per/100.0);
	_currentBet += bet;
	[_controller AIStatusUpdate:[NSString stringWithFormat:@"Bet $%ld", bet]];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AIbetNotification" object:nil userInfo:@{@"bet":[NSString stringWithFormat:@"%ld", bet]}];
}

-(void)betAmount:(long)amount{
	long bet = amount;
	_currentBet += bet;
	[_controller AIStatusUpdate:[NSString stringWithFormat:@"Bet $%ld", bet]];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AIbetNotification" object:nil userInfo:@{@"bet":[NSString stringWithFormat:@"%ld", bet]}];
}

-(void)betCall{
	long bet = _controller.currentBet - _currentBet;
	_currentBet += bet;
	[_controller AIStatusUpdate:[NSString stringWithFormat:@"Called $%ld", _controller.lastBet]];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AIbetCallNotification" object:nil userInfo:@{@"bet":[NSString stringWithFormat:@"%ld", bet]}];
}

-(void)betRaise:(int)per{
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	
	long bet = app.minBetAmount + (app.minBetAmount*per/100.0);
	
	if(app.totalCash+[self betDiff] < bet){
		bet = app.totalCash + [self betDiff];
	}
	
	_currentBet += bet;
	[_controller AIStatusUpdate:[NSString stringWithFormat:@"Raised To $%ld", bet]];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AIbetRaiseNotification" object:nil userInfo:@{@"bet":[NSString stringWithFormat:@"%ld", bet]}];
}

-(void)betCheck{
	[_controller AIStatusUpdate:@"Checked"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AIbetCheckNotification" object:nil userInfo:nil];
}

-(void)betFold{
	_isFolded = true;
	[_controller AIStatusUpdate:@"Folded"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AIbetFoldNotification" object:nil userInfo:nil];
}

// MARK: Notifications

-(void)betCallNotification:(NSNotification*)notification{
	dispatch_async(dispatch_get_main_queue(), ^(void){
		self.controller.bottomBox.hidden = true;
	});
	[self performSelector:@selector(AIPlay) withObject:nil afterDelay:2];
}

-(void)betRaiseNotification:(NSNotification*)notification{
	dispatch_async(dispatch_get_main_queue(), ^(void){
		self.controller.bottomBox.hidden = true;
	});
	[self performSelector:@selector(AIPlay) withObject:nil afterDelay:2];
}

-(void)betFoldNotification:(NSNotification*)notification{
}

-(void)betCheckNotification:(NSNotification*)notification{
	dispatch_async(dispatch_get_main_queue(), ^(void){
		self.controller.bottomBox.hidden = true;
	});
	[self performSelector:@selector(AIPlay) withObject:nil afterDelay:2];
}

-(void)betNotification:(NSNotification*)notification{
	dispatch_async(dispatch_get_main_queue(), ^(void){
		self.controller.bottomBox.hidden = true;
	});
	[self performSelector:@selector(AIPlay) withObject:nil afterDelay:2];
}
@end
