//
//  ZHFSTOSpeller.m
//  TastyImitationKeyboard
//
//  Created by Brendan Molloy on 22/11/2015.
//  Copyright © 2015 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZHFSTOSpeller-binding.h"
#import "ZHFSTOSpeller.h"

@implementation ZHFSTPair
-(id)initWithFirst:(id)first second:(id)second {
    self = [super init];
    
    if (self) {
        self.first = first;
        self.second = second;
    }
    
    return self;
}
@end


@implementation ZHFSTOSpeller

-(id)init {
    self = [super init];
    
    if (self) {
        self.handle = zhfst_ospeller_new();
    }
    
    return self;
}

-(void) dealloc {
    zhfst_ospeller_delete(self.handle);
}

-(void) readZhfst:(NSString*)filename tempDir:(NSString*)tmpdir {
    const char* error = NULL;
    zhfst_ospeller_read_zhfst(self.handle, [filename UTF8String], [tmpdir UTF8String], &error);
    
    if (error != NULL) {
        NSException* e = [NSException
                          exceptionWithName:@"ZHfstZipReadingError"
                          reason:[NSString stringWithUTF8String:error]
                          userInfo:nil];
        zhfst_string_delete(error);
        @throw e;
    }
}

- (void)setQueueLimit:(unsigned long)limit {
    zhfst_ospeller_set_queue_limit(self.handle, limit);
}

- (void)setWeightLimit:(float)weight {
    zhfst_ospeller_set_weight_limit(self.handle, weight);
}

- (void)setBeam:(float)beam {
    zhfst_ospeller_set_beam(self.handle, beam);
}

- (BOOL)spell:(NSString*)word {
    return zhfst_ospeller_spell(self.handle, [word UTF8String]) != 0;
}

//- (void)clearSuggestionCache {
//    zhfst_ospeller_clear_suggestion_cache(self.handle);
//}

-(NSArray<ZHFSTPair<NSString*, NSNumber*>*>*)suggest:(NSString*)word {
    correction_pair_t* pairs = zhfst_ospeller_suggest(self.handle, [word UTF8String]);
    
    if (pairs == NULL) {
        return [[NSArray alloc] init];
    }
    
    NSMutableArray* o = [[NSMutableArray alloc] init];
    
    correction_pair_t* ptr = pairs;
    for (; ptr->first != 0; ptr++) {
        ZHFSTPair* opair = [[ZHFSTPair<NSString*, NSNumber*> alloc]
                           initWithFirst:[NSString stringWithUTF8String:ptr->first]
                           second:[NSNumber numberWithFloat:ptr->second]];
        [o addObject:opair];
    }
    
    correction_pairs_delete(pairs);
    
    return [o copy];
}

@end