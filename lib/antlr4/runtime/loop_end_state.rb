module Antlr4::Runtime

  class LoopEndState < ATNState
    attr_accessor :loopback_state

    def initialize
      super
      @loopback_state = nil
    end

    def state_type
      LOOP_END
    end
  end
end