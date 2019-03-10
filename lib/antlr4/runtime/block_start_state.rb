require 'antlr4/runtime/decision_state'

module Antlr4::Runtime
  class BlockStartState < DecisionState
    attr_accessor :end_state
    @end_state = nil
  end
end