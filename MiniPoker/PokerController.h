//
//  PokerController.h
//  Mini-Poker
//
//  Created by Dinesh Kumar Vyas on 24/04/19.
//  Copyright © 2019 Dinesh Kumar Vyas. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PokerController : NSViewController

@property(nonatomic) long betDiff;
@property(nonatomic) long lastBet;
@property(nonatomic) long currentBet;
@property(nonatomic) BOOL isStarted;
@property(nonatomic) BOOL isFinished;
@property(nonatomic, retain) IBOutlet NSBox*bottomBox;

-(void)AIStatusUpdate:(NSString*)status;

@end

NS_ASSUME_NONNULL_END
