require '../antlr4/atn_state'

class LoopEndState < ATNState
  attr_accessor :loopback_state
  @loopback_state = nil

  def state_type
    LOOP_END
  end
end
