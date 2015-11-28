//
//  ZHFSTOSpeller.cpp
//  TastyImitationKeyboard
//
//  Created by Brendan Molloy on 22/11/2015.
//  Copyright © 2015 Apple. All rights reserved.
//

#import <libhfstospell/ospell.h>
#import <libhfstospell/ZHfstOspeller.h>

extern "C" {

#import "ZHFSTOSpeller-binding.h"
    correction_pair_t* correction_pairs_new(std::vector<hfst_ol::StringWeightPair> vec) {
        size_t size = vec.size() + 1;
        correction_pair_t* pairs = new correction_pair_t[size];
        
        size_t i = 0;
        for (hfst_ol::StringWeightPair pair : vec) {
            pairs[i].first = strdup(pair.first.c_str());
            pairs[i].second = pair.second;
            i++;
        }
        
        pairs[i] = { 0, 0 };
        
        return pairs;
    }
    
    void correction_pairs_delete(correction_pair_t* handle) {
        correction_pair_t* ptr = handle;
        
        while (ptr->first != 0) {
            delete ptr->first;
            ptr++;
        }
        
        delete[] handle;
    }
    
    zhfst_ospeller_t* zhfst_ospeller_new() {
        return new hfst_ol::ZHfstOspeller();
    }
    
    void zhfst_ospeller_delete(SELF) {
        delete self;
    }
    
    void zhfst_ospeller_inject_speller(SELF, speller_t* speller) {
        self->inject_speller(speller);
    }
    
    void zhfst_ospeller_set_queue_limit(SELF, unsigned long limit) {
        self->set_queue_limit(limit);
    }
    
    void zhfst_ospeller_set_weight_limit(SELF, float weight) {
        self->set_weight_limit(weight);
    }
    
    void zhfst_ospeller_set_beam(SELF, float beam) {
        self->set_beam(beam);
    }
    
    void zhfst_ospeller_read_zhfst(SELF, const char* filename, const char* tmpdir, const char** error) {
        try {
            self->set_temporary_dir(std::string(tmpdir));
            self->read_zhfst(std::string(filename));
        } catch (hfst_ol::ZHfstZipReadingError& e) {
            char* msg = new char[strlen(e.what())+1];
            strncpy(msg, e.what(), strlen(e.what())+1);
            *error = msg;
        }
    }
    
    void zhfst_string_delete(const char* handle) {
        delete[] handle;
    }
    
    bool zhfst_ospeller_spell(SELF, const char* wordform) {
        return self->spell(std::string(wordform));
    }
    
    correction_pair_t* zhfst_ospeller_suggest(SELF, const char* wordform) {
        std::string cpp_word (wordform);
        return correction_pairs_new(self->suggest(cpp_word));
    }
    
    //void zhfst_ospeller_clear_suggestion_cache(SELF) {
    //    self->clear_suggestion_cache();
    //}
    
    /*
     analysis_queue_t zhfst_ospeller_analyse(SELF, const char* wordform, bool ask_sugger) {
     return self->analyse(wordform, ask_sugger);
     }
     
     analysis_correction_queue_t zhfst_ospeller_suggest_analyses(SELF, const char* wordform) {
     return self->suggest_analyses(std::string(wordform));
     }
     
     hyphenation_queue_t zhfst_ospeller_hyphenate(SELF, const char* wordform) {
     return self->hyphenate(std::string(wordform));
     }
     */
    
    const char* zhfst_ospeller_metadata_dump(SELF) {
        return self->metadata_dump().c_str();
    }
}