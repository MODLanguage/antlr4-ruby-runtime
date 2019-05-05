require 'antlr4/runtime/decision_state'

module Antlr4::Runtime
  class BlockStartState < DecisionState
    attr_accessor :end_state

    def initialize
      super
      @end_state = nil
    end
  end
end