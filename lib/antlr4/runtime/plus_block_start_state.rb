module Antlr4::Runtime

  class PlusBlockStartState < BlockStartState
    attr_accessor :loopback_state
    @loopback_state = nil

    def state_type
      PLUS_BLOCK_START
    end
  end
end