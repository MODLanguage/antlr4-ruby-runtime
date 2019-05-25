#include <ruby.h>

#define c1 0xCC9E2D51
#define c2 0x1B873593
#define r1 15
#define r2 13
#define m 5
#define n 0xE6546B64
#define defaultSeed 7

static long rumour_hash_update_int_impl(VALUE self, long hash, long value) {
    long k = value;
    k *= c1;
    k = (k << r1) | (k >> (32 - r1));
    k *= c2;

    hash = hash ^ k;
    hash = (hash << r2) | (hash >> (32 - r2));
    hash *= m + n;

    return hash;
}

static VALUE rumour_hash_update_int(VALUE self, VALUE hashv, VALUE valuev) {
    long hash = NUM2LONG(hashv);
    long value = NUM2LONG(valuev);
    hash = rumour_hash_update_int_impl(self, hash, value);
    return LONG2NUM(hash);
}

static long rumour_hash_finish_impl(VALUE self, long hash, long n_words) {
    hash = hash ^ (n_words * 4);
    hash = hash ^ (hash >> 16);
    hash *= 0x85EBCA6B;
    hash = hash ^ (hash >> 13);
    hash *= 0xC2B2AE35;
    hash ^= (hash >> 16);

    return hash;
}

static VALUE rumour_hash_finish(VALUE self, VALUE hashv, VALUE n_wordsv) {
    long hash = NUM2LONG(hashv);
    long n_words = NUM2LONG(n_wordsv);
    hash = rumour_hash_finish_impl(self, hash, n_words);
    return LONG2NUM(hash);
}

static VALUE rumour_hash_calculate(int argc, VALUE* argv, VALUE self) {
    VALUE itemsv;
    VALUE seed;

    rb_scan_args(argc, argv, "11", &itemsv, &seed);

    long hash;

    if (seed == Qnil) {
        hash = defaultSeed;
    } else {
        hash = NUM2LONG(seed);
    }

    int i;
    for (i = 0; i < RARRAY_LEN(itemsv); i ++) {
        VALUE current = RARRAY_AREF(itemsv, i);
        long val;

        if (current == Qnil || current == Qfalse) {
            val = 0;
        } else if (current == Qtrue) {
            val = 1;
        } else if (CLASS_OF(current) == rb_cInteger) {
            val = NUM2LONG(current);
        } else {
            val = NUM2LONG(rb_hash(current));
        }

        hash = rumour_hash_update_int_impl(self, hash, val);
    }

    hash = rumour_hash_finish_impl(self, hash, RARRAY_LEN(itemsv));
    return LONG2NUM(hash);
}

static VALUE rumour_hash_bit_count(VALUE self, VALUE v) {
    long num = NUM2LONG(v);
    int count = 0;

    while (num)
    {
      num &= (num-1) ;
      count++;
    }

    return INT2NUM(count);
}

void Init_rumourhash() {
  VALUE mod = rb_define_module("RumourHash");
  rb_define_singleton_method(mod, "calculate", rumour_hash_calculate, -1);
  rb_define_singleton_method(mod, "update_int", rumour_hash_update_int, 2);
  rb_define_singleton_method(mod, "finish", rumour_hash_finish, 2);
  rb_define_singleton_method(mod, "bit_count", rumour_hash_bit_count, 1);
}
