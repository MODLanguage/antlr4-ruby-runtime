require 'rumourhash/rumourhash'

include RumourHash

module Antlr4::Runtime
  class MurmurHash
    DEFAULT_SEED = 0
    MASK_32 = 0xFFFFFFFF

    def self.hash_int(num)
      hash_code = 7
      hash_code = RumourHash.rumour_hash_update_int(hash_code, num)
      RumourHash.rumour_hash_finish(hash_code, 0)
    end

    def self.hash_int_obj(num, obj)
      hash_code = 7
      hash_code = RumourHash.rumour_hash_update_int(hash_code, num)
      hash_code = update_obj(hash_code, obj)
      RumourHash.rumour_hash_finish(hash_code, 2)
    end

    def self.hash_int_int_obj_obj(num1, num2, obj1, obj2)
      hash_code = 7
      hash_code = RumourHash.rumour_hash_update_int(hash_code, num1)
      hash_code = RumourHash.rumour_hash_update_int(hash_code, num2)
      hash_code = update_obj(hash_code, obj1)
      hash_code = update_obj(hash_code, obj2)
      RumourHash.rumour_hash_finish(hash_code, 4)
    end

    def self.hash_int_int(num1, num2)
      hash_code = 7
      hash_code = RumourHash.rumour_hash_update_int(hash_code, num1)
      hash_code = RumourHash.rumour_hash_update_int(hash_code, num2)
      RumourHash.rumour_hash_finish(hash_code, 2)
    end

    def self.hash_objs(objs)
      hash_code = 7

      i = 0
      while i < objs.length
        obj = objs[i]
        hash_code = update_obj(hash_code, obj)
        i += 1
      end

      RumourHash.rumour_hash_finish(hash_code, objs.length)
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
        hash_code = RumourHash.rumour_hash_update_int(hash_code, num)
        i += 1
      end

      RumourHash.rumour_hash_finish(hash_code, 2 * objs.length)
    end

    def self.hash_ints(nums)
      hash_code = 7

      i = 0
      while i < nums.length
        num = nums[i]
        hash_code = RumourHash.rumour_hash_update_int(hash_code, num)
        i += 1
      end

      RumourHash.rumour_hash_finish(hash_code, 2 * nums.length)
    end

    private

    def self.update_obj(hash, value)
      RumourHash.rumour_hash_update_int(hash, !value.nil? ? value.hash : 0)
    end

    def self.hash(data, seed)
      hash = seed
      i = 0
      while i < data.length
        value = data[i]
        hash = update_obj(hash, value)
        i += 1
      end

      RumourHash.rumour_hash_finish(hash, data.length)
    end
  end
end