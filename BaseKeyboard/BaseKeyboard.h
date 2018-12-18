//
//  BaseKeyboard.h
//  BaseKeyboard
//
//  Created by Brendan Molloy on 21/9/17.
//  Copyright © 2017 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for BaseKeyboard.
FOUNDATION_EXPORT double BaseKeyboardVersionNumber;

//! Project version string for BaseKeyboard.
FOUNDATION_EXPORT const unsigned char BaseKeyboardVersionString[];

#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <sys/types.h>

#ifndef _Nonnull
#define _Nonnull
#endif

typedef void speller_t;
typedef void suggest_vec_t;

extern speller_t*
speller_archive_new(const char* _Nonnull path, uint8_t* error);

extern const char* _Nonnull
speller_get_error(uint8_t code);

extern void
speller_archive_free(speller_t* _Nonnull handle);

extern const char* _Nonnull
speller_meta_get_locale(speller_t* _Nonnull handle);

extern void
speller_str_free(const char* _Nonnull str);

extern suggest_vec_t* _Nonnull
speller_suggest(speller_t* _Nonnull handle, const char* _Nonnull word, size_t n_best, float max_weight, float beam);

extern const char* _Nonnull
speller_suggest_json(speller_t* _Nonnull handle, const char* _Nonnull word, size_t n_best, float max_weight, float beam);

extern bool
speller_is_correct(speller_t* _Nonnull handle, const char* _Nonnull word);

extern void
suggest_vec_free(suggest_vec_t* _Nonnull handle);

extern size_t
suggest_vec_len(suggest_vec_t* _Nonnull handle);

extern const char* _Nonnull
suggest_vec_get_value(suggest_vec_t* _Nonnull handle, size_t _Nonnull index);

extern float
suggest_vec_get_weight(suggest_vec_t* _Nonnull handle, size_t _Nonnull index);

extern void
suggest_vec_value_free(const char* _Nonnull value);

const uint8_t TOKEN_OTHER = 0;
const uint8_t TOKEN_WORD = 1;
const uint8_t TOKEN_PUNCTUATION = 2;
const uint8_t TOKEN_WHITESPACE = 3;

typedef struct token_record_s {
    uint8_t type;
    uint32_t start;
    uint32_t end;
    const char* value;
} token_record_t;

typedef void tokenizer_t;

extern tokenizer_t*
speller_tokenize(const char* _Nonnull string);

extern bool
speller_token_next(tokenizer_t* _Nonnull handle, token_record_t** record);

extern void
speller_tokenizer_free(tokenizer_t* _Nonnull handle);
