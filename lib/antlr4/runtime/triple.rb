module Antlr4::Runtime
  class Triple
    attr_accessor :a
    attr_accessor :b
    attr_accessor :c

    def initialize(a, b, c)
      @a = a
      @b = b
      @c = c
    end

    def eql?(obj)
      if obj == self
        return true
      else
        return false unless obj.is_a? Triple
      end

      ObjectEqualityComparator.instance.compare(a, obj.a).zero? && ObjectEqualityComparator.instance.compare(b, obj.b).zero? && ObjectEqualityComparator.instance.compare(c, obj.c).zero?
    end

    def hash
      hash_code = RumourHash.hash([@a, @b, @c])

      unless @_hash.nil?
        if hash_code == @_hash
          puts 'Same hash_code for Triple'
        else
          puts 'Different hash_code for Triple'
        end
      end
      @_hash = hash_code
    end

    def to_s
      '(' << @a.to_s << ',' << @b.to_s << ', ' << @c.to_s << ')'
    end
  end
end
