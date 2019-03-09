require '../antlr4/atn_simulator'
require '../antlr4/empty_prediction_context'
require '../antlr4/integer'
require '../antlr4/lexer_atn_config'
require '../antlr4/ordered_atn_config_set'
require '../antlr4/lexer_action_executor'

class LexerATNSimulator < ATNSimulator
  MIN_DFA_EDGE = 0
  MAX_DFA_EDGE = 127 # forces unicode to stay in ATN

  EMPTY = EmptyPredictionContext.new(Integer::MAX)

  class << self
    attr_reader :debug
  end

  class SimState
    attr_accessor :index
    attr_accessor :line
    attr_accessor :char_pos
    attr_accessor :dfa_state

    def reset
      @index = -1
      @line = 0
      @char_pos = -1
      @dfa_state = nil
    end
  end

  attr_reader :char_position_in_line
  attr_reader :line

  def initialize(recog, atn, decision_to_dfa, shared_context_cache)
    super(atn, shared_context_cache)
    @@debug = false
    @dfa_debug = false

    @decision_to_dfa = decision_to_dfa
    @recog = recog
    @start_index = -1
    @line = 1
    @char_position_in_line = 0
    @mode = Lexer::DEFAULT_MODE
    @prev_accept = SimState.new
    @match_calls = 0
  end

  def copy_state(simulator)
    @char_position_in_line = simulator.char_position_in_line
    @line = simulator.line
    @mode = simulator.mode
    @start_index = simulator.start_index
  end

  def match(input, mode)
    @match_calls += 1
    @mode = mode
    mark = input.mark

    begin
      @start_index = input.index
      @prev_accept.reset
      dfa = @decision_to_dfa[mode]
      if dfa.s0.nil?
        return match_atn(input)
      else
        return exec_atn(input, dfa.s0)
      end
    ensure
      input.release(mark)
    end
  end

  def reset
    @prev_accept.reset
    @start_index = -1
    @line = 1
    @char_position_in_line = 0
    @mode = Lexer.DEFAULT_MODE
  end

  def clear_dfa
    d = 0
    while d < @decision_to_dfa.length
      @decision_to_dfa[d] = DFA.new(atn.decision_state(d), d)
      d += 1
    end
  end

  def match_atn(input)
    start_state = atn.mode_to_start_state[@mode]

    printf format("matchATN mode %d start: %s\n", @mode, start_state) if @@debug

    old_mode = @mode

    s0_closure = compute_start_state(input, start_state)
    suppress_edge = s0_closure.has_semantic_context
    s0_closure.has_semantic_context = false

    next_state = add_dfa_state(s0_closure)
    @decision_to_dfa[@mode].s0 = next_state unless suppress_edge

    predict = exec_atn(input, next_state)

    if @@debug
      printf format("DFA after matchATN: %s\n", @decision_to_dfa[old_mode].to_lexer_string)
    end

    predict
  end

  def exec_atn(input, ds0)
    printf format("start state closure=%s\n", ds0.configs) if @@debug

    if ds0.is_accept_state
      # allow zero-length tokens
      capture_sim_state(@prev_accept, input, ds0)
    end

    t = input.la(1)

    s = ds0 # s is current/from DFA state

    loop do # while more work
      printf format("execATN loop starting closure: %s\n", s.configs) if @@debug

      # As we move src->trg, src->trg, we keep track of the previous trg to
      # avoid looking up the DFA state again, which is expensive.
      # If the previous target was already part of the DFA, we might
      # be able to avoid doing a reach operation upon t. If s!=nil,
      # it means that semantic predicates didn't prevent us from
      # creating a DFA state. Once we know s!=nil, we check to see if
      # the DFA state has an edge already for t. If so, we can just reuse
      # it's configuration set there's no point in re-computing it.
      # This is kind of like doing DFA simulation within the ATN
      # simulation because DFA simulation is really just a way to avoid
      # computing reach/closure sets. Technically, once we know that
      # we have a previously added DFA state, we could jump over to
      # the DFA simulator. But, that would mean popping back and forth
      # a lot and making things more complicated algorithmically.
      # This optimization makes a lot of sense for loops within DFA.
      # A character will take us back to an existing DFA state
      # that already has lots of edges out of it. e.g., .* in comments.
      target = existing_target_state(s, t)
      target = compute_target_state(input, s, t) if target.nil?

      break if target == ERROR

      # If this is a consumable input element, make sure to consume before
      # capturing the accept state so the input index, line, and char
      # position accurately reflect the state of the interpreter at the
      # end of the token.
      consume(input) if t != IntStream::EOF

      if target.is_accept_state
        capture_sim_state(@prev_accept, input, target)
        break if t == IntStream::EOF
      end

      t = input.la(1)
      s = target # flip current DFA target becomes new src/from state
    end

    fail_or_accept(@prev_accept, input, s.configs, t)
  end

  def existing_target_state(s, t)
    return nil if s.edges.nil? || t < MIN_DFA_EDGE || t > MAX_DFA_EDGE

    target = s.edges[t - MIN_DFA_EDGE]
    if @@debug && !target.nil?
      puts 'reuse state ' + s.state_number.to_s + ' edge to ' + target.state_number.to_s
    end

    target
  end

  def compute_target_state(input, s, t)
    reach = OrderedATNConfigSet.new

    # if we don't find an existing DFA state
    # Fill reach starting from closure, following t transitions
    reachable_config_set(input, s.configs, reach, t)

    if reach.empty? # we got nowhere on t from s
      unless reach.has_semantic_context
        # we got nowhere on t, don't throw out this knowledge it'd
        # cause a failover from DFA later.
        add_dfa_edge_dfastate_dfastate(s, t, ERROR)
      end

      # stop when we can't match any more char
      return ERROR
    end

    # Add an edge from s to target DFA found/created for reach
    add_dfa_edge_dfastate_atnconfigset(s, t, reach)
  end

  def fail_or_accept(prev_accept, input, _reach, t)
    if !prev_accept.dfa_state.nil?
      lexer_action_executor = prev_accept.dfa_state.lexer_action_executor
      accept(input, lexer_action_executor, @start_index, prev_accept.index, prev_accept.line, prev_accept.char_pos)
      prev_accept.dfa_state.prediction
    else # if no accept and EOF is first char, return EOF
      return Token::EOF if t == IntStream::EOF && input.index == @start_index

      raise LexerNoViableAltException, @recog
    end
  end

  def reachable_config_set(input, closure, reach, t) # this is used to skip processing for configs which have a lower priority
    # than a config that already reached an accept state for the same rule
    skip_alt = ATN::INVALID_ALT_NUMBER
    closure.configs.each do |c|
      current_alt_reached_accept_state = (c.alt == skip_alt)
      next if current_alt_reached_accept_state && c.passed_through_non_greedy_decision

      if @@debug
        printf format("testing %s at %s\n", token_name(t), c.to_s2(@recog, true))
      end

      n = c.state.number_of_transitions
      ti = 0
      while ti < n # for each transition
        trans = c.state.transition(ti)
        target = reachable_target(trans, t)
        unless target.nil?
          lexer_action_executor = c.lexer_action_executor
          unless lexer_action_executor.nil?
            lexer_action_executor = lexer_action_executor.fix_offset_before_match(input.index - start_index)
          end

          treat_eof_as_epsilon = (t == CharStream::EOF)
          cfg = LexerATNConfig.new
          cfg.lexer_atn_config4(c, target, lexer_action_executor)
          if closure(input, cfg, reach, current_alt_reached_accept_state, true, treat_eof_as_epsilon)
            # any remaining configs for this alt have a lower priority than
            # the one that just reached an accept state.
            skip_alt = c.alt
            break
          end
        end
        ti += 1
      end
    end
  end

  def accept(input, lexer_action_executor, start_index, index, line, char_pos)
    printf format("ACTION %s\n", lexer_action_executor) if @@debug

    # seek to after last char in token
    input.seek(index)
    @line = line
    @char_position_in_line = char_pos

    if !lexer_action_executor.nil? && !@recog.nil?
      lexer_action_executor.execute(@recog, input, start_index)
    end
  end

  def reachable_target(trans, t)
    if trans.matches(t, Lexer::MIN_CHAR_VALUE, Lexer::MAX_CHAR_VALUE)
      return trans.target
    end

    nil
  end

  def compute_start_state(input, p)
    initial_context = EMPTY
    configs = ATNConfigSet.new
    i = 0
    while i < p.number_of_transitions
      target = p.transition(i).target
      c = LexerATNConfig.new
      c.lexer_atn_config1(target, i + 1, initial_context)
      closure(input, c, configs, false, false, false)
      i += 1
    end
    configs
  end

  def closure(input, config, configs, current_alt_reached_accept_state, speculative, treat_eof_as_epsilon)
    if config.state.is_a? RuleStopState
      if @@debug
        if !@recog.nil?
          printf format("closure at %s rule stop %s\n", @recog.rule_names[config.state.rule_index], config)
        else
          printf format("closure at rule stop %s\n", config)
        end
      end

      if config.context.nil? || config.context.empty_path?
        if config.context.nil? || config.context.empty?
          configs.add(config)
          return true
        else
          configs.add(LexerATNConfig.create_from_config2(config, config.state, EmptyPredictionContext::EMPTY))
          current_alt_reached_accept_state = true
        end
      end

      if !config.context.nil? && !config.context.empty?
        i = 0
        while i < config.context.size
          if config.context.get_return_state(i) != PredictionContext::EMPTY_RETURN_STATE
            new_context = config.context.get_parent(i) # "pop" return state
            return_state = atn.states[config.context.get_return_state(i)]
            c = LexerATNConfig.new
            c.lexer_atn_config5(config, return_state, new_context)
            current_alt_reached_accept_state = closure(input, c, configs, current_alt_reached_accept_state, speculative, treat_eof_as_epsilon)
          end
          i += 1
        end
      end

      return current_alt_reached_accept_state
    end

    # optimization
    unless config.state.only_has_epsilon_transitions
      if !current_alt_reached_accept_state || !config.passed_through_non_greedy_decision
        configs.add(config)
      end
    end

    p = config.state
    i = 0
    while i < p.number_of_transitions
      t = p.transition(i)
      c = epsilon_target(input, config, t, configs, speculative, treat_eof_as_epsilon)
      unless c.nil?
        current_alt_reached_accept_state = closure(input, c, configs, current_alt_reached_accept_state, speculative, treat_eof_as_epsilon)
      end
      i += 1
    end

    current_alt_reached_accept_state
  end

  # side-effect: can alter configs.hasSemanticContext

  def epsilon_target(input, config, t, configs, speculative, treat_eof_as_epsilon)
    c = nil
    case t.serialization_type
    when Transition::RULE
      rule_transition = t
      new_context = SingletonPredictionContext.new(config.context, rule_transition.follow_state.state_number)
      c = LexerATNConfig.new
      c.lexer_atn_config5(config, t.target, new_context)

    when Transition::PRECEDENCE

      raise UnsupportedOperationException, 'Precedence predicates are not supported in lexers.'

    when Transition::PREDICATE
      pt = t
      puts('EVAL rule ' + pt.rule_index + ':' + pt.pred_index) if @@debug
      configs.has_semantic_context = true
      if evaluate_predicate(input, pt.rule_index, pt.pred_index, speculative)
        c = LexerATNConfig.create_from_config(config, t.target)
      end

    when Transition::ACTION

      if config.context.nil? || config.context.empty_path?
        # execute actions anywhere in the start rule for a token.
        #
        # TODO: if the entry rule is invoked recursively, some
        # actions may be executed during the recursive call. The
        # problem can appear when hasEmptyPath() is true but
        # isEmpty() is false. In this case, the config needs to be
        # split into two contexts - one with just the empty path
        # and another with everything but the empty path.
        # Unfortunately, the current algorithm does not allow
        # getEpsilonTarget to return two configurations, so
        # additional modifications are needed before we can support
        # the split operation.
        lexer_action_executor = LexerActionExecutor.append(config.lexer_action_executor, @atn._a[t.action_index])
        c = LexerATNConfig.new
        c.lexer_atn_config4(config, t.target, lexer_action_executor)
      else # ignore actions in referenced rules
        c = LexerATNConfig.new
        c.lexer_atn_config3(config, t.target)
      end

    when Transition::EPSILON
      c = LexerATNConfig.new
      c.lexer_atn_config3(config, t.target)
    when Transition::ATOM, Transition::RANGE, Transition::SET
      if treat_eof_as_epsilon
        if t.matches(CharStream.EOF, Lexer.MIN_CHAR_VALUE, Lexer.MAX_CHAR_VALUE)
          c = LexerATNConfig.create_from_config(config, t.target)
        end
      end

    else
      # empty
    end

    c
  end

  def evaluate_predicate(input, rule_index, pred_index, speculative) # assume true if no recognizer was provided
    return true if @recog.nil?

    return @recog.sempred(nil, rule_index, pred_index) unless speculative

    saved_char_position_in_line = @char_position_in_line
    saved_line = @line
    index = input.index
    marker = input.mark
    begin
      consume(input)
      return @recog.sempred(nil, rule_index, pred_index)
    ensure
      @char_position_in_line = saved_char_position_in_line
      @line = saved_line
      input.seek(index)
      input.release(marker)
    end
  end

  def capture_sim_state(settings, input, dfa_state)
    settings.index = input.index
    settings.line = @line
    settings.char_pos = @char_position_in_line
    settings.dfa_state = dfa_state
  end

  def add_dfa_edge_dfastate_atnconfigset(from, t, q)
    suppress_edge = q.has_semantic_context
    q.has_semantic_context = false

    to = add_dfa_state(q)

    return to if suppress_edge

    add_dfa_edge_dfastate_dfastate(from, t, to)
    to
  end

  def add_dfa_edge_dfastate_dfastate(p, t, q)
    if t < MIN_DFA_EDGE || t > MAX_DFA_EDGE
      # Only track edges within the DFA bounds
      return
    end

    if @@debug
      message = 'EDGE ' << p.to_s << ' -> ' << q.to_s << ' upon ' << t
      puts(message)
    end

    if p.edges.nil?
      #  make room for tokens 1..n and -1 masquerading as index 0
      p.edges = []
    end
    p.edges[t - MIN_DFA_EDGE] = q # connect
  end

  def add_dfa_state(configs)
    proposed = DFAState.new(configs)
    first_config_with_rule_stop_state = configs.find_first_rule_stop_state

    unless first_config_with_rule_stop_state.nil?
      proposed.is_accept_state = true
      proposed.lexer_action_executor = first_config_with_rule_stop_state.lexer_action_executor
      proposed.prediction = atn.rule_to_token_type[first_config_with_rule_stop_state.state.rule_index]
    end

    dfa = @decision_to_dfa[@mode]

    existing = dfa.states[proposed]
    return existing unless existing.nil?

    new_state = proposed

    new_state.state_number = dfa.states.size
    configs.readonly = true
    new_state.configs = configs
    dfa.states[new_state] = new_state
    new_state
  end

  def dfa(mode)
    @decision_to_dfa[mode]
  end

  def text(input) # index is first lookahead char, don' t include.
    input.text(Interval.of(start_index, input.index - 1))
  end

  def consume(input)
    cur_char = input.la(1)
    if cur_char == '\n'
      @line += 1
      @char_position_in_line = 0
    else
      @char_position_in_line += 1
    end
    input.consume
  end

  def token_name(t)
    return 'EOF' if t == -1

    # if ( atn.g!=nil ) return atn.g.getTokenDisplayName(t)
    "'" + t.to_s + "'"
  end
end
