module Antlr4::Runtime
  class MurmurHash
    DEFAULT_SEED = 0
    MASK_32 = 0xFFFFFFFF

    def self.hash_int(num)
      hash_code = 7
      hash_code = update_int(hash_code, num)
      finish(hash_code, 0)
    end

    def self.hash_int_obj(num, obj)
      hash_code = 7
      hash_code = update_int(hash_code, num)
      hash_code = update_obj(hash_code, obj)
      finish(hash_code, 2)
    end

    def self.hash_int_int_obj_obj(num1, num2, obj1, obj2)
      hash_code = 7
      hash_code = update_int(hash_code, num1)
      hash_code = update_int(hash_code, num2)
      hash_code = update_obj(hash_code, obj1)
      hash_code = update_obj(hash_code, obj2)
      finish(hash_code, 4)
    end

    def self.hash_int_int(num1, num2)
      hash_code = 7
      hash_code = update_int(hash_code, num1)
      hash_code = update_int(hash_code, num2)
      finish(hash_code, 2)
    end

    def self.hash_objs(objs)
      hash_code = 7

      i = 0
      while i < objs.length
        obj = objs[i]
        hash_code = update_obj(hash_code, obj)
        i += 1
      end

      finish(hash_code, objs.length)
    end

    def self.hash_ints_objs(nums, objs)
      hash_code = 7

      i = 0
      while i < objs.length
        obj = objs[i]
        hash_code = update_obj(hash_code, obj)
        i += 1
      end

      i = 0
      while i < nums.length
        num = nums[i]
        hash_code = update_int(hash_code, num)
        i += 1
      end

      finish(hash_code, 2 * objs.length)
    end

    def self.hash_ints(nums)
      hash_code = 7

      i = 0
      while i < nums.length
        num = nums[i]
        hash_code = update_int(hash_code, num)
        i += 1
      end

      finish(hash_code, 2 * nums.length)
    end

    private

    def self.update_int(hash, value)
      c1 = 0xCC9E2D51
      c2 = 0x1B873593
      r1 = 15
      r2 = 13
      m = 5
      n = 0xE6546B64

      k = value
      k *= c1
      k = (k << r1) | (k >> (32 - r1))
      k *= c2

      hash = hash ^ k
      hash = (hash << r2) | (hash >> (32 - r2))
      hash *= m + n
      hash &= MASK_32
      hash
    end

    def self.update_obj(hash, value)
      update_int(hash, !value.nil? ? value.hash : 0)
    end

    def self.finish(hash, n_words)
      hash = hash ^ (n_words * 4)
      hash = hash ^ (hash >> 16)
      hash *= 0x85EBCA6B
      hash = hash ^ (hash >> 13)
      hash *= 0xC2B2AE35
      hash ^= (hash >> 16)
      hash &= MASK_32
      hash
    end

    def self.hash(data, seed)
      hash = seed
      i = 0
      while i < data.length
        value = data[i]
        hash = update_obj(hash, value)
        i += 1
      end

      finish(hash, data.length)
    end
  end
end