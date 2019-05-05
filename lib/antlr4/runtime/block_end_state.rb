module Antlr4::Runtime

  class BlockEndState < ATNState
    attr_accessor :start_state

    def initialize
      super
      @start_state = nil
    end

    def state_type
      BLOCK_END
    end
  end
end