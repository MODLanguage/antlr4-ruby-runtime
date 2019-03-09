require '../antlr4/block_start_state'

class BasicBlockStartState < BlockStartState
  def state_type
    BLOCK_START
  end
end
