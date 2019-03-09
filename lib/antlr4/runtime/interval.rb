class Interval
  INTERVAL_POOL_MAX_VALUE = 1000

  @@cache = []

  attr_accessor :a
  attr_accessor :b

  class << self
    attr_accessor :creates
    attr_accessor :misses
    attr_accessor :hits
    attr_accessor :outOfRange
  end
  @@creates = 0
  @@misses = 0
  @@hits = 0
  @@outOfRange = 0

  def initialize(a, b)
    @a = a
    @b = b
  end

  INVALID = Interval.new(-1, -2)

  def self.of(a, b)
    return Interval.new(a, b) if a != b || a < 0 || a > INTERVAL_POOL_MAX_VALUE

    @@cache[a] = Interval.new(a, a) if @@cache[a].nil?
    @@cache[a]
  end

  def length
    return 0 if b < a

    b - a + 1
  end

  def ==(o)
    return false if o.nil? || !(o.is_a? Interval)

    @a == o.a && @b == o.b
  end

  def hash
    hash = 23
    hash = hash * 31 + @a
    hash * 31 + @b
  end

  def starts_before_disjoint(other)
    @a < other.a && @b < other.a
  end

  def starts_before_non_disjoint(other)
    @a <= other.a && @b >= other.a
  end

  def startsAfter(other)
    @a > other.a
  end

  def startsAfterDisjoint(other)
    @a > other.b
  end

  def startsAfterNonDisjoint(other)
    @a > other.a && @a <= other.b
  end

  def disjoint(other)
    starts_before_disjoint(other) || startsAfterDisjoint(other)
  end

  def adjacent(other)
    @a == other.b + 1 || @b == other.a - 1
  end

  def properlyContains(other)
    other.a >= @a && other.b <= @b
  end

  def union(other)
    Interval.of([a, other.a].min, [b, other.b].max)
  end

  def intersection(other)
    Interval.of([a, other.a].max, [b, other.b].min)
  end

  def difference_not_properly_contained(other)
    diff = null
    if other.starts_before_non_disjoint(this)

      diff = Interval.of([@a, other.b + 1].max, @b)

    elsif other.startsAfterNonDisjoint(this)

      diff = Interval.of(@a, other.a - 1)
    end
    diff
  end

  def to_s
    a.to_s + '..' + b.to_s
  end
end
