class Transition
  EPSILON = 1
  RANGE = 2
  RULE = 3
  PREDICATE = 4
  ATOM = 5
  ACTION = 6
  SET = 7
  NOT_SET = 8
  WILDCARD = 9
  PRECEDENCE = 10

  @@serialization_names = %w[INVALID EPSILON RANGE RULE PREDICATE ATOM ACTION SET NOT_SET WILDCARD PRECEDENCE]

  @@serialization_types = {}

  @@serialization_types[:EpsilonTransition] = EPSILON
  @@serialization_types[:RangeTransition] = RANGE
  @@serialization_types[:RuleTransition] = RULE
  @@serialization_types[:PredicateTransition] = PREDICATE
  @@serialization_types[:AtomTransition] = ATOM
  @@serialization_types[:ActionTransition] = ACTION
  @@serialization_types[:SetTransition] = SET
  @@serialization_types[:NotSetTransition] = NOT_SET
  @@serialization_types[:WildcardTransition] = WILDCARD
  @@serialization_types[:PrecedencePredicateTransition] = PRECEDENCE

  attr_accessor :target

  def initialize(target)
    raise 'target cannot be null.' if target.nil?

    @target = target
  end

  def epsilon?
    false
  end

  def label
    nil
  end

  def matches(symbol, min_vocab_symbol, max_vocab_symbol)
  end
end
