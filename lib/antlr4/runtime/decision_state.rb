require 'antlr4/runtime/atn_state'

module Antlr4::Runtime

  class DecisionState < ATNState
    attr_accessor :decision
    attr_accessor :non_greedy

    def initialize
      super
      @decision = -1
      @non_greedy = false
    end
  end
end