require '../antlr4/prediction_context'

class ArrayPredictionContext < PredictionContext
  attr_accessor :parents
  attr_accessor :return_states

  def initialize(parents, return_states = nil)
    if parents.is_a? SingletonPredictionContext
      return_states = [parents.return_state]
      parents = [parents.parent]
    end

    super(PredictionContextUtils.calculate_hash_code2(parents, return_states))
    @parents = parents
    @return_states = return_states
  end

  def empty? # since EMPTY_RETURN_STATE can only appear in the last position, we
    # don't need to verify that size==1
    @return_states[0] == EMPTY_RETURN_STATE
  end

  def size
    @return_states.length
  end

  def get_parent(index)
    @parents[index]
  end

  def get_return_state(index)
    @return_states[index]
  end

  def equals(o)
    if self == o
      return true
    elsif !(o.is_a? ArrayPredictionContext)
      return false
    end

    if hash != o.hash
      return false # can't be same if hash is different
    end

    (@return_states.eql? o.return_states) && (@parents.eql? o.parents)
  end

  def to_s
    return '[]' if empty?

    buf = ''
    buf << '['
    i = 0
    while i < @return_states.length
      buf << ', ' if i > 0
      if return_states[i] == EMPTY_RETURN_STATE
        buf << '$'
        i += 1
        next
      end
      buf << @return_states[i]
      if !@parents[i].nil?
        buf << ' '
        buf << @parents[i].to_s
      else
        buf << 'nil'
      end
      i += 1
    end

    buf << ']'
    buf.to_s
  end
end
