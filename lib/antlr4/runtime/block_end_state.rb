module Antlr4::Runtime

  class BlockEndState < ATNState
    attr_accessor :start_state
    @start_state = nil

    def state_type
      BLOCK_END
    end
  end
end