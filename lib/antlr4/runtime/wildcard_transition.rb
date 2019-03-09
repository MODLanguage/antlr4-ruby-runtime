require '../antlr4/transition'

class WildcardTransition < Transition
  def initialize(target)
    super(target)
  end

  def serialization_type
    WILDCARD
  end

  def matches(symbol, min_vocab_symbol, max_vocab_symbol)
    symbol >= min_vocab_symbol && symbol <= max_vocab_symbol
  end

  def to_s
    '.'
  end
end
