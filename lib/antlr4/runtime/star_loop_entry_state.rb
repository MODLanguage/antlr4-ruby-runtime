require '../antlr4/decision_state'

class StarLoopEntryState < DecisionState
  attr_accessor :loopback_state
  @loopback_state = nil

  attr_accessor :is_precedence_pecision
  @is_precedence_pecision = false

  def state_type
    STAR_LOOP_ENTRY
  end
end
