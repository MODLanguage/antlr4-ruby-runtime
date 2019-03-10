module Antlr4::Runtime

  class BasicBlockStartState < BlockStartState
    def state_type
      BLOCK_START
    end
  end
end