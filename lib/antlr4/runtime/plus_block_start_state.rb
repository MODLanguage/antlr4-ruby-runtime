require '../antlr4/block_start_state'

class PlusBlockStartState < BlockStartState
  attr_accessor :loopback_state
  @loopback_state = nil

  def state_type
    PLUS_BLOCK_START
  end
end
