module Antlr4::Runtime

  class BitSet
    MAX_BITS = 128

    attr_reader :bits

    def initialize
      @bits = 0
    end

    def set(x)
      @bits |= (1 << x)
    end

    def clear(idx = nil)
      # check for zero to avoid trying to take the log2 of it, which
      # returns -Infinity
      if !idx || bits == 0
        @bits = 0
        return
      end

      @bits &= 2**Math.log2(bits).ceil - 2**idx - 1
    end

    def get(x)
      (@bits & (1 << x)) > 0 ? true : false
    end

    def cardinality
      RumourHash.bit_count(@bits)
    end

    def or(bit_set)
      @bits |= bit_set.bits
    end

    def next_set_bit(bit)
      result = bit
      i = 0
      mask = (1 << bit)
      while i < MAX_BITS
        if (@bits & mask) > 0
          return result
        end
        result += 1
        mask <<= 1
        i += 1
      end
      -1
    end

    def to_s
      buf = '['
      buf << @bits.to_s(2)
      buf << ']'
      buf
    end
  end
end
