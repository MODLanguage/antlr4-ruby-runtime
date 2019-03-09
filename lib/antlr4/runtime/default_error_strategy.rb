require '../antlr4/antlr_error_strategy'
require '../antlr4/no_viable_alt_exception'
require '../antlr4/input_mismatch_exception'

class DefaultErrorStrategy < ANTLRErrorStrategy
  def initialize
    @error_recovery_mode = false
    @last_error_index = -1
    @last_error_states = nil
    @next_tokens_context = nil
    @next_tokens_state = nil
  end

  def reset(recognizer)
    end_error_condition(recognizer)
  end

  def begin_error_condition(_recognizer)
    @error_recovery_mode = true
  end

  def error_recovery_mode?(_recognizer)
    @error_recovery_mode
  end

  def end_error_condition(_recognizer)
    @error_recovery_mode = false
    @last_error_states = nil
    @last_error_index = -1
  end

  def report_match(recognizer)
    end_error_condition(recognizer)
  end

  def report_error(recognizer, e)
    # if we've already reported an error and have not matched a token
    # yet successfully, don't report any errors.
    if error_recovery_mode?(recognizer)
      #      System.err.print("[SPURIOUS] ")
      return # don't report spurious errors
    end

    begin_error_condition(recognizer)
    if e.is_a? NoViableAltException
      report_no_viable_alternative(recognizer, e)
    elsif e.is_a? InputMismatchException
      report_input_mismatch(recognizer, e)
    elsif e.is_a? FailedPredicateException
      report_failed_predicate(recognizer, e)
    else
      STDERR.puts 'unknown recognition error type: ' + e.getClass.getName
      recognizer.notify_error_listeners(e.getOffendingToken, e.getMessage, e)
    end
  end

  def recover(recognizer, _e)
    if @last_error_index == recognizer.input_stream.index && !@last_error_states.nil? && @last_error_states.include?(recognizer.getState)
      # uh oh, another error at same token index and previously-visited
      # state in ATN must be a case where lt(1) is in the recovery
      # token set so nothing got consumed. Consume a single token
      # at least to prevent an infinite loop this is a failsafe.
      #      System.err.println("seen error condition before index="+
      #                 lastErrorIndex+", states="+last_error_states)
      #      System.err.println("FAILSAFE consumes "+recognizer.getTokenNames()[recognizer.getInputStream().la(1)])
      recognizer.consume
    end
    @last_error_index = recognizer.input_stream.index
    @last_error_states = IntervalSet.new if @last_error_states.nil?
    @last_error_states.add(recognizer.getState)
    followSet = error_recovery_set(recognizer)
    consume_until(recognizer, followSet)
  end

  def sync(recognizer)
    s = recognizer._interp.atn.states[recognizer._state_number]
    #    System.err.println("sync @ "+s.stateNumber+"="+s.getClass().getSimpleName())
    # If already recovering, don't try to sync
    return if error_recovery_mode?(recognizer)

    tokens = recognizer._input
    la = tokens.la(1)

    # try cheaper subset first might get lucky. seems to shave a wee bit off
    next_tokens = recognizer.atn.next_tokens(s)
    if next_tokens.contains(la)
      # We are sure the token matches
      @next_tokens_context = nil
      @next_tokens_state = ATNState.invalid_state_number
      return
    end

    if next_tokens.contains(Token::EPSILON)
      if @next_tokens_context.nil?
        # It's possible the next token won't match information tracked
        # by sync is restricted for performance.
        @next_tokens_context = recognizer._ctx
        @next_tokens_state = recognizer._state_number
      end
      return
    end

    case s.state_type
    when ATNState::BLOCK_START, ATNState::STAR_BLOCK_START, ATNState::PLUS_BLOCK_START, ATNState::STAR_LOOP_ENTRY
      # report error and recover if possible
      return unless single_token_deletion(recognizer).nil?

      exc = InputMismatchException.create(recognizer)
      raise exc

    when ATNState::PLUS_LOOP_BACK, ATNState::STAR_LOOP_BACK

      #      System.err.println("at loop back: "+s.getClass().getSimpleName())
      report_unwanted_token(recognizer)
      expecting = recognizer.expected_tokens
      what_follows_loop_iteration_or_rule = expecting.or(error_recovery_set(recognizer))
      consume_until(recognizer, what_follows_loop_iteration_or_rule)

    else # do nothing if we can't identify the exact kind of ATN state end
    end
  end

  def report_no_viable_alternative(recognizer, e)
    tokens = recognizer.input_stream
    input = if !tokens.nil?
              if e.start_token.type == Token::EOF
                '<EOF>'
              else
                tokens.text4(e.start_token, e.offending_token)
              end
            else
              '<unknown input>'
            end
    msg = 'no viable alternative at input ' + escape_ws_and_quote(input)
    recognizer.notify_error_listeners(e.offending_token, msg, e)
  end

  def report_input_mismatch(recognizer, e)
    msg = 'mismatched input ' + token_error_display(e.offending_token) + ' expecting ' + e.expected_tokens.to_string_from_vocabulary(recognizer.get_vocabulary)
    recognizer.notify_error_listeners(e.offending_token, msg, e)
  end

  def report_failed_predicate(recognizer, e)
    rule_name = recognizer.rule_names[recognizer._ctx.rule_index]
    msg = 'rule ' + rule_name + ' ' + e.getMessage
    recognizer.notify_error_listeners(e.getOffendingToken, msg, e)
  end

  def report_unwanted_token(recognizer)
    return if error_recovery_mode?(recognizer)

    begin_error_condition(recognizer)

    t = recognizer.current_token
    token_name = token_error_display(t)
    expecting = expected_tokens(recognizer)
    msg = 'extraneous input ' + token_name + ' expecting ' + expecting.to_string_from_vocabulary(recognizer.get_vocabulary)
    recognizer.notify_error_listeners(t, msg, nil)
  end

  def report_missing_token(recognizer)
    return if error_recovery_mode?(recognizer)

    begin_error_condition(recognizer)

    t = recognizer.current_token
    expecting = expected_tokens(recognizer)
    msg = 'missing ' + expecting.to_string_from_vocabulary(recognizer.get_vocabulary) + ' at ' + token_error_display(t)

    recognizer.notify_error_listeners(t, msg, nil)
  end

  def recover_in_line(recognizer)
    # SINGLE TOKEN DELETION
    matched_symbol = single_token_deletion(recognizer)
    unless matched_symbol.nil?
      # we have deleted the extra token.
      # now, move past ttype token as if all were ok
      recognizer.consume
      return matched_symbol
    end

    # SINGLE TOKEN INSERTION
    return get_missing_symbol(recognizer) if single_token_insertion(recognizer)

    # even that didn't work must throw the exception
    exc = InputMismatchException.new
    exc.recog = recognizer
    if nextTokensContext.nil?
      raise exc
    else
      exc.token = @next_tokens_state
      exc.context = @next_tokens_context
      raise exc
    end
  end

  def single_token_insertion(recognizer)
    current_symbol_type = recognizer.input_stream.la(1)
    # if current token is consistent with what could come after current
    # ATN state, then we know we're missing a token error recovery
    # is free to conjure up and insert the missing token
    current_state = recognizer._interp.atn.states[recognizer.getState]
    next_t = current_state.transition(0).target
    atn = recognizer._interp.atn
    expecting_at_ll2 = atn.next_tokens_ctx(next_t, recognizer._ctx)
    #    System.out.println("lt(2) set="+expecting_at_ll2.to_s(recognizer.getTokenNames()))
    if expecting_at_ll2.contains(current_symbol_type)
      report_missing_token(recognizer)
      return true
    end
    false
  end

  def single_token_deletion(recognizer)
    next_token_type = recognizer.input_stream.la(2)
    expecting = expected_tokens(recognizer)
    if expecting.contains(next_token_type)
      report_unwanted_token(recognizer)

      recognizer.consume # simply delete extra token
      # we want to return the token we're actually matching
      matched_symbol = recognizer.current_token
      report_match(recognizer) # we know current token is correct
      return matched_symbol
    end
    nil
  end

  def get_missing_symbol(recognizer)
    current_symbol = recognizer.current_token
    expecting = expected_tokens(recognizer)
    expected_token_type = Token::INVALID_TYPE
    unless expecting.is_nil
      expected_token_type = expecting.min_element # get any element
    end
    if expected_token_type == Token::EOF
      token_text = '<missing EOF>'
    else
      token_text = '<missing ' + recognizer.get_vocabulary.display_name(expected_token_type) + '>'
    end
    current = current_symbol
    look_back = recognizer.input_stream.lt(-1)
    current = look_back if current.type == Token::EOF && !look_back.nil?

    pair = OpenStruct.new
    pair.a = current.source
    pair.b = current.source.input_stream
    recognizer.token_factory.create(pair, expected_token_type, token_text, Token::DEFAULT_CHANNEL, -1, -1, current.line, current.char_position_in_line)
  end

  def expected_tokens(recognizer)
    recognizer.expected_tokens
  end

  def token_error_display(t)
    return '<no token>' if t.nil?

    s = symbol_text(t)
    if s.nil?
      s = if symbol_type(t) == Token::EOF
            '<EOF>'
          else
            '<' << symbol_type(t).to_s << '>'
          end
    end

    escape_ws_and_quote(s)
  end

  def symbol_text(symbol)
    symbol.text
  end

  def symbol_type(symbol)
    symbol.type
  end

  def escape_ws_and_quote(s) #    if ( s==nil ) return s
    s = s.sub("\n", '\\n')
    s = s.sub("\r", '\\r')
    s = s.sub("\t", '\\t')
    "'" + s + "'"
  end

  def error_recovery_set(recognizer)
    atn = recognizer._interp.atn
    ctx = recognizer._ctx
    recover_set = IntervalSet.new
    while !ctx.nil? && ctx.invoking_state >= 0
      # compute what follows who invoked us
      invoking_state = atn.states[ctx.invoking_state]
      rt = invoking_state.transition(0)
      follow = atn.next_tokens(rt.follow_state)
      recover_set.add_all(follow)
      ctx = ctx.parent
    end
    recover_set.remove(Token::EPSILON)
    recover_set
  end

  def consume_until(recognizer, set)
    ttype = recognizer.input_stream.la(1)
    while ttype != Token::EOF && !set.contains(ttype)
      recognizer.consume
      ttype = recognizer.input_stream.la(1)
    end
  end
end
