require '../antlr4/transition'

class EpsilonTransition < Transition
  def initialize(target, outermost_precedence_return = -1)
    super(target)
    @outermost_precedence_return = outermost_precedence_return
  end

  attr_reader :outermost_precedence_return

  def serialization_type
    EPSILON
  end

  def epsilon?
    true
  end

  def matches(_symbol, _min_vocab_symbol, _max_vocab_symbol)
    false
  end

  def to_s
    'epsilon'
  end
end
