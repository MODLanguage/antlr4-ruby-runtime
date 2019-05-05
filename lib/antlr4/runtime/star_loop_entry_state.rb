module Antlr4::Runtime

  class StarLoopEntryState < DecisionState
    attr_accessor :loopback_state
    attr_accessor :is_precedence_pecision

    def initialize
      super
      @loopback_state = nil
      @is_precedence_pecision = false
    end

    def state_type
      STAR_LOOP_ENTRY
    end
  end
end