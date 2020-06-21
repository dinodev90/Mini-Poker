//
//  PokerHelper.m
//  Mini-Poker
//
//  Created by Dinesh Kumar Vyas on 24/04/19.
//  Copyright © 2019 Dinesh Kumar Vyas. All rights reserved.
//

#import "PokerHelper.h"
#import "CardsHelper.h"

#define MIN_CARDS 20

@interface PokerHelper()
@property(nonatomic, retain) CardsHelper*cardsHelper;
@property(nonatomic, retain) NSMutableArray*cards;
@property(nonatomic) int players;
@end

@implementation PokerHelper

- (instancetype)initWithPlayers:(int) players {
	self = [super init];
	
	if (self) {
		_cardsHelper = [[CardsHelper alloc] init];
		_players = players;
		[self shuffle];
		[self reset];
	}
	
	return self;
}

- (void)reset {
	_playerCards = [[NSMutableArray alloc] init];
	_boardCards = [[NSMutableArray alloc] init];
}

- (void)shuffle {
	_cards = [NSMutableArray arrayWithArray:[_cardsHelper shuffle]];
}

- (void)throughCards {
	if (_cards.count < MIN_CARDS) {
		[_cards addObjectsFromArray:[_cardsHelper shuffle]];
	}
	
	for (int i=0; i<_players+1; i++) {
		NSMutableArray*pc = [[NSMutableArray alloc] init];
		[pc addObject:[self serveCard]];
		[_playerCards addObject:pc];
	}
	
	for (int i=0; i<_players+1; i++) {
		[[_playerCards objectAtIndex:i] addObject:[self serveCard]];
	}
}

- (NSString*)serveCard {
	NSString*c = [_cards firstObject];
	[_cards removeObjectAtIndex:0];
	return c;
}
- (void)openFirstCut {
	[self serveCard];
	[_boardCards addObject:[self serveCard]];
	[_boardCards addObject:[self serveCard]];
	[_boardCards addObject:[self serveCard]];
}
- (void)openSecondCut {
	[self serveCard];
	[_boardCards addObject:[self serveCard]];
}
- (void)openFinalCut {
	[self serveCard];
	[_boardCards addObject:[self serveCard]];
}

- (NSArray*)compareResults {
	NSArray*results = [self getStatus];
	NSArray*prRules = @[@"RoyalFlush", @"StraitFlush", @"FourOfAKing", @"FullHouse", @"Flush", @"Strait", @"ThreeOfAKind", @"TwoPair", @"OnePair", @"HandCards"];
	
	for(NSString*rule in prRules) {
		NSMutableArray*plistForRule = [[NSMutableArray alloc] init];
		
		for(int i=0; i<_players+1; i++){
			NSDictionary*pstat = [results objectAtIndex:i];
			if ([pstat valueForKey:rule] != nil) {
				[plistForRule addObject:[NSString stringWithFormat:@"%i", i]];
			}
		}
		
		if (plistForRule.count == 1) {
			return @[@[[plistForRule firstObject]], rule];
		}else if (plistForRule.count > 1) {
			return @[[self tieBracker:results rule:rule players:plistForRule], rule];
		}
	}
	
	return 0;
}

- (NSArray*)tieBracker:(NSArray*)results rule:(NSString*)rule players:(NSArray*)players {
	if ([rule isEqualToString:@"HandCards"]) {
		return [self checkHighCards:results players:players];
	} else {
		return [self biggerCards:results rule:rule players:players];
	}
	
}

- (NSArray*)biggerCards:(NSArray*)results rule:(NSString*)rule players:(NSArray*)players {
	NSMutableArray*ttl = [[NSMutableArray alloc] init];
	NSMutableDictionary*ttl_p = [[NSMutableDictionary alloc] init];
	
	for (NSString*p in players) {
		int index = [p intValue];
		NSArray*crds = [[results objectAtIndex:index] valueForKey:rule];
		long cttl = 0;
		
		for(NSString*cv in crds) {
			if ([cv intValue] == 1) {
				cttl += 14;
			}else{
				cttl += [cv intValue];
			}
		}
		
		NSMutableArray*ps;
		
		if ([ttl_p valueForKey:[NSString stringWithFormat:@"%ld", cttl]] == nil) {
			ps = [[NSMutableArray alloc] init];
			[ttl_p setValue:ps forKey:[NSString stringWithFormat:@"%ld", cttl]];
		}else{
			ps = [ttl_p valueForKey:[NSString stringWithFormat:@"%ld", cttl]];
		}
		
		[ps addObject:p];
		[ttl addObject:[NSNumber numberWithLong:cttl]];
	}
	
	NSArray*stl = [ttl sortedArrayUsingSelector: @selector(compare:)];
	NSMutableArray*eqs = [[NSMutableArray alloc] init];
	
	[eqs addObjectsFromArray:[ttl_p valueForKey:[[stl lastObject] stringValue]]];
	
	if (eqs.count == 1) {
		return @[@[[eqs firstObject]], @"BiggerCards"];
	}else if (eqs.count > 1) {
		return [self checkHighCards:results players:eqs];
	}
	
	return nil;
}

- (NSArray*)checkHighCards:(NSArray*)results players:(NSArray*)players {
	NSMutableDictionary*deck = [[NSMutableDictionary alloc] init];
	NSMutableArray*cards = [[NSMutableArray alloc] init];
	
	for(NSString*p in players){
		int index = [p intValue];
		NSArray*crds = [[results objectAtIndex:index] valueForKey:@"HandCards"];
		
		for(NSString*c in crds){
			NSString*tv = c;
			
			if([tv isEqualToString:@"1"]){
				tv = @"14";
			}
			
			[cards addObject:[NSNumber numberWithInt:[tv intValue]]];
			NSMutableArray*prt;
			
			if ([deck valueForKey:tv] == nil) {
				prt = [[NSMutableArray alloc] init];
				[deck setValue:prt forKey:tv];
			}else{
				prt = [deck valueForKey:tv];
			}
			
			[prt addObject:p];
		}
	}
	
	NSArray*stl = [cards sortedArrayUsingSelector: @selector(compare:)];
	
	for(NSNumber*v in stl.reverseObjectEnumerator){
		NSArray*pa = [deck valueForKey:[v stringValue]];
		
		if (pa.count == 1) {
			return @[@[[pa firstObject]], @"HighCards"];
		}
	}
	
	return @[players, @"HighCards"];
}

- (NSArray*)getStatus {
	NSMutableArray*statusArray = [[NSMutableArray alloc] init];
	
	for(NSArray*cs in _playerCards){
		
		NSMutableDictionary*pstate = [[NSMutableDictionary alloc] init];
		
		if ([self isRoyalFlush:cs]) {
			[pstate setValue:@"Yes" forKey:@"RoyalFlush"];
		}
		
		NSArray*StraitFlush = [self isStraitFlush:cs];
		
		if (StraitFlush != nil) {
			[pstate setValue:StraitFlush forKey:@"StraitFlush"];
		}
		
		NSArray*FourOfAKing = [self isFourOfAKing:cs];
		
		if (FourOfAKing != nil) {
			[pstate setValue:FourOfAKing forKey:@"FourOfAKing"];
		}
		
		NSArray*FullHouse = [self isFullHouse:cs];
		
		if (FullHouse != nil) {
			[pstate setValue:FullHouse forKey:@"FullHouse"];
		}
		
		NSArray*Flush = [self isFlush:cs];
		
		if (Flush != nil) {
			[pstate setValue:Flush forKey:@"Flush"];
		}
		
		NSArray*Strait = [self isStrait:cs];
		
		if (Strait != nil) {
			[pstate setValue:Strait forKey:@"Strait"];
		}
		
		NSArray*ThreeOfAKind = [self isThreeOfAKind:cs];
		
		if (ThreeOfAKind != nil) {
			[pstate setValue:ThreeOfAKind forKey:@"ThreeOfAKind"];
		}
		
		NSArray*TwoPair = [self isTwoPair:cs];
		
		if (TwoPair != nil) {
			[pstate setValue:TwoPair forKey:@"TwoPair"];
		}
		
		NSArray*OnePair = [self isOnePair:cs];
		
		if (OnePair != nil) {
			[pstate setValue:OnePair forKey:@"OnePair"];
		}
		
		NSArray*HandCards = [self isHandCards:cs];
		[pstate setValue:HandCards forKey:@"HandCards"];
		
		[statusArray addObject:pstate];
	}
	
	return statusArray;
}

- (NSMutableArray*)getPCards:(NSArray*)pc {
	NSMutableArray*cs = [NSMutableArray arrayWithArray:pc];
	[cs addObjectsFromArray:_boardCards];
	return cs;
}

- (BOOL)isRoyalFlush:(NSArray*)pc {
	NSMutableArray*cs = [self getPCards:pc];
	
	if (cs.count >= 5) {
		NSMutableDictionary*ts = [[NSMutableDictionary alloc] init];
		
		for(NSString*c in cs){
			NSString*t = [c substringToIndex:1];
			NSMutableArray*carr;
			if ([ts valueForKey:t] == nil) {
				carr = [[NSMutableArray alloc] init];
			}else{
				carr = [ts valueForKey:t];
			}
			[carr addObject:[c substringFromIndex:1]];
			[ts setValue:carr forKey:t];
		}
		
		for(NSString*t in ts.allKeys){
			long tc = [[ts valueForKey:t] count];
			
			if (tc >= 5) {
				BOOL irf = true;
				
				for(NSString*c in [ts valueForKey:t]){
					int cv = [c intValue];
					if (!(cv == 1 || (cv <=13 && cv >=10))) {
						irf = false;
					}
				}
				
				return irf;
			}
		}
	}
	
	return false;
}

- (NSArray*)isStraitFlush:(NSArray*)pc {
	NSMutableArray*cs = [self getPCards:pc];
	
	if (cs.count >= 5) {
		NSMutableDictionary*ts = [[NSMutableDictionary alloc] init];
		
		for(NSString*c in cs){
			NSString*t = [c substringToIndex:1];
			NSMutableArray*carr;
			
			if ([ts valueForKey:t] == nil) {
				carr = [[NSMutableArray alloc] init];
			}else{
				carr = [ts valueForKey:t];
			}
			
			[carr addObject:[NSNumber numberWithInt:[[c substringFromIndex:1] intValue]]];
			[ts setValue:carr forKey:t];
		}
		
		for(NSString*t in ts.allKeys){
			long tc = [[ts valueForKey:t] count];
			
			if (tc >= 5) {
				NSArray*array = [[ts valueForKey:t] sortedArrayUsingSelector: @selector(compare:)];
				
				if ([[array lastObject] intValue] - [[array firstObject] intValue] == 5) {
					return array;
				}
			}
		}
	}
	
	return nil;
}

- (NSArray*)isFourOfAKing:(NSArray*)pc {
	NSMutableArray*cs = [self getPCards:pc];
	
	if (cs.count >= 4) {
		NSMutableDictionary*ts = [[NSMutableDictionary alloc] init];
		
		for(NSString*c in cs){
			NSString*t = [c substringFromIndex:1];
			int tc = 0;
			
			if ([ts valueForKey:t] != nil) {
				tc = [[ts valueForKey:t] intValue];
			}
			
			tc++;
			[ts setValue:[NSNumber numberWithInteger:tc] forKey:t];
		}
		
		for(NSString*t in ts.allKeys){
			int tc = [[ts valueForKey:t] intValue];
			if (tc >= 4) {
				return @[t];
			}
		}
	}
	
	return nil;
}

- (NSArray*)isFullHouse:(NSArray*)pc {
	NSMutableArray*cs = [self getPCards:pc];
	
	if (cs.count >= 5) {
		BOOL trk = false;
		BOOL twk = false;
		NSMutableDictionary*ts = [[NSMutableDictionary alloc] init];
		
		for(NSString*c in cs){
			NSString*t = [c substringFromIndex:1];
			int tc = 0;
			if ([ts valueForKey:t] != nil) {
				tc = [[ts valueForKey:t] intValue];
			}
			tc++;
			[ts setValue:[NSNumber numberWithInteger:tc] forKey:t];
		}
		
		NSString *lt = @"";
		NSString*trk_v;
		NSString*twk_v;
		
		for(NSString*t in ts.allKeys){
			int tc = [[ts valueForKey:t] intValue];
			
			if (tc >= 3 && ![lt isEqualToString:t] && trk == false) {
				trk = true;
				trk_v = t;
				lt = t;
			}
			
			if (tc >= 2 && ![lt isEqualToString:t] && twk == false) {
				twk = true;
				twk_v = t;
				lt = t;
			}
		}
		
		if (trk == true && twk == true) {
			return @[trk_v, twk_v];
		}
	}
	
	return nil;
}

- (NSArray*)isFlush:(NSArray*)pc {
	NSMutableArray*cs = [self getPCards:pc];
	
	if (cs.count >= 5) {
		NSMutableDictionary*ts = [[NSMutableDictionary alloc] init];
		
		for(NSString*c in cs){
			NSString*t = [c substringToIndex:1];
			int tc = 0;
			if ([ts valueForKey:t] != nil) {
				tc = [[ts valueForKey:t] intValue];
			}
			tc++;
			[ts setValue:[NSNumber numberWithInteger:tc] forKey:t];
		}
		
		for(NSString*t in ts.allKeys){
			int tc = [[ts valueForKey:t] intValue];
			
			if (tc >= 5) {
				NSMutableArray*cards = [[NSMutableArray alloc] init];
				
				for(NSString*c in cs){
					NSString*ty = [c substringToIndex:1];
					if ([ty isEqualToString:t]) {
						[cards addObject:[c substringFromIndex:1]];
					}
				}
				
				return cards;
			}
		}
	}
	
	return nil;
}

- (NSArray*)isStrait:(NSArray*)pc {
	NSMutableArray*cs = [self getPCards:pc];
	
	if (cs.count >= 5) {
		
		NSMutableArray *tcs = [[NSMutableArray alloc] init];
		
		for(NSString*c in cs){
			[tcs addObject:[NSNumber numberWithInteger:[[c substringFromIndex:1] intValue]]];
		}
		
		int lv = 0;
		int f = 0;
		NSArray*scs = [tcs sortedArrayUsingSelector: @selector(compare:)];
		NSMutableArray*cards = [[NSMutableArray alloc] init];
		
		for(NSString*c in scs){
			int v = [c intValue];
			
			if (lv != 0) {
				if (v - lv != 1 && v - lv != 0) {
					f = 0;
				}
			}
			
			if(v - lv != 0){
				[cards addObject:c];
				f++;
			}
			
			lv = v;
		}
		
		if (f >= 5) {
			return cards;
		}
	}
	
	return nil;
}

- (NSArray*)isThreeOfAKind:(NSArray*)pc {
	NSMutableArray*cs = [self getPCards:pc];
	
	if (cs.count >= 3) {
		
		NSMutableDictionary*ts = [[NSMutableDictionary alloc] init];
		
		for(NSString*c in cs){
			NSString*t = [c substringFromIndex:1];
			int tc = 0;
			if ([ts valueForKey:t] != nil) {
				tc = [[ts valueForKey:t] intValue];
			}
			tc++;
			[ts setValue:[NSNumber numberWithInteger:tc] forKey:t];
		}
		
		for(NSString*t in ts.allKeys){
			int tc = [[ts valueForKey:t] intValue];
			if (tc >= 3) {
				return @[t];
			}
		}
	}
	
	return nil;
}

- (NSArray*)isTwoPair:(NSArray*)pc {
	NSMutableArray*cs = [self getPCards:pc];
	
	if (cs.count >= 4) {
		NSMutableDictionary*ts = [[NSMutableDictionary alloc] init];
		
		for(NSString*c in cs){
			NSString*t = [c substringFromIndex:1];
			int tc = 0;
			if ([ts valueForKey:t] != nil) {
				tc = [[ts valueForKey:t] intValue];
			}
			tc++;
			[ts setValue:[NSNumber numberWithInteger:tc] forKey:t];
		}
		
		int p = 0;
		NSMutableArray*pairs = [[NSMutableArray alloc] init];
		
		for(NSString*t in ts.allKeys){
			int tc = [[ts valueForKey:t] intValue];
			if (tc >= 2) {
				p++;
				[pairs addObject:t];
			}
			if (p >= 2) {
				return pairs;
			}
		}
	}
	
	return nil;
}

- (NSArray*)isOnePair:(NSArray*)pc {
	NSMutableArray*cs = [self getPCards:pc];
	
	if (cs.count >= 2) {
		NSMutableDictionary*ts = [[NSMutableDictionary alloc] init];
		
		for(NSString*c in cs){
			NSString*t = [c substringFromIndex:1];
			int tc = 0;
			if ([ts valueForKey:t] != nil) {
				tc = [[ts valueForKey:t] intValue];
			}
			tc++;
			[ts setValue:[NSNumber numberWithInteger:tc] forKey:t];
		}
		
		for(NSString*t in ts.allKeys){
			int tc = [[ts valueForKey:t] intValue];
			if (tc >= 2) {
				return @[t];
			}
		}
	}
	
	return nil;
}

- (NSArray*)isHandCards:(NSArray*)pc {
	NSMutableArray*cards = [[NSMutableArray alloc] init];
	
	for(NSString*c in pc){
		[cards addObject:[c substringFromIndex:1]];
	}
	
	return cards;
}

@end
