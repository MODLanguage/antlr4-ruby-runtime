require 'singleton'

class ObjectEqualityComparator
  include Singleton

  def hash(obj)
    return 0 if obj.nil?

    obj.hash
  end

  def equals(a, b)
    return b.nil? if a.nil?

    a.eql?(b)
  end
end
