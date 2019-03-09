require '../antlr4/transition'

class RangeTransition < Transition
  attr_reader :from
  attr_reader :to

  def initialize(target, from, to)
    super(target)
    @from = from
    @to = to
  end

  def serialization_type
    RANGE
  end

  def label
    IntervalSet.of(@from, @to)
  end

  def matches(symbol, _min_vocab_symbol, _max_vocab_symbol)
    symbol >= @from && symbol <= @to
  end

  def to_s
    "'" << @from << "'..'" << @to << "'"
  end
end
