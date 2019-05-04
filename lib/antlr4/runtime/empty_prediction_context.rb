require 'antlr4/runtime/singleton_prediction_context'
module Antlr4::Runtime

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

    def parent(_index=nil)
      nil
    end

    def return_state(_index=nil)
      @return_state
    end

    def equals(o)
      self == o
    end

    def to_s
      '$'
    end
  end
end