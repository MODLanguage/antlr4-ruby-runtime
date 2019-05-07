module Antlr4::Runtime

  class TokensStartState < DecisionState
    def initialize
      super
    end

    def state_type
      TOKEN_START
    end
  end
end
