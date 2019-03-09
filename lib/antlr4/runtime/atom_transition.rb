require '../antlr4/transition'

class AtomTransition < Transition
  attr_reader :the_label

  def initialize(target, label)
    super(target)
    @the_label = label
  end

  def serialization_type
    ATOM
  end

  def label
    IntervalSet.of(@the_label)
  end

  def matches(symbol, _min_vocab_symbol, _max_vocab_symbol)
    @the_label == symbol
  end

  def to_s
    '' + @the_label
  end
end
