module Antlr4::Runtime

  class ObjectEqualityComparator
    include Singleton

    def hash(obj)
      return 0 if obj.nil?

      obj.hash
    end

    def compare(a, b)
      return 1 if a.nil? || b.nil?

      a <=> b
    end
  end
end