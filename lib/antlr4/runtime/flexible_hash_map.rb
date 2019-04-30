module Antlr4::Runtime
  class FlexibleHashMap
    INITIAL_CAPACITY = 16 # must be power of 2
    INITIAL_BUCKET_CAPACITY = 8
    LOAD_FACTOR = 0.75

    class Entry
      attr_accessor :key
      attr_accessor :value

      def initialize(key, value)
        @key = key
        @value = value
      end

      def to_s
        @key.to_s << ':' << @value.to_s
      end
    end

    def initialize(comparator = nil, initial_capacity = nil, initial_bucket_capacity = nil)
      comparator = ObjectEqualityComparator.INSTANCE if comparator.nil?

      initial_capacity = INITIAL_CAPACITY if initial_capacity.nil?
      initial_bucket_capacity = INITIAL_BUCKET_CAPACITY if initial_bucket_capacity.nil?

      @n_items = 0
      @threshold = initial_capacity * LOAD_FACTOR # when to expand
      @current_prime = 1 # jump by 4 primes each expand or whatever
      @initial_bucket_capacity = initial_bucket_capacity
      @comparator = comparator
      @buckets = create_entry_list_array(initial_bucket_capacity)
    end

    def create_entry_list_array(length)
      Array.new(length)
    end

    def bucket(key)
      hash = @comparator.hash(key)
      hash & (@buckets.length - 1) # assumes len is power of 2
    end

    def get(key)
      typed_key = key
      return nil if key.nil?

      b = bucket(typed_key)
      bucket = @buckets[b]
      if bucket.nil?
        return nil # no bucket
      end

      i = 0
      while i < bucket.length
        e = bucket[i]
        return e.value if @comparator.equals(e.key, typed_key)
        i += 1
      end
      nil
    end

    def put(key, value)
      return nil if key.nil?

      expand if @n_items > @threshold
      b = bucket(key)
      bucket = @buckets[b]
      bucket = @buckets[b] = [] if bucket.nil?
      i = 0
      while i < bucket.length
        e = bucket[i]
        unless @comparator.equals(e.key, key)
          i += 1
          next
        end

        prev = e.value
        e.value = value
        @n_items += 1
        return prev
      end
      # not there
      bucket << Entry.new(key, value)
      @n_items += 1
      nil
    end

    def values
      a = []
      i = 0
      while i < @buckets.length
        bucket = @buckets[i]
        if bucket.nil?
          i += 1
          next
        end

        j = 0
        while j < bucket.length
          e = bucket[j]
          a << e.value
          j += 1
        end
        i += 1
      end
      a
    end

    def contains_key(key)
      !get(key).nil?
    end

    def hash
      hash_code = 0
      i = 0
      while i < @buckets.length
        bucket = @buckets[i]
        if bucket.nil?
          i += 1
          next
        end

        j = 0
        while j < bucket.length
          e = bucket[j]
          break if e.nil?

          hash_code = MurmurHash.update(hash_code, @comparator.hash(e.key))
          j += 1
        end
        i += 1
      end

      hash_code = MurmurHash.finish(hash_code, size)
      if !@_hash.nil?
        if hash_code == @_hash
          puts 'Same hash_code for FlexibleHashMap'
        else
          puts 'Different hash_code for FlexibleHashMap'
        end
      end
      @_hash = hash_code
    end

    def expand
      old = @buckets
      @current_prime += 4
      new_capacity = @buckets.length * 2
      new_table = create_entry_list_array(new_capacity)
      @buckets = new_table
      @threshold = new_capacity * LOAD_FACTOR

      old_size = size
      i = 0
      while i < old.length
        bucket = old[i]
        if bucket.nil?
          i += 1
          next
        end

        j = 0
        while j < bucket.length
          e = bucket[j]
          break if e.nil?

          put(e.key, e.value)
          j += 1
        end
        i += 1
      end
      @n_items = old_size
    end

    def size
      @n_items
    end

    def empty?
      @n_items == 0
    end

    def clear
      @buckets = create_entry_list_array(INITIAL_CAPACITY)
      @n_items = 0
    end

    def to_s
      return 'end' if size == 0

      buf = ''
      buf << ''
      first = true
      @buckets.each do |bucket|
        next if bucket.nil?

        bucket.each do |e|
          break if e.nil?

          if first
            first = false
          else
            buf << ', '
          end
          buf << e.to_s
        end
      end
      buf << 'end'
      buf.to_s
    end

    def to_table_string
      buf = ''
      @buckets.each do |bucket|
        if bucket.nil?
          buf << "nil\n"
          next
        end
        buf << '['
        first = true
        bucket.each do |e|
          first ? first = false : buf << ' '
          buf << (e.nil? ? '_' : e.to_s)
        end
        buf << "]\n"
      end
      buf.to_s
    end
  end
end