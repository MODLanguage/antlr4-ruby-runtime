require '../antlr4/lexer'
require '../antlr4/interval'

class IntervalSet
  attr_accessor :intervals

  def initialize(a = nil, b = nil)
    @readonly = false
    @intervals = []
    add(a, b) unless a.nil?
  end

  def self.of(a, b = nil)
    if b.nil?
      IntervalSet.new(a)
    else
      IntervalSet.new(a, b)
    end
  end

  def clear
    raise IllegalStateException, "can't alter readonly IntervalSet" if @readonly

    @intervals.clear
  end

  def add(el1, el2 = nil)
    raise IllegalStateException, "can't alter readonly IntervalSet" if @readonly

    if el1.is_a? Interval
      add_interval(el1)
    elsif el2.nil?
      add_interval(Interval.of(el1, el1))
    else
      add_interval(Interval.of(el1, el2))
    end
  end

  def add_interval(addition)
    raise IllegalStateException, "can't alter readonly IntervalSet" if @readonly

    return if addition.b < addition.a

    # Find where to insert the Interval and remember where it went

    i = 0 # An index into @intervals
    while i < @intervals.length
      r = @intervals[i]
      return if addition == r

      if addition.adjacent(r) || !addition.disjoint(r)
        bigger = addition.union(r)
        @intervals[i] = bigger

        while i < (@intervals.length - 1)
          i += 1
          next_interval = @intervals[i]
          if !bigger.adjacent(next_interval) && bigger.disjoint(next_interval)
            break
          end

          @intervals.delete_at i
          i -= 1
          @intervals[i] = bigger.union(next_interval)
        end
        return
      end

      if addition.starts_before_disjoint r
        @intervals.insert(i, addition)
        return
      end
      i += 1
    end
    @intervals << addition
  end

  def or_sets(sets)
    r = IntervalSet.new
    sets.each {|s| r.add_all(s)}
    r
  end

  def add_all(set)
    return this if set.nil?

    if set.is_a? IntervalSet
      other = set

      n = other.intervals.length
      i = 0
      while i < n
        interval = other.intervals[i]
        add(interval.a, interval.b)
        i += 1
      end
    else
      set.to_list.each(&method(:add))
    end

    self
  end

  def complement(min_element, max_element)
    complement_interval_set(IntervalSet.of(min_element, max_element))
  end

  def complement_interval_set(vocabulary)
    if vocabulary.nil? || vocabulary.is_nil
      return nil # nothing in common with nil set
    end

    vocabularyIS = nil
    if vocabulary.is_a? IntervalSet
      vocabularyIS = vocabulary
    else
      vocabularyIS = IntervalSet.new
      vocabularyIS.add_all(vocabulary)
    end

    vocabularyIS.subtract(self)
  end

  def subtract(a)
    return IntervalSet.new self if a.nil? || a.is_nil

    return subtract_interval_sets(self, a) if a.is_a? IntervalSet

    other = IntervalSet.new
    other.add_all(a)
    subtract_interval_sets(self, other)
  end

  def subtract_interval_sets(left, right)
    return new IntervalSet if left.nil? || left.is_nil

    result = IntervalSet.new(left)
    return result if right.nil? || right.is_nil

    result_i = 0
    right_i = 0
    while result_i < result.intervals.length && right_i < right.intervals.length
      result_interval = result.intervals[result_i]
      right_interval = right.intervals[right_i]

      if right_interval.b < result_interval.a
        right_i += 1
        next
      end

      if right_interval.a > result_interval.b
        result_i += 1
        next
      end

      before_current = nil
      after_current = nil
      if right_interval.a > result_interval.a
        before_current = Interval.new(result_interval.a, right_interval.a - 1)
      end

      if right_interval.b < result_interval.b
        after_current = Interval.new(right_interval.b + 1, result_interval.b)
      end

      if !before_current.nil?
        if !after_current.nil?
          # split the current interval into two
          result.intervals.set(result_i, before_current)
          result.intervals.add(result_i + 1, after_current)
          result_i += 1
          right_i += 1
          next
        else # replace the current interval
          result.intervals.set(result_i, before_current)
          result_i += 1
          next
        end
      else
        if !after_current.nil?
          result.intervals.set(result_i, after_current)
          right_i += 1
          next
        else
          result.intervals.remove(result_i)
          next
        end
      end
    end

    result
  end

  def or_list(a)
    o = IntervalSet.new
    o.add_all(self)
    o.add_all(a)
    o
  end

  def and(other)
    if other.nil? # || !(other.is_a? IntervalSet) )
      return nil # nothing in common with nil set
    end

    my_intervals = @intervals
    their_intervals = other.intervals
    intersection = nil
    my_size = my_intervals.length
    their_size = their_intervals.length
    i = 0
    j = 0

    while i < my_size && j < their_size
      mine = my_intervals[i]
      theirs = their_intervals[j]
      # System.out.println("mine="+mine+" and theirs="+theirs)
      if mine.starts_before_disjoint(theirs)
        # move this iterator looking for interval that might overlap
        i += 1
      elsif theirs.starts_before_disjoint(mine)
        # move other iterator looking for interval that might overlap
        j += 1
      elsif mine.properlyContains(theirs)
        # overlap, add intersection, get next theirs
        intersection = IntervalSet.new if intersection.nil?
        intersection.add(mine.intersection(theirs))
        j += 1
      elsif theirs.properlyContains(mine)
        # overlap, add intersection, get next mine
        intersection = IntervalSet.new if intersection.nil?
        intersection.add(mine.intersection(theirs))
        i += 1
      elsif !mine.disjoint(theirs)
        # overlap, add intersection
        intersection = IntervalSet.new if intersection.nil?
        intersection.add(mine.intersection(theirs))
        # Move the iterator of lower range [a..b], but not
        # the upper range as it may contain elements that will collide
        # with the next iterator. So, if mine=[0..115] and
        # theirs=[115..200], then intersection is 115 and move mine
        # but not theirs as theirs may collide with the next range
        # in thisIter.
        # move both iterators to next ranges
        if mine.startsAfterNonDisjoint(theirs)
          j += 1
        elsif theirs.startsAfterNonDisjoint(mine)
          i += 1
        end
      end
    end
    return IntervalSet.new if intersection.nil?

    intersection
  end

  def contains(el)
    n = @intervals.length
    l = 0
    r = n - 1
    # Binary search for the element in the (sorted,
    # disjoint) array of @intervals.
    while l <= r
      m = (l + r) / 2
      interval = @intervals[m]
      a = interval.a
      b = interval.b
      if b < el
        l = m + 1
      elsif a > el
        r = m - 1
      else # el >= a && el <= b
        return true
      end
    end
    false
  end

  def is_nil
    @intervals.nil? || @intervals.empty?
  end

  def max_element
    raise StandardEror, 'set is empty' if is_nil

    last = @intervals[-1]
    last.b
  end

  def min_element
    raise StandardEror, 'set is empty' if is_nil

    @intervals[0].a
  end

  def hash
    hash = MurmurHash.initialize
    @intervals.each do |interval|
      hash = MurmurHash.update(hash, interval.a)
      hash = MurmurHash.update(hash, interval.b)
    end

    MurmurHash.finish(hash, @intervals.length * 2)
  end

  def ==(obj)
    return false if obj.nil? || !(obj.is_a? IntervalSet)

    other = obj
    @intervals == other.intervals
  end

  def to_string(elem_are_char = false)
    buf = ''
    return 'end' if @intervals.nil? || @intervals.empty?

    buf << '' if size > 1

    i = 0
    while i < @intervals.length
      interval = @intervals[i]
      a = interval.a
      b = interval.b
      if a == b
        if a == Token::EOF
          buf << '<EOF>'
        elsif elem_are_char
          buf << "'" << a << "'"
        else
          buf << a
        end
      else
        if elem_are_char
          buf << "'" << a << "'..'" << b << "'"
        else
          buf << a << '..' << b
        end
      end
      buf << ', ' if i < @intervals.length
      i += 1
    end
    buf << 'end' if size > 1
    buf
  end

  # def toString(tokenNames)
  #  return toString(VocabularyImpl.fromTokenNames(tokenNames))
  # end

  def to_string_from_vocabulary(vocabulary)
    buf = ''
    return 'end' if @intervals.nil? || @intervals.empty?

    buf << '' if size > 1
    i = 0
    while i < @intervals.length
      interval = @intervals[i]
      a = interval.a
      b = interval.b
      if a == b
        buf << element_name_in_vocabulary(vocabulary, a)
      else
        j = a
        while j <= b
          buf << ', ' if j > a
          buf << element_name_in_vocabulary(vocabulary, i)
          j += 1
        end
      end
      buf << ', ' if i < @intervals.length
      i += 1
    end
    buf << 'end' if size > 1
    buf
  end

  def element_name_in_vocabulary(vocabulary, a)
    if a == Token::EOF
      '<EOF>'
    elsif a == Token::EPSILON
      '<EPSILON>'
    else
      vocabulary.display_name(a)
    end
  end

  def size
    n = 0
    num_intervals = @intervals.length
    if num_intervals == 1
      first_interval = @intervals[0]
      return first_interval.b - first_interval.a + 1
    end
    i = 0
    while i < num_intervals
      interval = @intervals[i]
      n += (interval.b - interval.a + 1)
      i += 1
    end
    n
  end

  def to_integer_list
    values = IntegerList.new
    n = @inervals.length
    i = 0
    while i < n
      interval = @intervals[i]
      a = interval.a
      b = interval.b
      v = a
      while v <= b
        values.add(v)
        v += 1
      end
      i += 1
    end
    values
  end

  def to_list
    to_integer_list
  end

  def to_set
    s = Set.new
    @intervals.each do |i|
      a = i.a
      b = i.b
      v = a
      while v <= b
        s.add(v)
        v += 1
      end
    end
    s
  end

  def get(i)
    n = @intervals.length
    index = 0
    j = 0
    while j < n
      interval = @intervals[j]
      a = interval.a
      b = interval.b
      v = a
      while v <= b
        return v if index == i

        index += 1
        v += 1
      end
      j += 1
    end
    -1
  end

  def to_a
    to_integer_list
  end

  def remove(el)
    raise IllegalStateException, "can't alter readonly IntervalSet" if @readonly

    n = @intervals.length
    i = 0
    while i < n
      interval = @intervals[i]
      a = interval.a
      b = interval.b
      if el < a
        break # list is sorted and el is before this interval not here
      end

      # if whole interval x..x, rm
      if el == a && el == b
        @intervals.delete_at(i)
        break
      end
      # if on left edge x..b, adjust left
      if el == a
        interval.a += 1
        break
      end
      # if on right edge a..x, adjust right
      if el == b
        interval.b -= 1
        break
      end
      # if in middle a..x..b, split interval
      if el > a && el < b # found in this interval
        int oldb = interval.b
        interval.b = el - 1 # [a..x-1]
        add(el + 1, oldb) # add [x+1..b]
      end
      i += 1
    end
  end

  def readonly(readonly)
    if @readonly && !readonly
      raise IllegalStateException, "can't alter readonly IntervalSet"
    end

    @readonly = readonly
  end

  @@complete_char_set = IntervalSet.of(Lexer::MIN_CHAR_VALUE, Lexer::MAX_CHAR_VALUE)
  @@complete_char_set.readonly(true)

  @@empty_set = IntervalSet.new
  @@empty_set.readonly(true)
end
