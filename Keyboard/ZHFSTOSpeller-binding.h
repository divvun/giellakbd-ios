//
//  ZHFSTOSpeller.h
//  TastyImitationKeyboard
//
//  Created by Brendan Molloy on 22/11/2015.
//  Copyright © 2015 Apple. All rights reserved.
//

#ifndef ZHFSTOSpeller_binding_h
#define ZHFSTOSpeller_binding_h

#define SELF zhfst_ospeller_t* self

#ifndef __cplusplus
typedef struct speller_s* speller_t;
typedef struct zhfst_ospeller_s* zhfst_ospeller_t;
#else
typedef hfst_ol::Speller speller_t;
typedef hfst_ol::ZHfstOspeller zhfst_ospeller_t;
#endif

struct correction_pair_s {
    const char* first;
    float second;
};

typedef struct correction_pair_s correction_pair_t;

void correction_pairs_delete(correction_pair_t* handle);
zhfst_ospeller_t* zhfst_ospeller_new();
void zhfst_ospeller_delete(SELF);
void zhfst_ospeller_inject_speller(SELF, speller_t* speller);
void zhfst_ospeller_set_queue_limit(SELF, unsigned long limit);
void zhfst_ospeller_set_weight_limit(SELF, float weight);
void zhfst_ospeller_set_beam(SELF, float beam);
void zhfst_ospeller_read_zhfst(SELF, const char* filename, const char* tmpdir, const char** error);
bool zhfst_ospeller_spell(SELF, const char* wordform);
correction_pair_t* zhfst_ospeller_suggest(SELF, const char* wordform);
//void zhfst_ospeller_clear_suggestion_cache(SELF);
const char* zhfst_ospeller_metadata_dump(SELF);
void zhfst_string_delete(const char* handle);
#endif /* ZHFSTOSpeller_binding_h */
