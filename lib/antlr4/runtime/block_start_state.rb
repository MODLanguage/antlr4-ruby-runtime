require '../antlr4/decision_state'
class BlockStartState < DecisionState
  attr_accessor :end_state
  @end_state = nil
end
