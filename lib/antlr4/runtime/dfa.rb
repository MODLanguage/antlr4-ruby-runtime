require '../antlr4/lexer_dfa_serializer'
require '../antlr4/dfa_serializer'

class DFA
  attr_accessor :states
  attr_accessor :s0
  attr_reader :decision
  attr_reader :atn_start_state

  def initialize(atn_start_state, decision = 0)
    @atn_start_state = atn_start_state
    @decision = decision
    @states = {}

    precedence_dfa = false
    if atn_start_state.is_a? StarLoopEntryState
      if atn_start_state.is_precedence_pecision
        precedence_dfa = true
        precedence_state = DFAState.new(ATNConfigSet.new)
        precedence_state.edges = []
        precedence_state.is_accept_state = false
        precedence_state.requiresFullContext = false
        @s0 = precedence_state
      end
    end

    @precedence_dfa = precedence_dfa
  end

  def precedence_dfa?
    @precedence_dfa
  end

  def precedence_start_state(precedence)
    unless precedence_dfa?
      raise IllegalStateException, 'Only precedence DFAs may contain a precedence start state.'
    end

    # s0.edges is never nil for a precedence DFA
    return nil if precedence < 0 || precedence >= @s0.edges.length

    @s0.edges[precedence]
  end

  def precedence_start_state2(precedence, start_state)
    unless precedence_dfa?
      raise IllegalStateException, 'Only precedence DFAs may contain a precedence start state.'
    end

    return if precedence < 0

    @s0.edges[precedence] = start_state
  end

  def precedence_dfa(precedence_dfa)
    if precedence_dfa != precedence_dfa?
      raise UnsupportedOperationException, 'The precedence_dfa field cannot change after a DFA is constructed.'
    end
  end

  def get_states
    result = @states.keys
    result.sort! { |i, j| i.state_number - j.state_number }

    result
  end

  def to_s
    to_s2(VocabularyImpl.EMPTY_VOCABULARY)
  end

  def to_s1(token_names)
    return '' if @s0.nil?

    serializer = DFASerializer.new
    serializer.init_from_token_names(self, token_names)
    serializer.to_s
  end

  def to_s2(vocabulary)
    return '' if @s0.nil?

    serializer = DFASerializer.new
    serializer.init_from_vocabulary(self, vocabulary)
    serializer.to_s
  end

  def to_lexer_string
    return '' if @s0.nil?

    serializer = LexerDFASerializer.new(self)
    serializer.to_s
  end
end
