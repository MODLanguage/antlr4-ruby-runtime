require '../antlr4/ll1_analyzer'

class IllegalArgumentException < RuntimeError
end

class ATN
  INVALID_ALT_NUMBER = 0

  attr_accessor :states
  attr_accessor :grammar_type
  attr_accessor :rule_to_token_type
  attr_accessor :rule_to_start_state
  attr_accessor :rule_to_stop_state
  attr_accessor :mode_name_to_start_state
  attr_accessor :mode_to_start_state
  attr_accessor :decision_to_state
  attr_accessor :_a
  attr_accessor :max_token_type

  def initialize(grammar_type, max_token_type)
    @states = []
    @decision_to_state = []
    @rule_to_start_state = []
    @rule_to_stop_state = []
    @mode_name_to_start_state = {}
    @grammar_type = grammar_type
    @max_token_type = max_token_type
    @rule_to_token_type = []
    @_a = []
    @mode_to_start_state = []
  end

  def next_tokens_ctx(s, ctx)
    LL1Analyzer.new(self).look(s, nil, ctx)
  end

  def next_tokens(s)
    return s.next_token_within_rule unless s.next_token_within_rule.nil?

    s.next_token_within_rule = next_tokens_ctx(s, nil)
    s.next_token_within_rule.readonly(true)
    s.next_token_within_rule
  end

  def add_state(state)
    unless state.nil?
      state.atn = self
      state.state_number = @states.length
    end

    @states << state
  end

  def remove_state(state)
    @states[state.state_number] = nil
  end

  def define_decision_state(s)
    @decision_to_state << s
    s.decision = @decision_to_state.length - 1
  end

  def decision_state(decision)
    @decision_to_state[decision] unless @decision_to_state.empty?
  end

  def number_of_decisions
    @decision_to_state.length
  end

  def expected_tokens(state_number, context)
    if state_number < 0 || state_number >= @states.length
      raise IllegalArgumentException, 'Invalid state number.'
    end

    ctx = context
    s = @states[state_number]
    following = next_tokens(s)
    return following unless following.contains(Token::EPSILON)

    expected = IntervalSet.new
    expected.concat(following)
    expected.delete(Token::EPSILON)
    while !ctx.nil? && ctx.invoking_state >= 0 && following.include?(Token::EPSILON)
      invoking_state = @states[ctx.invoking_state]
      rt = invoking_state.transition(0)
      following = next_tokens(rt.follow_state)
      expected.add_all(following)
      expected.remove(Token::EPSILON)
      ctx = ctx.parent
    end

    expected << Token::EOF if following.include?(Token::EPSILON)

    expected
  end
end
