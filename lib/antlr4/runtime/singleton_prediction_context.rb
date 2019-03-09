require '../antlr4/prediction_context_utils'
require '../antlr4/prediction_context'
require '../antlr4/murmur_hash'

class SingletonPredictionContext < PredictionContext
  attr_accessor :parent
  attr_accessor :return_state

  def initialize(parent, return_state)
    super(!parent.nil? ? PredictionContextUtils.calculate_hash_code1(parent, return_state) : PredictionContextUtils.calculate_empty_hash_code)
    @parent = parent
    @return_state = return_state
  end

  def get_parent(_i)
    @parent
  end

  def size
    1
  end

  def empty?
    @return_state == EMPTY_RETURN_STATE
  end

  def get_return_state(_index)
    @return_state
  end

  def equals(other)
    if self == other
      return true
    elsif !(other.is_a? SingletonPredictionContext)
      return false
    end

    if hash != other.hash
      return false # can't be same if hash is different
    end

    @return_state == other.return_state && (!@parent.nil? && @parent.eql?(other.parent))
  end

  def to_s
    up = !@parent.nil? ? @parent.to_s : ''
    if up.empty?
      return '$' if @return_state == EMPTY_RETURN_STATE

      return @return_state.to_s
    end
    @return_state.to_s + ' ' + up
  end
end
