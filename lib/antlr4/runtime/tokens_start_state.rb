require '../antlr4/decision_state'

class TokensStartState < DecisionState
  def initialize
    super
  end
  def state_type
    TOKEN_START
  end
end
