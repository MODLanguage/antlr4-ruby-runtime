module Antlr4::Runtime

  class BitSet
    attr_reader :bits

    def initialize
      @bits = Set.new
    end

    def set(x)
      @bits.add x
    end

    def get(x)
      @bits.include? x ? true : false
    end

    def cardinality
      @bits.length
    end

    def or(bit_set)
      bit_set.bits.each(&method(:set))
    end

    def next_set_bit(bit)
      result = -1

      @bits.each do |b|
        if b >= bit
          result = b
          break
        end
      end
      result
    end

    def to_s
      max = 0
      @bits.each {|b| max = b if b > max}
      v = Array.new(max, 0)
      @bits.each do |bit|
        v[bit] = 1
      end
      buf = '['
      tmp = ''
      v.each do |c|
        tmp << c.to_s
      end
      buf << tmp.reverse!
      buf << ']'
      buf
    end
  end
end