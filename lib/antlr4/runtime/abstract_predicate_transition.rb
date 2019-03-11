require 'antlr4/runtime/transition'

module Antlr4::Runtime

  class AbstractPredicateTransition < Transition
    def initialize(target)
      super(target)
    end
  end

end