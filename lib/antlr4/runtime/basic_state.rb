module Antlr4::Runtime
  class BasicState < ATNState
    def initialize
      super
    end

    def state_type
      BASIC
    end
  end
end