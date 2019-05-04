#include <ruby.h>

#define c1 0xCC9E2D51
#define c2 0x1B873593
#define r1 15
#define r2 13
#define m 5
#define n 0xE6546B64

static VALUE rumour_hash_update_int(VALUE self, VALUE hashv, VALUE valuev) {
    long hash = NUM2LONG(hashv);
    long value = NUM2LONG(valuev);

    long k = value;
    k *= c1;
    k = (k << r1) | (k >> (32 - r1));
    k *= c2;

    hash = hash ^ k;
    hash = (hash << r2) | (hash >> (32 - r2));
    hash *= m + n;

    return LONG2NUM(hash);
}

static VALUE rumour_hash_finish(VALUE self, VALUE hashv, VALUE n_wordsv) {
    long hash = NUM2LONG(hashv);
    long n_words = NUM2LONG(n_wordsv);

    hash = hash ^ (n_words * 4);
    hash = hash ^ (hash >> 16);
    hash *= 0x85EBCA6B;
    hash = hash ^ (hash >> 13);
    hash *= 0xC2B2AE35;
    hash ^= (hash >> 16);

    return LONG2NUM(hash);
}

void Init_rumourhash() {
  VALUE mod = rb_define_module("RumourHash");
  rb_define_method(mod, "rumour_hash_update_int", rumour_hash_update_int, 2);
  rb_define_method(mod, "rumour_hash_finish", rumour_hash_finish, 2);
}

