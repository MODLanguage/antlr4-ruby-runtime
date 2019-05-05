module Antlr4::Runtime

  class PlusLoopbackState < DecisionState
    def initialize
      super
    end

    def state_type
      PLUS_LOOP_BACK
    end
  end
end