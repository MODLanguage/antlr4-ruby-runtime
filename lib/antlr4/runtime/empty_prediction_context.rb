require '../antlr4/singleton_prediction_context'
require '../antlr4/prediction_context_utils'

class EmptyPredictionContext < SingletonPredictionContext
  def initialize(return_state)
    super(nil, return_state)
  end

  EMPTY = EmptyPredictionContext.new(PredictionContextUtils::EMPTY_RETURN_STATE)

  def isEmpty
    true
  end

  def size
    1
  end

  def parent(_index)
    nil
  end

  def return_state(_index)
    @return_state
  end

  def equals(o)
    self == o
  end

  def to_s
    '$'
  end
end
