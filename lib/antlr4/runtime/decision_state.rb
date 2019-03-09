require '../antlr4/atn_state'

class DecisionState < ATNState
  attr_accessor :decision
  attr_accessor :non_greedy

  def initialize
    super
    @decision = -1
    @non_greedy = false
  end
end
