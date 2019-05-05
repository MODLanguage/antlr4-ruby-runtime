module Antlr4::Runtime

  class RuleStopState < ATNState
    def initialize
      super
    end

    def state_type
      RULE_STOP
    end
  end
end