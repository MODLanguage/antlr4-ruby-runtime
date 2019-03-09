require '../antlr4/set_transition'

class NotSetTransition < SetTransition
  def initialize(target, set)
    super(target, set)
  end

  def serialization_type
    NOT_SET
  end

  def matches(symbol, min_vocab_symbol, max_vocab_symbol)
    (symbol >= min_vocab_symbol) && (symbol <= max_vocab_symbol) && !super
  end

  def to_s
    '~' + super.to_s
  end
end
