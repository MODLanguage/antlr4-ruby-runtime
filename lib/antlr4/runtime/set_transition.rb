require '../antlr4/transition'

class SetTransition < Transition
  attr_reader :set

  def initialize(target, set)
    super(target)
    set = IntervalSet.of(Token::INVALID_TYPE) if set.nil?

    @set = set
  end

  def serialization_type
    SET
  end

  def label
    @set
  end

  def matches(symbol, _min_vocab_symbol, _max_vocab_symbol)
    @set.contains(symbol)
  end

  def to_s
    @set.to_s
  end
end
