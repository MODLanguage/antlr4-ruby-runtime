module Antlr4::Runtime

  class StarBlockStartState < BlockStartState
    def initialize
      super
    end

    def state_type
      STAR_BLOCK_START
    end
  end
end