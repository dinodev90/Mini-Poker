//
//  PokerHelper.h
//  Mini-Poker
//
//  Created by Dinesh Kumar Vyas on 24/04/19.
//  Copyright © 2019 Dinesh Kumar Vyas. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PokerHelper : NSObject
@property(nonatomic, retain) NSMutableArray*playerCards;
@property(nonatomic, retain) NSMutableArray*boardCards;
-(instancetype)initWithPlayers:(int) players;
-(void)throughCards;
-(void)reset;
-(void)openFirstCut;
-(void)openSecondCut;
-(void)openFinalCut;
-(NSArray*)compareResults;
@end

NS_ASSUME_NONNULL_END
