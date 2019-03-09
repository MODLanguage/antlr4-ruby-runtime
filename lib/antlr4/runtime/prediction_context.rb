require '../antlr4/integer'
require '../antlr4/rule_context'

class PredictionContext
  INITIAL_HASH = 1
  EMPTY_RETURN_STATE = Integer::MAX

  class << self
    @@global_node_count = 0
  end

  attr_accessor :cachedHashCode

  def initialize(cached_hash_code)
    @id = @@global_node_count
    @@global_node_count += 1
    @cached_hash_code = cached_hash_code
  end

  def empty_path? # since EMPTY_RETURN_STATE can only appear in the last position, we check last one
    get_return_state(size - 1) == EMPTY_RETURN_STATE
  end

  def hash
    @cached_hash_code
  end

  def to_s_recog(_recog)
    to_s
  end

  def to_strings(recognizer, current_state)
    to_strings3(recognizer, EMPTY, current_state)
  end

  def to_strings3(_recognizer, _stop, _current_state)
    result = []

    while to_strings3_inner result

    end

    result
  end

  def to_strings3_inner(result)
    perm = 0
    while perm
      offset = 0
      last = true
      p = self
      state_number = current_state
      local_buffer = ''
      local_buffer << '['
      while !p.empty? && p != stop
        index = 0
        unless p.empty?
          bits = 1
          bits += 1 while (1 << bits) < p.size

          mask = (1 << bits) - 1
          index = (perm >> offset) & mask
          last &= index >= p.size - 1
          return true if index >= p.size

          offset += bits
        end

        if !recognizer.nil?
          if local_buffer.length > 1
            # first char is '[', if more than that this isn't the first rule
            local_buffer << ' '
          end

          atn = recognizer.getATN
          s = atn.states.get(state_number)
          ruleName = recognizer.rule_names[s.rule_index]
          local_buffer << ruleName
        elsif p.get_return_state(index) != EMPTY_RETURN_STATE
          unless p.empty?
            if local_buffer.length > 1
              # first char is '[', if more than that this isn't the first rule
              local_buffer << ' '
            end

            local_buffer << p.get_return_state(index)
          end
        end
        state_number = p.get_return_state(index)
        p = p.getParent(index)
      end
      local_buffer << ']'
      result.push(local_buffer.to_s)

      break if last

      perm += 1
    end
    false
  end
end
