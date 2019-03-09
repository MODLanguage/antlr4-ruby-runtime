require '../antlr4/atn_state'

class StarLoopbackState < ATNState
  def loop_entry_state
    transition(0).target
  end

  def state_type
    STAR_LOOP_BACK
  end
end
