//
//  PokerController.m
//  Mini-Poker
//
//  Created by Dinesh Kumar Vyas on 24/04/19.
//  Copyright © 2019 Dinesh Kumar Vyas. All rights reserved.
//

#import "PokerController.h"
#import "PokerHelper.h"
#import "CardViewController.h"
#import "AppDelegate.h"
#import "AIPlayer.h"

#define CARD_SIDE_WIDTH 26

#define MIN_BID 10

@interface PokerController ()

@property(nonatomic, retain) IBOutlet NSLayoutConstraint*plWidth;
@property(nonatomic, retain) IBOutlet NSLayoutConstraint*dlWidth;
@property(nonatomic, retain) IBOutlet NSLayoutConstraint*bdWidth;
@property(nonatomic, retain) IBOutlet NSBox*plContainer;
@property(nonatomic, retain) IBOutlet NSBox*dlContainer;
@property(nonatomic, retain) IBOutlet NSBox*bdContainer;
@property(nonatomic, retain) IBOutlet NSTextField*bid;
@property(nonatomic, retain) IBOutlet NSTextField*cash;
@property(nonatomic, retain) IBOutlet NSButton*raiseBtn;
@property(nonatomic, retain) IBOutlet NSButton*foldBtn;
@property(nonatomic, retain) IBOutlet NSButton*callBtn;
@property(nonatomic, retain) IBOutlet NSButton*betBtn;
@property(nonatomic, retain) IBOutlet NSButton*checkBtn;
@property(nonatomic, retain) IBOutlet NSBox*dlDealerBox;
@property(nonatomic, retain) IBOutlet NSBox*pldealerBox;
@property(nonatomic, retain) IBOutlet NSBox*dlStatusBox;
@property(nonatomic, retain) IBOutlet NSBox*plStatusBox;
@property(nonatomic, retain) IBOutlet NSBox*nextGameBox;
@property(nonatomic, retain) IBOutlet NSTextField*dlStatusText;
@property(nonatomic, retain) IBOutlet NSTextField*plStatusText;

@property(nonatomic, retain) NSMutableArray*pCards;
@property(nonatomic, retain) NSMutableArray*dCards;
@property(nonatomic, retain) NSMutableArray*bCards;
@property(nonatomic, retain) AIPlayer*aiPlayer;
@property(nonatomic, retain) NSTimer*aiStatusT;
@property(nonatomic, retain) NSTimer*plStatusT;
@property(nonatomic, retain) PokerHelper*ph;

@property(nonatomic) int cardsOpened;
@property(nonatomic) long betAmount;
@property(nonatomic) int dealer;
@property(nonatomic) int lastDealer;
@property(nonatomic) int lastCall;
@property(nonatomic) long opener;

@end

@implementation PokerController

- (void)viewDidLoad {
	[super viewDidLoad];
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	app.totalCash = 1000;
	_lastDealer = -1;
	
	_ph = [[PokerHelper alloc] initWithPlayers:1];
	[self start];
	_dealer = 0;
	_betAmount = 0;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(betConfirmNotification:) name:@"betConfirmNotification" object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AIbetCallNotification:) name:@"AIbetCallNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AIbetRaiseNotification:) name:@"AIbetRaiseNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AIbetFoldNotification:) name:@"AIbetFoldNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AIbetCheckNotification:) name:@"AIbetCheckNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AIbetNotification:) name:@"AIbetNotification" object:nil];
}

-(long)betDiff{
	return MAX(_aiPlayer.currentBet, _currentBet) - MIN(_aiPlayer.currentBet, _currentBet);
}

-(void)AIbetCallNotification:(NSNotification*)notification{
	long bet = [[notification.userInfo valueForKey:@"bet"] intValue];
	_betAmount += bet;
	_lastBet = bet;
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	app.minBetAmount = 0;
	dispatch_async(dispatch_get_main_queue(), ^(void){
		[self playerBtnUpdate];
		[self updateCash];
		[self results];
	});
}

-(void)AIbetRaiseNotification:(NSNotification*)notification{
	long bet = [[notification.userInfo valueForKey:@"bet"] intValue];
	_betAmount += bet;
	_lastBet = bet;
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	app.minBetAmount = _lastBet;
	dispatch_async(dispatch_get_main_queue(), ^(void){
		[self playerBtnUpdate];
		[self updateCash];
	});
}

-(void)AIbetFoldNotification:(NSNotification*)notification{
	dispatch_async(dispatch_get_main_queue(), ^(void){
		[self playerBtnUpdate];
		[self updateCash];
		//[self results];
	});
}

-(void)AIbetCheckNotification:(NSNotification*)notification{
	_lastBet = 0;
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	app.minBetAmount = 0;
	dispatch_async(dispatch_get_main_queue(), ^(void){
		[self playerBtnUpdate];
		[self updateCash];
	});
}

-(void)AIbetNotification:(NSNotification*)notification{
	long bet = [[notification.userInfo valueForKey:@"bet"] intValue];
	_betAmount += bet;
	_lastBet = bet;
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	app.minBetAmount = [self betDiff];
	dispatch_async(dispatch_get_main_queue(), ^(void){
		[self playerBtnUpdate];
		[self updateCash];
	});
}

-(void)betConfirmNotification:(NSNotification*)notification{
	long bet = [[notification.userInfo valueForKey:@"bet"] intValue];
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	
	if(bet == app.minBetAmount){
		dispatch_async(dispatch_get_main_queue(), ^(void){
			[self callAction:self];
		});
		return;
	}
	_currentBet += bet;
	_betAmount += bet;
	app.totalCash -= bet;
	NSString*type = @"Bet";
	if (!_isStarted || [self betDiff] == 0) {
		_isStarted = true;
		_lastBet = bet;
		AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
		app.minBetAmount = _lastBet;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"betNotification" object:nil userInfo:notification.userInfo];
	}else{
		type = @"Raised To";
		_lastBet = bet;
		AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
		app.minBetAmount = _lastBet;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"betRaiseNotification" object:nil userInfo:notification.userInfo];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^(void){
		[self updateCash];
		
		[self playerStatusUpdate:[NSString stringWithFormat:@"%@ $%ld", type, bet]];
	});
}

-(void)updateCash{
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	_cash.stringValue = [NSString stringWithFormat:@"$%ld", app.totalCash];
	_bid.stringValue = [NSString stringWithFormat:@"$%ld", _betAmount];
}

-(void)start{
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	app.minBet = MIN_BID;
	app.minBetAmount = 0;
	_nextGameBox.hidden = true;
	_isFinished = false;
	_cardsOpened = 0;
	_lastCall = 0;
	_isStarted = false;
	_betDiff = 0;
	_betAmount = 0;
	_raiseBtn.hidden = false;
	_foldBtn.hidden = false;
	_callBtn.hidden = false;
	
	_raiseBtn.enabled = true;
	_betBtn.enabled = true;
	
	_currentBet = 0;
	
	if (_lastDealer != -1) {
		if (_lastDealer == 0) {
			_dealer = 1;
		}else{
			_dealer = 0;
		}
	}
	
	if (_dealer == 0) {
		_dlDealerBox.hidden = false;
		_pldealerBox.hidden = true;
		_opener = 0;
	}else{
		_dlDealerBox.hidden = true;
		_pldealerBox.hidden = false;
		_opener = 1;
	}
	
	_lastDealer = _dealer;
	
	_pCards = [[NSMutableArray alloc] init];
	_dCards = [[NSMutableArray alloc] init];
	_bCards = [[NSMutableArray alloc] init];
	
	_dlStatusBox.hidden = true;
	_plStatusBox.hidden = true;
	
	_aiPlayer = nil;
	_aiPlayer = [[AIPlayer alloc] initWithPokerHelper:_ph pokerController:self];
	
	[self updateCash];
	
	NSOperationQueue*q = [[NSOperationQueue alloc] init];
	[q addOperationWithBlock:^{
		[self.ph reset];
		[self.ph throughCards];
		dispatch_async(dispatch_get_main_queue(), ^(void){
			[self updatePlayerCards];
			[self updateDealerCards];
			[self updateBoardCards];
			[self checkPlayCall];
		});
	}];
}

-(void)checkPlayCall{
	if (!_isStarted) {
		if (_dealer == 0) {
			[_aiPlayer AIPlay];
		}else{
			[self playerBtnUpdate];
		}
	}
}

-(void)playerPlay{
	
}

-(void)playerBtnUpdate{
	if (_opener == 1 || _lastBet == 0) {
		_checkBtn.hidden = false;
	}else{
		_checkBtn.hidden = true;
	}
	
	if ([self betDiff] > 0 && _opener == 1) {
		_checkBtn.hidden = true;
	}else if([self betDiff] == 0 && _opener == 1) {
		_checkBtn.hidden = false;
	}
	
	if (!_isStarted || [self betDiff] == 0) {
		_betBtn.hidden = false;
		_raiseBtn.hidden = true;
		_callBtn.enabled = false;
	}else{
		_betBtn.hidden = true;
		_raiseBtn.hidden = false;
		_callBtn.enabled = true;
	}
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	if (app.totalCash <= _lastBet) {
		_raiseBtn.enabled = false;
	}
}

-(void)removeCards:(NSArray*)cards{
	for(id card in cards){
		[card removeFromParentViewController];
	}
}

-(void)updatePlayerCards{
	[self removeCards:_pCards];
	[_pCards removeAllObjects];
	for(NSString*c in [_ph.playerCards objectAtIndex:1]){
		[self addPlayerCard:c];
	}
	[self drawPlayerCards];
}

-(void)updateDealerCards{
	[self removeCards:_dCards];
	[_dCards removeAllObjects];
	for(NSString*c in [_ph.playerCards objectAtIndex:0]){
		[self addDealerCard:c];
	}
	[self drawDealerCards];
}

-(void)updateBoardCards{
	[self removeCards:_bCards];
	[_bCards removeAllObjects];
	for(NSString*c in _ph.boardCards){
		[self addBoardCard:c];
	}
	[self drawBoardCards];
}

-(void)drawPlayerCards{
	CGFloat sw = CARD_SIDE_WIDTH;
	CGFloat pw = ((_pCards.count - 1) * sw) + 69;
	_plWidth.constant = pw;
	
	CGFloat x = 0;
	for(CardViewController*card in _pCards){
		[_plContainer.contentView addSubview:card.view];
		card.view.frame = CGRectMake(x, 0, 69, 100);
		[card showCard];
		x += sw;
	}
}

-(void)drawDealerCards{
	CGFloat sw = CARD_SIDE_WIDTH;
	CGFloat pw = ((_dCards.count - 1) * sw) + 69;
	_dlWidth.constant = pw;
	
	CGFloat x = 0;
	for(CardViewController*card in _dCards){
		[_dlContainer.contentView addSubview:card.view];
		card.view.frame = CGRectMake(x, 0, 69, 100);
		if (_isFinished) {
			[card showCard];
		}
		x += sw;
	}
}

-(void)drawBoardCards{
	for(NSView*v in _bdContainer.contentView.subviews.reverseObjectEnumerator){
		[v removeFromSuperview];
	}
	if (_bCards.count == 0) {
		return;
	}
	CGFloat sw = CARD_SIDE_WIDTH;
	CGFloat pw = ((_bCards.count - 1) * sw) + 69;
	_bdWidth.constant = pw;
	
	CGFloat x = 0;
	for(CardViewController*card in _bCards){
		[_bdContainer.contentView addSubview:card.view];
		card.view.frame = CGRectMake(x, 0, 69, 100);
		[card showCard];
		x += sw;
	}
}

-(void)addPlayerCard:(NSString*)c{
	CardViewController*card = [self getCard:c];
	[_pCards addObject:card];
	[self addChildViewController:card];
}

-(void)addDealerCard:(NSString*)c{
	CardViewController*card = [self getCard:c];
	[_dCards addObject:card];
	[self addChildViewController:card];
}

-(void)addBoardCard:(NSString*)c{
	CardViewController*card = [self getCard:c];
	[_bCards addObject:card];
	[self addChildViewController:card];
}

-(CardViewController*)getCard:(NSString*)c{
	NSStoryboard *sb = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
	CardViewController*card = [sb instantiateControllerWithIdentifier:@"CardViewController"];
	card.card = c;
	return card;
}

-(IBAction)callAction:(id)sender{
	long bet = [self betDiff];
	_currentBet += bet;
	_betAmount += bet;
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	_lastBet = bet;
	app.totalCash -= bet;
	[self playerStatusUpdate:[NSString stringWithFormat:@"Called $%ld", _lastBet]];
	[self openBoardCards];
	[self updateCash];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"betCallNotification" object:nil userInfo:nil];
}

-(IBAction)foldAction:(id)sender{
	_isFinished = true;
	[self playerStatusUpdate:@"Folded"];
	[self lost:@"Folded"];
	[self finish];
}

-(IBAction)checkAction:(id)sender{
	[self playerStatusUpdate:@"Checked"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"betCheckNotification" object:nil userInfo:nil];
}

-(IBAction)raiseAction:(id)sender{
	[self results];
}

-(IBAction)betAction:(id)sender{
	[self results];
}

-(void)results{
	_isFinished = true;
	
	NSLog(@"Total Pot = %ld", _betAmount);
	NSLog(@"P0 Bet = %ld", _aiPlayer.currentBet);
	NSLog(@"P1 Bet = %ld", _currentBet);
	
	if (_aiPlayer.isFolded) {
		[self won:@"Folded"];
		[self finish];
		return;
	}
	[self updateDealerCards];
	NSArray*pstates = [_ph compareResults];
	NSArray*pwon = [pstates firstObject];
	NSString*rule = [pstates lastObject];
	
	if (pwon.count == 1) {
		if ([[pwon firstObject] isEqualToString:@"1"]) {
			[self won:rule];
		}else{
			[self lost:rule];
		}
		NSLog(@"Player %@ Won with [ %@ ]", [pwon firstObject], rule);
	}else{
		NSArray*spwon = [pwon firstObject];
		NSString*srule = [pwon lastObject];
		
		if (spwon.count == 1) {
			if ([[spwon firstObject] isEqualToString:@"1"]) {
				[self won:rule];
			}else{
				[self lost:rule];
			}
			NSLog(@"Player %@ Won with [ %@ + %@ ]", [spwon firstObject], rule, srule);
		}else{
			[self tie:rule];
			NSLog(@"Tie with [ %@ + %@ ] -", rule, srule);
			for(NSString*p in spwon){
				NSLog(@"Player %@", p);
			}
		}
	}
	[self finish];
}

-(void)finish{
	[self updateCash];
}

-(NSString*)getRuleName:(NSString*)rule{
	NSDictionary*rules = @{
		@"RoyalFlush" : @"Royal Flush",
		@"StraitFlush" : @"Strait Flush",
		@"FourOfAKing" : @"Four of a Kind",
		@"FullHouse" : @"Full House",
		@"Flush" : @"Flush",
		@"Strait" : @"Strait",
		@"ThreeOfAKind" : @"Three of a Kind",
		@"TwoPair" : @"Two Pair",
		@"OnePair" : @"One Pair",
		@"HandCards" : @"High Card",
		@"Folded" : @"Opponent Folded"
	};
	return [rules valueForKey:rule];
}

-(void)won:(NSString*)rule{
	_bottomBox.hidden = true;
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	app.totalCash += _betAmount;
	_betAmount = 0;
	[self playerStatusUpdate:[NSString stringWithFormat:@"Won [%@]", [self getRuleName:rule]]];
	[self performSelector:@selector(nextGameScreen) withObject:nil afterDelay:4];
}

-(void)tie:(NSString*)rule{
	_bottomBox.hidden = true;
	_betAmount = 0;
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	app.totalCash += (_betAmount/2);
	[self playerStatusUpdate:[NSString stringWithFormat:@"Tie [%@]", [self getRuleName:rule]]];
	[self AIStatusUpdate:[NSString stringWithFormat:@"Tie [%@]", [self getRuleName:rule]]];
	[self performSelector:@selector(nextGameScreen) withObject:nil afterDelay:4];
}

-(void)lost:(NSString*)rule{
	_bottomBox.hidden = true;
	_betAmount = 0;
	[self AIStatusUpdate:[NSString stringWithFormat:@"Won [%@]", [self getRuleName:rule]]];
	[self performSelector:@selector(nextGameScreen) withObject:nil afterDelay:4];
}

-(void)nextGameScreen{
	_nextGameBox.hidden = false;
}

-(IBAction)newGameAction:(id)sender{
	AppDelegate*app = (AppDelegate*)[NSApplication sharedApplication].delegate;
	if (app.totalCash >= MIN_BID) {
		[self start];
		_bottomBox.hidden = false;
	}else{
		NSAlert*alert = [[NSAlert alloc] init];
		
		alert.informativeText = @"Error";
		alert.messageText  = @"Not enough money to play.";
		alert.alertStyle = NSAlertSecondButtonReturn;
		[alert addButtonWithTitle:@"Ok"];
		
		[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
			
		}];
	}
}

-(BOOL)openBoardCards{
	switch (_cardsOpened) {
		case 0:
			[_ph openFirstCut];
			break;
		case 1:
			[_ph openSecondCut];
			break;
		case 2:
			[_ph openFinalCut];
			break;
		default:
			[self results];
	}
	[self updateBoardCards];
	_cardsOpened++;
	return true;
}

-(void)playerStatusUpdate:(NSString*)status{
	if (![status hasPrefix:@"Tie"]) {
		self.dlStatusBox.hidden = true;
	}
	
	_plStatusBox.hidden = false;
	_plStatusText.stringValue = status;
}

-(void)AIStatusUpdate:(NSString*)status{
	if (![status hasPrefix:@"Tie"]) {
		self.plStatusBox.hidden = true;
	}
	
	_dlStatusBox.hidden = false;
	_dlStatusText.stringValue = status;
}

-(void)hidePStatus{
	self.plStatusBox.hidden = true;
	[_plStatusT invalidate];
}

-(void)hideAIStatus{
	self.dlStatusBox.hidden = true;
	[_aiStatusT invalidate];
}

@end
