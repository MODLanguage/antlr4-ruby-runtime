module Antlr4::Runtime

  class RuleStartState < ATNState
    attr_accessor :stop_state
    attr_accessor :is_left_recursive_rule

    def initialize
      super
      @is_left_recursive_rule = false
      @stop_state = nil
    end

    def state_type
      RULE_START
    end
  end
end