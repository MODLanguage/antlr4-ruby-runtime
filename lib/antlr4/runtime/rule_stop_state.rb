require '../antlr4/atn_state'

class RuleStopState < ATNState
  def state_type
    RULE_STOP
  end
end
