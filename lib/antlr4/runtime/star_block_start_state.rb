require '../antlr4/block_start_state'

class StarBlockStartState < BlockStartState
  def state_type
    STAR_BLOCK_START
  end
end
