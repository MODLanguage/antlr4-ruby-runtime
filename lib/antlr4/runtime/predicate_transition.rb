require '../antlr4/abstract_predicate_transition'
require '../antlr4/semantic_context'

class PredicateTransition < AbstractPredicateTransition
  attr_reader :rule_index
  attr_reader :pred_index
  attr_reader :is_ctx_dependent # e.g., $i ref in pred

  def initialize(target, rule_index, pred_index, is_ctx_dependent)
    super(target)
    @rule_index = rule_index
    @pred_index = pred_index
    @is_ctx_dependent = is_ctx_dependent
  end

  def serialization_type
    PREDICATE
  end

  def epsilon?
    true
  end

  def matches(_symbol, _min_vocab_symbol, _max_vocab_symbol)
    false
  end

  def predicate
    SemanticContext::Predicate.new(@rule_index, @pred_index, @is_ctx_dependent)
  end

  def to_s
    'pred_' + @rule_index + ':' + @pred_index
  end
end
