module Antlr4::Runtime

  class BasicBlockStartState < BlockStartState
    def initialize
      super
    end

    def state_type
      BLOCK_START
    end
  end
end