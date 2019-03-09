require '../antlr4/recognizer'
require '../antlr4/parse_tree_listener'
require '../antlr4/default_error_strategy'
require '../antlr4/atn_deserializer'
require '../antlr4/vocabulary_impl'
require '../antlr4/error_node_impl'
require 'singleton'

class Parser < Recognizer
  class TraceListener < ParseTreeListener
    def initialize(parser, input)
      @parser = parser
      @_input = input
    end

    def enter_every_rule(ctx)
      puts('enter   ' << @parser.rule_names[ctx.rule_index] << ', lt(1)=' << @_input.lt(1).text)
    end

    def visit_terminal(node, ctx)
      puts('consume ' << node.getSymbol.to_s << ' rule ' << @parser.rule_names[ctx.rule_index].to_s)
    end

    def visit_error_node(_node)
    end

    def exit_every_rule(ctx)
      puts('exit    ' << @parser.rule_names[ctx.rule_index] << ', lt(1)=' << @_input.lt(1).text)
    end
  end

  class TrimToSizeListener < ParseTreeListener
    include Singleton

    def enter_every_rule(_ctx)
    end

    def visit_terminal(_node, _ctx)
    end

    def visit_error_node(_node)
    end

    def exit_every_rule(ctx)
      ctx.children.trimToSize if ctx.children.is_a? ArrayList
    end
  end

  attr_accessor :_ctx
  attr_reader :_input

  @@bypass_alts_atn_cache = {}

  def initialize(input)
    super()
    @_err_handler = DefaultErrorStrategy.new
    @_input = nil
    @_precedence_stack = []
    @_precedence_stack.push(0)
    @_ctx = nil
    @_build_parse_trees = true
    @_tracer = nil
    @_parse_listeners = nil
    @_syntax_errors = nil
    @matched_eof = nil
    set_token_stream(input)
  end

  def reset
    @_input.seek(0) unless @_input.nil?
    @_err_handler.reset(self)
    @_ctx = nil
    @_syntax_errors = 0
    @matched_eof = false
    set_trace(false)
    @_precedence_stack.clear
    @_precedence_stack.push(0)
    interpreter = @_interp
    interpreter.reset unless interpreter.nil?
  end

  def match(ttype)
    t = current_token
    if t.type == ttype
      @matched_eof = true if ttype == Token::EOF
      @_err_handler.report_match(self)
      consume
    else
      t = @_err_handler.recover_in_line(self)
      if @_build_parse_trees && t.index == -1
        # we must have conjured up a new token during single token insertion
        # if it's not the current symbol
        @_ctx.add_error_node(create_error_node(@_ctx, t))
      end
    end

    t
  end

  def match_wildcard
    t = current_token
    if t.type > 0
      @_err_handler.report_match(this)
      consume
    else
      t = @_err_handler.recover_in_line(this)
      if @_build_parse_trees && t.token_index == -1
        # we must have conjured up a new token during single token insertion
        # if it's not the current symbol
        @_ctx.add_error_node(create_error_node(@_ctx, t))
      end
    end

    t
  end

  def set_trim_parse_tree(trimParseTrees)
    if trimParseTrees
      return if get_trim_parse_tree

      add_parse_listener(TrimToSizeListener.INSTANCE)
    else
      remove_parse_listener(TrimToSizeListener.INSTANCE)
    end
  end

  def get_trim_parse_tree
    get_parse_listeners.contains(TrimToSizeListener.INSTANCE)
  end

  def get_parse_listeners
    listeners = @_parse_listeners
    return [] if listeners.nil?

    listeners
  end

  def add_parse_listener(listener)
    raise nilPointerException, 'listener' if listener.nil?

    @_parse_listeners = [] if @_parse_listeners.nil?

    @_parse_listeners << listener
  end

  def remove_parse_listener(listener)
    unless @_parse_listeners.nil?
      if @_parse_listeners.remove(listener)
        @_parse_listeners = nil if @_parse_listeners.empty?
      end
    end
  end

  def remove_parse_listeners
    @_parse_listeners = nil
  end

  def trigger_enter_rule_event
    @_parse_listeners.each do |listener|
      listener.enter_every_rule(@_ctx)
      @_ctx.enter_rule(listener)
    end
  end

  def trigger_exit_rule_event # reverse order walk of listeners
    i = @_parse_listeners.length - 1
    while i >= 0

      listener = @_parse_listeners[i]
      @_ctx.exit_rule(listener)
      listener.exit_every_rule(@_ctx)
      i -= 1
    end
  end

  def token_factory
    @_input.token_source.token_factory
  end

  def set_token_factory(factory)
    @_input.token_source.set_token_factory(factory)
  end

  def get_atn_with_bypass_alts
    serialized_atn = get_serialized_atn
    if serialized_atn.nil?
      raise UnsupportedOperationException, 'The current parser does not support an ATN with bypass alternatives.'
    end

    result = @@bypass_alts_atn_cache.get(serialized_atn)
    if result.nil?
      deserialization_options = ATNDeserializationOptions.new
      deserialization_options.generate_rule_bypass_transitions(true)
      result = ATNDeserializer.new(deserialization_options).deserialize(serialized_atn)
      @@bypass_alts_atn_cache.put(serialized_atn, result)
    end

    result
  end

  def compile_parse_tree_pattern1(pattern, patter_rule_index)
    unless getTokenStream.nil?
      token_source = getTokenStream.token_source
      if token_source.is_a? Lexer
        lexer = token_source
        return compile_parse_tree_pattern2(pattern, patter_rule_index, lexer)
      end
    end
    raise UnsupportedOperationException, "Parser can't discover a lexer to use"
  end

  def compile_parse_tree_pattern2(pattern, patternRuleIndex, lexer)
    m = ParseTreePatternMatcher.new(lexer, self)
    m.compile(pattern, patternRuleIndex)
  end

  def set_token_stream(input)
    @_input = nil
    reset
    @_input = input
  end

  def current_token
    @_input.lt(1)
  end

  def notify_error_listeners_simple(msg)
    notify_error_listeners(current_token, msg, nil)
  end

  def notify_error_listeners(offending_token, msg, e)
    @_syntax_errors += 1
    line = offending_token.line
    char_position_in_line = offending_token.char_position_in_line

    listener = error_listener_dispatch
    listener.syntax_error(self, offending_token, line, char_position_in_line, msg, e)
  end

  def consume
    o = current_token
    @_input.consume if o.type != EOF
    has_listener = !@_parse_listeners.nil? && !@_parse_listeners.empty?
    if @_build_parse_trees || has_listener
      if @_err_handler.in_error_recovery_mode(self)
        node = @_ctx.add_error_node(create_error_node(@_ctx, o))
        unless @_parse_listeners.nil?
          @_parse_listeners.each do |listener|
            listener.visit_error_node(node)
          end
        end
      else
        node = @_ctx.add_child_terminal_node(create_terminal_node(@_ctx, o))
        unless @_parse_listeners.nil?
          @_parse_listeners.each do |listener|
            listener.visit_terminal(node, @_ctx)
          end
        end
      end
    end

    o
  end

  def create_terminal_node(_parent, t)
    TerminalNodeImpl.new(t)
  end

  def create_error_node(_parent, t)
    ErrorNodeImpl.new(t)
  end

  def add_context_to_parse_tree
    parent = @_ctx.parent
    # add current context to parent if we have a parent
    parent.add_child_rule_invocation(@_ctx) unless parent.nil?
  end

  def enter_rule(local_ctx, state, _rule_index)
    @_state_number = state
    @_ctx = local_ctx
    @_ctx.start = @_input.lt(1)
    add_context_to_parse_tree if @_build_parse_trees
    trigger_enter_rule_event unless @_parse_listeners.nil?
  end

  def exit_rule
    if @matched_eof
      # if we have matched EOF, it cannot consume past EOF so we use lt(1) here
      @_ctx.stop = @_input.lt(1) # lt(1) will be end of file
    else
      @_ctx.stop = @_input.lt(-1) # stop node is what we just matched
    end

    # trigger event on @_ctx, before it reverts to parent
    trigger_exit_rule_event unless @_parse_listeners.nil?
    @_state_number = @_ctx.invoking_state
    @_ctx = @_ctx.parent
  end

  def enter_outer_alt(local_ctx, alt_num)
    local_ctx.set_alt_number(alt_num)
    # if we have new local_ctx, make sure we replace existing ctx
    # that is previous child of parse tree
    if @_build_parse_trees && @_ctx != local_ctx
      parent = @_ctx.parent
      unless parent.nil?
        parent.remove_last_child
        parent.addChild(local_ctx)
      end
    end
    @_ctx = local_ctx
  end

  def precedence
    return -1 if @_precedence_stack.empty?

    @_precedence_stack.peek
  end

  def enter_recursion_rule(local_ctx, state, _rule_index, precedence)
    setState(state)
    @_precedence_stack.push(precedence)
    @_ctx = local_ctx
    @_ctx.start = @_input.lt(1)
    unless @_parse_listeners.nil?
      trigger_enter_rule_event # simulates rule entry for left-recursive rules
    end
  end

  def push_new_recursion_context(local_ctx, state, _rule_index)
    previous = @_ctx
    previous.parent = local_ctx
    previous.invoking_state = state
    previous.stop = @_input.lt(-1)

    @_ctx = local_ctx
    @_ctx.start = previous.start
    @_ctx.addChild(previous) if @_build_parse_trees

    unless @_parse_listeners.nil?
      trigger_enter_rule_event # simulates rule entry for left-recursive rules
    end
  end

  def unroll_recursion_contexts(_parent_ctx)
    @_precedence_stack.pop
    @_ctx.stop = @_input.lt(-1)
    retctx = @_ctx # save current ctx (return value)

    # unroll so @_ctx is as it was before call to recursive method
    if !@_parse_listeners.nil?
      while @_ctx != _parent_ctx
        trigger_exit_rule_event
        @_ctx = @_ctx.parent
      end

    else
      _ctx = _parent_ctx
    end

    # hook into tree
    retctx.parent = _parent_ctx

    if @_build_parse_trees && !_parent_ctx.nil?
      # add return ctx into invoking rule's tree
      _parent_ctx.addChild(retctx)
    end
  end

  def invoking_context(rule_index)
    p = @_ctx
    until p.nil?
      return p if p.rule_index == rule_index

      p = p.parent
    end
    nil
  end

  def precpred(_localctx, precedence)
    precedence >= @_precedence_stack.peek
  end

  def in_context?(_context)
    false
  end

  def expected_token?(symbol)
    atn = @_interp.atn
    ctx = @_ctx
    s = atn.states.get(getState)
    following = atn.next_tokens(s)
    return true if following.include?(symbol)

    return false unless following.contains(Token::EPSILON)

    while !ctx.nil? && ctx.invoking_state >= 0 && following.include?(Token::EPSILON)
      invoking_state = atn.states.get(ctx.invoking_state)
      rt = invoking_state.transition(0)
      following = atn.next_tokens(rt.follow_state)
      return true if following.include?(symbol)

      ctx = ctx.parent
    end

    return true if following.include?(Token::EPSILON) && symbol == Token::EOF

    false
  end

  def matched_eof?
    @matched_eof
  end

  def expected_tokens
    getATN.expected_tokens(getState, getContext)
  end

  def expected_tokens_within_current_rule
    atn = @_interp.atn
    s = atn.states.get(getState)
    atn.next_tokens(s)
  end

  def rule_index(rule_name)
    index = get_rule_index_map.get(rule_name)
    return index unless index.nil?

    -1
  end

  def rule_invocation_stack1
    rule_invocation_stack2(@_ctx)
  end

  def rule_invocation_stack2(p)
    rule_names = rule_names
    stack = []
    until p.nil?
      # compute what follows who invoked us
      rule_index = p.rule_index
      if rule_index < 0
        stack.push('n/a')
      else
        stack.push(rule_names[rule_index])
      end
      p = p.parent
    end
    stack
  end

  def dfa_strings
    s = []
    d = 0
    while d < @_interp.decision_to_dfa.length
      dfa = @_interp.decision_to_dfa[d]
      s.push(dfa.to_s(get_vocabulary))
      d += 1
    end
    s
  end

  def dump_dfa
    seen_one = false
    d = 0
    while d < @_interp.decision_to_dfa.length
      dfa = @_interp.decision_to_dfa[d]
      unless dfa.states.empty?
        puts if seen_one
        puts('Decision ' << dfa.decision << ':')
        puts(dfa.to_s(get_vocabulary))
        seen_one = true
      end
      d += 1
    end
  end

  def source_name
    @_input.get_source_name
  end

  def parse_info
    interp = @_interp
    return ParseInfo.new(interp) if interp.is_a? ProfilingATNSimulator

    nil
  end

  def set_profile(profile)
    interp = @_interp
    save_mode = interp.getPredictionMode
    if profile
      unless interp.is_a? ProfilingATNSimulator
        @_interp = ProfilingATNSimulator.new(self)
      end
    elsif @_interp.is_a? ProfilingATNSimulator
      sim = ParserATNSimulator.new(self, atn, interp.decision_to_dfa, interp.shared_context_cache)
      @_interp = sim
    end
    @_interp.setPredictionMode(save_mode)
  end

  def set_trace(trace)
    if !trace
      remove_parse_listener(@_tracer)
      @_tracer = nil
    else
      if !@_tracer.nil?
        remove_parse_listener(@_tracer)
      else
        @_tracer = new TraceListener
      end
      add_parse_listener(@_tracer)
    end
  end

  def trace?
    !@_tracer.nil?
  end
end
