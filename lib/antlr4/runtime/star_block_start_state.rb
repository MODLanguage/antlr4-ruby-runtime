module Antlr4::Runtime

  class StarBlockStartState < BlockStartState
    def state_type
      STAR_BLOCK_START
    end
  end
end