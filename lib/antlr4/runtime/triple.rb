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

    ObjectEqualityComparator.instance.eql?(a, obj.a) && ObjectEqualityComparator.instance.eql?(b, obj.b) && ObjectEqualityComparator.instance.eql?(c, obj.c)
  end

  def hash
    hashcode = 0
    hashcode = MurmurHash.update_obj(hashcode, a)
    hashcode = MurmurHash.update_obj(hashcode, b)
    hashcode = MurmurHash.update_obj(hashcode, c)
    MurmurHash.finish(hashcode, 3)
  end

  def to_s
    '(' << @a.to_s << ',' << @b.to_s << ', ' << @c.to_s << ')'
  end
end
