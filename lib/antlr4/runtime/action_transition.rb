require '../antlr4/transition'

class ActionTransition < Transition
  attr_reader :action_index

  def initialize(target, rule_index, action_index, is_ctx_dependent)
    super(target)
    @rule_index = rule_index
    @action_index = action_index
    @is_ctx_dependent = is_ctx_dependent
  end

  def serialization_type
    ACTION
  end

  def epsilon?
    true
  end

  def matches(_symbol, _min_vocab_symbol, _max_vocab_symbol)
    false
  end

  def to_s
    'action_' + @rule_index + ':' + @action_index
  end
end