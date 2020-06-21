//
//  AIPlayer.h
//  Mini-Poker
//
//  Created by Dinesh Kumar Vyas on 24/04/19.
//  Copyright © 2019 Dinesh Kumar Vyas. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PokerHelper, PokerController;

NS_ASSUME_NONNULL_BEGIN

@interface AIPlayer : NSObject
@property(nonatomic) BOOL isFolded;
@property(nonatomic) long currentBet;

-(instancetype)initWithPokerHelper:(PokerHelper*)helper pokerController:(PokerController*)controller;
-(void)AIPlay;
@end

NS_ASSUME_NONNULL_END
