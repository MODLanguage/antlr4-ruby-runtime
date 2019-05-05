module Antlr4::Runtime

  class StarLoopbackState < ATNState
    def initialize
      super
    end

    def loop_entry_state
      transition(0).target
    end

    def state_type
      STAR_LOOP_BACK
    end
  end
end