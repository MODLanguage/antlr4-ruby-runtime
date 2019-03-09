require '../antlr4/atn_state'

class RuleStartState < ATNState
  attr_accessor :stop_state
  @stop_state = nil
  attr_accessor :is_left_recursive_rule
  @is_left_recursive_rule = false

  def state_type
    RULE_START
  end
end
