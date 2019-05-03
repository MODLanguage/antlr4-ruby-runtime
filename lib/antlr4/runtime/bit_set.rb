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

    def get(x)
      (@bits & (1 << x)) > 0 ? true : false
    end

    def cardinality
      count = 0
      i = 0
      mask = 1
      while i < MAX_BITS
        count += 1 if (@bits & mask) > 0
        mask <<= 1
        i += 1
      end
      count
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