require '../antlr4/abstract_predicate_transition'

class PrecedencePredicateTransition < AbstractPredicateTransition
  attr_reader :precedence

  def initialize(target, precedence)
    super(target)
    @precedence = precedence
  end

  def serialization_type
    PRECEDENCE
  end

  def epsilon?
    true
  end

  def matches(_symbol, _min_vocab_symbol, _max_vocab_symbol)
    false
  end

  def predicate
    SemanticContext.PrecedencePredicate.new(@precedence)
  end

  def to_s
    @precedence + ' >= _p'
  end
end
