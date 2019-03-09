require '../antlr4/transition'

class RuleTransition < Transition
  attr_reader :rule_index # no Rule object at runtime

  attr_reader :precedence

  attr_reader :follow_state

  def initialize(rule_start, rule_index, precedence, follow_state)
    super(rule_start)
    @rule_index = rule_index
    @precedence = precedence
    @follow_state = follow_state
  end

  def serialization_type
    RULE
  end

  def epsilon?
    true
  end

  def matches(_symbol, _min_vocab_symbol, _max_vocab_symbol)
    false
  end
end
