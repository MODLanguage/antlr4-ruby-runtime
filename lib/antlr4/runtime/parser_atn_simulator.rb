require '../antlr4/atn_simulator'
require '../antlr4/prediction_mode'
require '../antlr4/prediction_context_utils'
require '../antlr4/rule_stop_state'
require '../antlr4/double_key_map'

class ParserATNSimulator < ATNSimulator
  attr_accessor :debug
  attr_accessor :debug_list_atn_decisions
  attr_accessor :dfa_debug
  attr_accessor :retry_debug

  def self.get_safe_env(env_name)
    ENV[env_name]
  rescue StandardError
    nil
  end

  TURN_OFF_LR_LOOP_ENTRY_BRANCH_OPT = get_safe_env('TURN_OFF_LR_LOOP_ENTRY_BRANCH_OPT')

  def initialize(parser, atn, decision_to_dfa, shared_context_cache)
    super(atn, shared_context_cache)
    @parser = parser
    @decision_to_dfa = decision_to_dfa
    @mode = PredictionMode::LL
    @merge_cache = nil
    @_input = nil
    @_start_index = nil
    @_outer_context = nil
    @_dfa = nil

    @debug = false
    @debug_list_atn_decisions = false
    @dfa_debug = false
    @retry_debug = false
  end

  def clear_dfa
    d = 0
    while d < @decision_to_dfa.length
      @decision_to_dfa[d] = DFA.new(atn.decision_state(d), d)
    end
  end

  def adaptive_predict(input, decision, outer_ctx)
    if @debug || @debug_list_atn_decisions
      puts('adaptivePredict decision ' << decision.to_s << ' exec la(1)==' << lookahead_name(input) << ' line ' << input.lt(1).line.to_s << ':' << input.lt(1).char_position_in_line.to_s)
    end

    @_input = input
    @_start_index = input.index
    @_outer_context = outer_ctx
    dfa = @decision_to_dfa[decision]
    @_dfa = dfa

    m = input.mark
    index = @_start_index

    # Now we are certain to have a specific decision's DFA
    # But, do we still need an initial state?
    begin
      dfa.precedence_dfa? ? s0 = dfa.precedence_start_state(parser.precedence) : s0 = dfa.s0

      if s0.nil?
        outer_ctx = ParserRuleContext::EMPTY if outer_ctx.nil?
        if @debug || @debug_list_atn_decisions
          puts('predictATN decision ' << dfa.decision.to_s << ' exec la(1)==' << lookahead_name(input) << ', outer_ctx=' << outer_ctx.to_s_recog(@parser))
        end

        full_ctx = false
        s0_closure = compute_start_state(dfa.atn_start_state, ParserRuleContext::EMPTY, full_ctx)

        if dfa.precedence_dfa?
          dfa.s0.configs = s0_closure # not used for prediction but useful to know start configs anyway
          s0_closure = apply_precedence_filter(s0_closure)
          s0 = add_dfa_state(dfa, DFAState.new(s0_closure))
          dfa.precedence_start_state(@parser.precedence, s0)
        else
          s0 = add_dfa_state(dfa, DFAState.new(s0_closure))
          dfa.s0 = s0
        end
      end

      alt = exec_atn(dfa, s0, input, index, outer_ctx)
      if @debug
        puts('DFA after predictATN: ' << dfa.to_s2(@parser.get_vocabulary))
      end
      return alt
    ensure
      @merge_cache = nil # wack cache after each prediction
      @_dfa = nil
      input.seek(index)
      input.release(m)
    end
  end

  def exec_atn(dfa, s0, input, start_index, outer_ctx)
    if @debug || @debug_list_atn_decisions
      puts('execATN decision ' << dfa.decision.to_s << ' exec la(1)==' << lookahead_name(input) << ' line ' << input.lt(1).line.to_s << ':' << input.lt(1).char_position_in_line.to_s)
    end

    previous_d = s0

    puts('s0 = ' << s0.to_s) if @debug

    t = input.la(1)

    loop do # while more work
      d = existing_target_state(previous_d, t)
      d = compute_target_state(dfa, previous_d, t) if d.nil?

      if d == ERROR
        # if any configs in previous dipped into outer context, that
        # means that input up to t actually finished entry rule
        # at least for SLL decision. Full LL doesn' t dip into outer
        # so don't need special case.
        # We will get an error no matter what so delay until after
        # decision better error message. Also, no reachable target
        # ATN states in SLL implies LL will also get nowhere.
        # If conflict in states that dip out, choose min since we
        # will get error no matter what.
        input.seek(start_index)
        alt = syn_valid_or_sem_invalid_alt_that_finished_decision_entry_rule(previous_d.configs, outer_ctx)
        return alt if alt != ATN::INVALID_ALT_NUMBER

        exc = NoViableAltException.new
        exc.recognizer = @parser
        exc.input = input
        exc.context = outer_ctx
        exc.start_token = input.get(start_index)
        exc.offending_token = input.lt(1)
        exc.dead_end_configs = previous_d.configs
        raise exc
      end

      if d.requires_full_context && @mode != PredictionMode::SLL
        # IF PREDS, MIGHT RESOLVE TO SINGLE ALT => SLL (or syntax error)
        conflicting_alts = d.configs.conflictingAlts
        unless d.predicates.nil?
          puts('DFA state has preds in DFA sim LL failover') if @debug
          conflict_index = input.index
          input.seek(start_index) if conflict_index != start_index

          conflicting_alts = eval_semantic_context(D.predicates, outer_ctx, true)
          if conflicting_alts.cardinality == 1
            puts('Full LL avoided') if debug
            return conflicting_alts.next_set_bit(0)
          end

          if conflict_index != start_index
            # restore the index so reporting the fallback to full
            # context occurs with the index at the correct spot
            input.seek(conflict_index)
          end
        end

        if @dfa_debug
          puts('ctx sensitive state ' << outer_ctx.to_s << ' in ' << d.to_s)
        end
        full_ctx = true
        s0_closure = compute_start_state(dfa.atn_start_state, outer_ctx, full_ctx)
        report_attempting_full_context(dfa, conflicting_alts, d.configs, start_index, input.index)
        alt = exec_atn_with_full_context(dfa, d, s0_closure, input, start_index, outer_ctx)
        return alt
      end

      if d.is_accept_state
        return d.prediction if d.predicates.nil?

        stop_index = input.index
        input.seek(start_index)
        alts = eval_semantic_context(d.predicates, outer_ctx, true)
        case alts.cardinality
        when 0
          raise NoViableAltException, input, outer_ctx, d.configs, start_index

        when 1
          return alts.next_set_bit(0)

        else # report ambiguity after predicate evaluation to make sure the correct
          # set of ambig alts is reported.
          report_ambiguity(dfa, D, start_index, stop_index, false, alts, d.configs)
          return alts.next_set_bit(0)
        end
      end

      previous_d = d

      if t != IntStream::EOF
        input.consume
        t = input.la(1)
      end
    end
  end

  def existing_target_state(prev_d, t)
    edges = prev_d.edges
    return nil if edges.nil? || t + 1 < 0 || t + 1 >= edges.length

    edges[t + 1]
  end

  def compute_target_state(dfa, prev_d, t)
    reach = compute_reach_set(prev_d.configs, t, false)
    if reach.nil?
      add_dfa_edge(dfa, prev_d, t, ERROR)
      return ERROR
    end

    # create new target state we'll add to DFA after it's complete
    d = DFAState.new(reach)

    predicted_alt = unique_alt(reach)

    if @debug
      alt_sub_sets = PredictionMode.conflicting_alt_subsets(reach)
      alt_sub_sets_str = '['
      alt_sub_sets.each do |x|
        alt_sub_sets_str << x.to_s
      end
      alt_sub_sets_str << ']'
      puts('SLL alt_sub_sets=' << alt_sub_sets_str << ', configs=' << reach.to_s << ', predict=' << predicted_alt.to_s << ', allSubsetsConflict=' << PredictionMode.all_subsets_conflict?(alt_sub_sets).to_s << ', conflicting_alts=' << conflicting_alts(reach).to_s)
    end

    if predicted_alt != ATN::INVALID_ALT_NUMBER
      # NO CONFLICT, UNIQUELY PREDICTED ALT
      d.is_accept_state = true
      d.configs.unique_alt = predicted_alt
      d.prediction = predicted_alt
    elsif PredictionMode.has_sll_conflict_terminating_prediction(@mode, reach)
      # MORE THAN ONE VIABLE ALTERNATIVE
      d.configs.conflictingAlts = conflicting_alts(reach)
      d.requires_full_context = true
      # in SLL-only mode, we will stop at this state and return the minimum alt
      d.is_accept_state = true
      d.prediction = d.configs.conflictingAlts.next_set_bit(0)
    end

    if d.is_accept_state && d.configs.has_semantic_context
      predicate_dfa_state(d, atn.decision_state(dfa.decision))
      d.prediction = ATN::INVALID_ALT_NUMBER unless d.predicates.nil?
    end

    # all adds to dfa are done after we've created full D state
    d = add_dfa_edge(dfa, prev_d, t, d)
  end

  def predicate_dfa_state(dfa_state, decision_state) # We need to test all predicates, even in DFA states that
    # uniquely predict alternative.
    nalts = decision_state.number_of_transitions
    # Update DFA so reach becomes accept state with (predicate,alt)
    # pairs if preds found for conflicting alts
    alts_to_collect_preds_from = conflicting_alts_or_unique_alt(dfa_state.configs)
    alt_to_pred = preds_for_ambig_alts(alts_to_collect_preds_from, dfa_state.configs, nalts)
    if !alt_to_pred.nil?
      dfa_state.predicates = predicate_predictions(alts_to_collect_preds_from, alt_to_pred)
      dfa_state.prediction = ATN::INVALID_ALT_NUMBER # make sure we use preds
    else # There are preds in configs but they might go away
      # when OR'd together like pend? || NONE == NONE. If neither
      # alt has preds, resolve to min alt
      dfa_state.prediction = alts_to_collect_preds_from.next_set_bit(0)
    end
  end

  # comes back with reach.uniqueAlt set to a valid alt
  def exec_atn_with_full_context(dfa, d, s0, input, start_index, outer_ctx)
    if @debug || @debug_list_atn_decisions
      puts('execATNWithFullContext ' << s0.to_s)
    end
    full_ctx = true
    found_exact_ambig = false
    reach = nil
    previous = s0
    input.seek(start_index)
    t = input.la(1)
    predicted_alt = 0
    loop do # while more work
      reach = compute_reach_set(previous, t, full_ctx)
      if reach.nil?
        # if any configs in previous dipped into outer context, that
        # means that input up to t actually finished entry rule
        # at least for LL decision. Full LL doesn't dip into outer
        # so don't need special case.
        # We will get an error no matter what so delay until after
        # decision better error message. Also, no reachable target
        # ATN states in SLL implies LL will also get nowhere.
        # If conflict in states that dip out, choose min since we
        # will get error no matter what.

        input.seek(start_index)
        alt = syn_valid_or_sem_invalid_alt_that_finished_decision_entry_rule(previous, outer_ctx)
        return alt if alt != ATN::INVALID_ALT_NUMBER

        raise NoViableAltException, input, outer_ctx, previous, start_index
      end

      alt_sub_sets = PredictionMode.conflicting_alt_subsets(reach)
      if @debug
        tmp = ''
        alt_sub_sets.each do |as|
          tmp << as.to_s
          tmp << ' '
        end
        puts('LL alt_sub_sets=' << tmp << ', predict=' << PredictionMode.unique_alt(alt_sub_sets).to_s << ', resolvesToJustOneViableAlt=' << PredictionMode.resolves_to_just_one_viable_alt?(alt_sub_sets).to_s)
      end

      #      puts("alt_sub_sets: "+alt_sub_sets)
      #      System.err.println("reach="+reach+", "+reach.conflicting_alts)
      reach.unique_alt = unique_alt(reach)
      # unique prediction?
      if reach.unique_alt != ATN::INVALID_ALT_NUMBER
        predicted_alt = reach.unique_alt
        break
      end
      if @mode != PredictionMode::LL_EXACT_AMBIG_DETECTION
        predicted_alt = PredictionMode.resolves_to_just_one_viable_alt?(alt_sub_sets)
        break if predicted_alt != ATN::INVALID_ALT_NUMBER
      else # In exact ambiguity mode, we never try to terminate early.
        # Just keeps scarfing until we know what the conflict is
        if PredictionMode.all_subsets_conflict?(alt_sub_sets) && PredictionMode.all_subsets_equal?(alt_sub_sets)

          found_exact_ambig = true
          predicted_alt = PredictionMode.single_viable_alt(alt_sub_sets)
          break
        end
        # else there are multiple non-conflicting subsets or
        # we're not sure what the ambiguity is yet.
        # So, keep going.
      end

      previous = reach
      if t != IntStream::EOF
        input.consume
        t = input.la(1)
      end
    end

    # If the configuration set uniquely predicts an alternative,
    # without conflict, then we know that it's a full LL decision
    # not SLL.
    if reach.unique_alt != ATN::INVALID_ALT_NUMBER
      report_context_sensitivity(dfa, predicted_alt, reach, start_index, input.index)
      return predicted_alt
    end

    report_ambiguity(dfa, d, start_index, input.index, found_exact_ambig, reach.alts, reach)

    predicted_alt
  end

  def compute_reach_set(closure, t, full_ctx)
    puts('in computeReachSet, starting closure: ' << closure.to_s) if @debug

    @merge_cache = DoubleKeyMap.new if @merge_cache.nil?

    intermediate = ATNConfigSet.new(full_ctx)

    skipped_stop_states = nil

    # First figure out where we can reach on input t
    closure.configs.each do |c|
      puts('testing ' << token_name(t) << ' at ' << c.to_s) if @debug

      if c.state.is_a? RuleStopState
        if full_ctx || t == IntStream::EOF
          skipped_stop_states = [] if skipped_stop_states.nil?

          skipped_stop_states.add(c)
        end

        next
      end

      n = c.state.number_of_transitions
      ti = 0
      while ti < n
        trans = c.state.transition(ti)
        target = reachable_target(trans, t)
        unless target.nil?
          atncfg = ATNConfig.new
          atncfg.atn_config3(c, target)
          intermediate.add(atncfg, @merge_cache)
        end
        ti += 1
      end
    end

    # Now figure out where the reach operation can take us...

    reach = nil

    if skipped_stop_states.nil? && t != Token::EOF
      if intermediate.configs.size == 1
        # Don' t pursue the closure if there is just one state.
        # It can only have one alternative just add to result
        # Also don't pursue the closure if there is unique alternative
        # among the configurations.
        reach = intermediate
      elsif unique_alt(intermediate) != ATN::INVALID_ALT_NUMBER
        # Also don't pursue the closure if there is unique alternative
        # among the configurations.
        reach = intermediate
      end
    end

    if reach.nil?
      reach = ATNConfigSet.new(full_ctx)
      closure_busy = Set.new
      treat_eof_as_epsilon = t == Token::EOF
      intermediate.configs.each do |c|
        closure(c, reach, closure_busy, false, full_ctx, treat_eof_as_epsilon)
      end
    end

    if t == IntStream::EOF
      reach = remove_all_configs_not_in_rule_stop_state(reach, reach == intermediate)
    end

    if !skipped_stop_states.nil? && (!full_ctx || !PredictionMode.has_config_in_rule_stop_state?(reach))
      skipped_stop_states.each do |c|
        reach.add(c, @merge_cache)
      end
    end

    return nil if reach.empty?
    reach
  end

  def remove_all_configs_not_in_rule_stop_state(configs, look_to_end_of_rule)
    return configs if PredictionMode.all_configs_in_rule_stop_states?(configs)

    result = ATNConfigSet.new(configs.full_ctx)
    configs.each do |config|
      if config.state.is_a? RuleStopState
        result.add(config, mergeCache)
        next
      end

      next unless look_to_end_of_rule && config.state.only_has_epsilon_transitions

      next_tokens = atn.next_tokens(config.state)
      next unless next_tokens.include?(Token::EPSILON)

      end_of_rule_state = atn.rule_to_stop_state[config.state.rule_index]
      atncfg = ATNConfig.new
      atncfg.atn_config3(config, end_of_rule_state)
      result.add(atncfg, @merge_cache)
    end

    result
  end

  def compute_start_state(p, ctx, full_ctx)
    # always at least the implicit call to start rule
    initial_context = PredictionContextUtils.from_rule_context(@atn, ctx)
    configs = ATNConfigSet.new(full_ctx)

    i = 0
    while i < p.number_of_transitions
      target = p.transition(i).target
      c = ATNConfig.new
      c.atn_config1(target, i + 1, initial_context)
      closure_busy = Set.new
      closure(c, configs, closure_busy, true, full_ctx, false)
      i += 1
    end

    configs
  end

  def apply_precedence_filter(configs)
    states_from_alt1 = Map.new
    config_set = ATNConfigSet.new(configs.full_ctx)
    configs.each do |config| # handle alt 1 first
      next if config.alt != 1

      updated_context = config.semantic_context.eval_precedence(@parser, @_outer_context)
      if updated_context.nil?
        # the configuration was eliminated
        next
      end

      states_from_alt1.put(config.state.state_number, config.context)
      if updated_context != config.semantic_context
        atncfg = ATNConfig.new
        atncfg.atn_config3(config, updated_context)
        config_set.add(atncfg, @merge_cache)
      else
        config_set.add(config, mergeCache)
      end
    end

    configs.each do |config|
      if config.alt == 1
        # already handled
        next
      end

      unless config.precedence_filter_suppressed?

        context = states_from_alt1.get(config.state.state_number)
        if !context.nil? && context.eql?(config.context)
          # eliminated
          next
        end
      end

      config_set.add(config, @merge_cache)
    end

    config_set
  end

  def reachable_target(trans, ttype)
    return trans.target if trans.matches(ttype, 0, atn.max_token_type)

    nil
  end

  def preds_for_ambig_alts(ambig_alts, configs, n_alts)
    alt_to_pred = []
    configs.each do |c|
      if ambig_alts.get(c.alt)
        alt_to_pred[c.alt] = SemanticContext.or(alt_to_pred[c.alt], c.semantic_context)
      end
    end

    n_pred_alts = 0
    i = 1
    while i <= n_alts
      if alt_to_pred[i].nil?
        alt_to_pred[i] = SemanticContext::NONE
      elsif alt_to_pred[i] != SemanticContext::NONE
        n_pred_alts += 1
      end
      i += 1
    end

    # nonambig alts are nil in alt_to_pred
    alt_to_pred = nil if n_pred_alts == 0
    puts('getPredsForAmbigAlts result ' << alt_to_pred.to_s) if @debug
    alt_to_pred
  end

  def predicate_predictions(ambig_alts, alt_to_pred)
    pairs = []
    contains_predicate = false
    i = 1
    while i < alt_to_pred.length
      pred = alt_to_pred[i]

      if !ambig_alts.nil? && ambig_alts.get(i)
        pairs.add(DFAState.PredPrediction.new(pred, i))
      end
      contains_predicate = true if pred != SemanticContext::NONE
      i += 1
    end

    return nil unless contains_predicate

    #    puts(Arrays.to_s(alt_to_pred)+"->"+pairs)
    pairs.to_a
  end

  def syn_valid_or_sem_invalid_alt_that_finished_decision_entry_rule(configs, outer_ctx)
    sets = split_according_to_semantic_validity(configs, outer_ctx)
    sem_valid_configs = sets.a
    sem_invalid_configs = sets.b
    alt = alt_that_finished_decision_entry_rule(sem_valid_configs)
    return alt if alt != ATN::INVALID_ALT_NUMBER # semantically/syntactically viable path exists

    # Is there a syntactically valid path with a failed pred?
    unless sem_invalid_configs.empty?
      alt = alt_that_finished_decision_entry_rule(sem_invalid_configs)
      return alt if alt != ATN::INVALID_ALT_NUMBER # syntactically viable path exists
    end
    ATN::INVALID_ALT_NUMBER
  end

  def alt_that_finished_decision_entry_rule(configs)
    alts = IntervalSet.new
    configs.configs.each do |c|
      if c.outer_context_depth > 0 || (c.state.class.name == 'RuleStopState' && c.context.empty_path?)
        alts.add(c.alt)
      end
    end
    return ATN::INVALID_ALT_NUMBER if alts.empty?

    alts.min_element
  end

  def split_according_to_semantic_validity(configs, outer_ctx)
    succeeded = ATNConfigSet.new(configs.full_ctx)
    failed = ATNConfigSet.new(configs.full_ctx)
    configs.configs.each do |c|
      if c.semantic_context != SemanticContext::NONE
        predicate_evaluation_result = eval_semantic_context(c.semantic_context, outer_ctx, c.alt, configs.full_ctx)
        if predicate_evaluation_result
          succeeded.add(c)
        else
          failed.add(c)
        end
      else
        succeeded.add(c)
      end
    end

    pair = OpenStruct.new
    pair.a = succeeded
    pair.b = failed
    pair
  end

  def eval_semantic_context1(pred_predictions, outer_ctx, complete)
    predictions = BitSet.new
    pred_predictions.each do |pair|
      if pair.pred == SemanticContext::NONE
        predictions.set(pair.alt)
        break unless complete

        next
      end

      full_ctx = false # in dfa
      predicate_evaluation_result = eval_semantic_context(pair.pred, outer_ctx, pair.alt, full_ctx)
      if @debug || @dfa_debug
        puts('eval pred ' << pair << '=' << predicate_evaluation_result)
      end

      next unless predicate_evaluation_result

      puts('PREDICT ' << pair.alt) if @debug || @dfa_debug
      predictions.set(pair.alt)
      break unless complete
    end

    predictions
  end

  def eval_semantic_context2(pred, parser_call_stack, _alt, _full_ctx)
    pred.eval(parser, parser_call_stack)
  end

  def closure(config, configs, closure_busy, collect_predicates, full_ctx, treat_eof_as_epsilon)
    initial_depth = 0
    closure_checking_stop_state(config, configs, closure_busy, collect_predicates, full_ctx, initial_depth, treat_eof_as_epsilon)
  end

  def closure_checking_stop_state(config, configs, closure_busy, collect_predicates, full_ctx, depth, treat_eof_as_epsilon)
    puts('closure(' << config.to_s2(@parser, true) << ')') if @debug

    if config.state.is_a? RuleStopState
      # We hit rule end. If we have context info, use it
      # run thru all possible stack tops in ctx
      if !config.context.empty?
        i = 0
        while i < config.context.size
          if config.context.get_return_state(i) == PredictionContext::EMPTY_RETURN_STATE
            if full_ctx
              atncfg = ATNConfig.new
              atncfg.atn_config6(config, config.state, EmptyPredictionContext::EMPTY)
              configs.add(atncfg, @merge_cache)
              i += 1
              next
            else # we have no context info, just chase follow links (if greedy)
              if @debug
                puts('FALLING off rule ' << rule_name(config.state.rule_index))
              end
              closure_(config, configs, closure_busy, collect_predicates, full_ctx, depth, treat_eof_as_epsilon)
            end
            i += 1
            next
          end
          return_state = atn.states[config.context.get_return_state(i)]
          new_context = config.context.get_parent(i) # "pop" return state
          c = ATNConfig.new
          c.atn_config2(return_state, config.alt, new_context, config.semantic_context)
          # While we have context to pop back from, we may have
          # gotten that context AFTER having falling off a rule.
          # Make sure we track that we are now out of context.
          #
          # This assignment also propagates the
          # isPrecedenceFilterSuppressed() value to the new
          # configuration.
          c.reaches_into_outer_context = config.reaches_into_outer_context
          closure_checking_stop_state(c, configs, closure_busy, collect_predicates, full_ctx, depth - 1, treat_eof_as_epsilon)
          i += 1
        end
        return
      elsif full_ctx
        # reached end of start rule
        configs.add(config, @merge_cache)
        return
      else # else if we have no context info, just chase follow links (if greedy)
        if @debug
          puts('FALLING off rule ' << rule_name(config.state.rule_index))
        end
      end
    end

    closure_(config, configs, closure_busy, collect_predicates, full_ctx, depth, treat_eof_as_epsilon)
  end

  def closure_(config, configs, closure_busy, collect_predicates, full_ctx, depth, treat_eof_as_epsilon)
    p = config.state
    # optimization
    unless p.only_has_epsilon_transitions
      configs.add(config, @merge_cache)
      # make sure to not return here, because EOF transitions can act as
      # both epsilon transitions and non-epsilon transitions.
      #            if ( debug ) puts("added config "+configs)
    end

    i = 0
    while i < p.number_of_transitions
      if i == 0 && can_drop_loop_entry_edge_in_left_recursive_rule?(config)
        i += 1
        next
      end

      t = p.transition(i)
      continue_collecting = !(t.is_a? ActionTransition) && collect_predicates
      c = epsilon_target(config, t, continue_collecting, depth == 0, full_ctx, treat_eof_as_epsilon)
      unless c.nil?
        new_depth = depth
        if config.state.is_a? RuleStopState
          # target fell off end of rule mark resulting c as having dipped into outer context
          # We can't get here if incoming config was rule stop and we had context
          # track how far we dip into outer context.  Might
          # come in handy and we avoid evaluating context dependent
          # preds if this is > 0.

          if !@_dfa.nil? && @_dfa.precedence_dfa?
            outermost_precedence_return = t.outermost_precedence_return
            if outermost_precedence_return == @_dfa.atn_start_state.rule_index
              c.precedence_filter_suppressed(true)
            end
          end

          c.reaches_into_outer_context += 1

          added = false
          unless closure_busy.include? c
            closure_busy.add(c)
            added = true
          end
          unless added
            # avoid infinite recursion for right-recursive rules
            i += 1
            next
          end

          configs.dips_into_outer_context = true # TODO: can remove? only care when we add to set per middle of this method
          new_depth -= 1
          puts('dips into outer ctx: ' << c.to_s) if @debug
        else
          added = false
          unless closure_busy.include? c
            closure_busy.add(c)
            added = true
          end
          if !t.epsilon? && !added
            # avoid infinite recursion for EOF* and EOF+
            i += 1
            next
          end

          if t.is_a? RuleTransition
            # latch when new_depth goes negative - once we step out of the entry context we can't return
            new_depth += 1 if new_depth >= 0
          end
        end

        closure_checking_stop_state(c, configs, closure_busy, continue_collecting, full_ctx, new_depth, treat_eof_as_epsilon)
      end
      i += 1
    end
  end

  def can_drop_loop_entry_edge_in_left_recursive_rule?(config)
    return false if TURN_OFF_LR_LOOP_ENTRY_BRANCH_OPT

    p = config.state
    # First check to see if we are in StarLoopEntryState generated during
    # left-recursion elimination. For efficiency, also check if
    # the context has an empty stack case. If so, it would mean
    # global FOLLOW so we can't perform optimization
    if p.state_type != ATNState::STAR_LOOP_ENTRY || !p.is_precedence_pecision || # Are we the special loop entry/exit state?
        config.context.empty? || # If SLL wildcard
        config.context.empty_path?

      return false
    end

    # Require all return states to return back to the same rule
    # that p is in.
    num_ctxs = config.context.size
    i = 0
    while i < num_ctxs
      return_state = atn.states.get(config.context.get_return_state(i))
      return false if return_state.rule_index != p.rule_index

      i += 1
    end

    decision_start_state = p.transition(0).target
    block_end_state_num = decision_start_state.end_state.state_number
    block_end_state = atn.states.get(block_end_state_num)

    # Verify that the top of each stack context leads to loop entry/exit
    # state through epsilon edges and w/o leaving rule.
    i = 0
    while i < num_ctxs
      return_state_number = config.context.get_return_state(i)
      return_state = atn.states.get(return_state_number)
      # all states must have single outgoing epsilon edge
      if return_state.number_of_transitions != 1 || !return_state.transition(0).epsilon?

        return false
      end

      # Look for prefix op case like 'not expr', (' type ')' expr
      return_state_target = return_state.transition(0).target
      if return_state.state_type == BLOCK_END && return_state_target == p
        i += 1
        next
      end
      # Look for 'expr op expr' or case where expr's return state is block end
      # of (...)* internal block the block end points to loop back
      # which points to p but we don't need to check that
      if return_state == block_end_state
        i += 1
        next
      end
      # Look for ternary expr ? expr : expr. The return state points at block end,
      # which points at loop entry state
      if return_state_target == block_end_state
        i += 1
        next
      end
      # Look for complex prefix 'between expr and expr' case where 2nd expr's
      # return state points at block end state of (...)* internal block
      if return_state_target.state_type == BLOCK_END && return_state_target.number_of_transitions == 1 && return_state_target.transition(0).epsilon? && return_state_target.transition(0).target == p

        i += 1
        next
      end

      # anything else ain't conforming
      return false
    end

    true
  end

  def rule_name(index)
    return @parser.rule_names[index] if !@parser.nil? && index >= 0

    '<rule ' << index << '>'
  end

  def epsilon_target(config, t, collect_predicates, in_context, full_ctx, treat_eof_as_epsilon)
    case t.serialization_type
    when Transition::RULE
      rule_transition(config, t)

    when Transition::PRECEDENCE
      precedence_transition(config, t, collect_predicates, in_context, full_ctx)

    when Transition::PREDICATE
      pred_transition(config, t, collect_predicates, in_context, full_ctx)

    when Transition::ACTION
      action_transition(config, t)

    when Transition::EPSILON
      c = ATNConfig.new
      c.atn_config3(config, t.target)
      c

    when Transition::ATOM, Transition::RANGE, Transition::SET
      # EOF transitions act like epsilon transitions after the first EOF
      # transition is traversed
      if treat_eof_as_epsilon
        if t.matches(Token::EOF, 0, 1)
          c = ATNConfig.new
          c.atn_config3(config, t.target)
          return c
        end
      end

      return nil

    end
  end

  def action_transition(config, t)
    puts('ACTION edge ' << t.rule_index << ':' << t.action_index) if @debug
    c = ATNConfig.new
    c.atn_config3(config, t.target)
    c
  end

  def precedence_transition(config, pt, collect_predicates, in_context, full_ctx)
    if @debug
      puts('PRED (collect_predicates=' << collect_predicates << ') ' << pt.precedence << '>=_p' << ', ctx dependent=true')
      unless @parser.nil?
        puts('context surrounding pred is ' << @parser.getRuleInvocationStack)
      end
    end

    c = nil
    if collect_predicates && in_context
      if full_ctx
        # In full context mode, we can evaluate predicates on-the-fly
        # during closure, which dramatically reduces the size of
        # the config sets. It also obviates the need to test predicates
        # later during conflict resolution.
        current_position = @_input.index
        @_input.seek(@_start_index)
        pred_succeeds = eval_semantic_context(pt.predicate, @_outer_context, config.alt, full_ctx)
        @_input.seek(current_position)
        if pred_succeeds
          c = ATNConfig.new
          c.atn_config3(config, pt.target) # no pred context
        end
      else
        new_sem_ctx = SemanticContext.and(config.semantic_context, pt.predicate)
        c = ATNConfig.new
        c.atn_config4(config, pt.target, new_sem_ctx)
      end
    else
      c = ATNConfig.new
      c.atn_config3(config, pt.target)
    end

    puts('config from pred transition=' << c) if @debug
    c
  end

  def pred_transition(config, pt, collect_predicates, in_context, full_ctx)
    if @debug
      puts('PRED (collect_predicates=' << collect_predicates << ') ' << pt.rule_index << ':' << pt.pred_index << ', ctx dependent=' << pt.is_ctx_dependent)
      unless @parser.nil?
        puts('context surrounding pred is ' << @parser.getRuleInvocationStack)
      end
    end

    c = nil
    if collect_predicates && (!pt.is_ctx_dependent || (pt.is_ctx_dependent && in_context))

      if full_ctx
        # In full context mode, we can evaluate predicates on-the-fly
        # during closure, which dramatically reduces the size of
        # the config sets. It also obviates the need to test predicates
        # later during conflict resolution.
        current_position = @_input.index
        @_input.seek(@_start_index)
        pred_succeeds = eval_semantic_context(pt.predicate, @_outer_context, config.alt, full_ctx)
        @_input.seek(current_position)
        if pred_succeeds
          c = ATNConfig.new
          c.atn_config3(config, pt.target) # no pred context
        end
      else
        new_sem_ctx = SemanticContext.and(config.semantic_context, pt.predicate)
        c = ATNConfig.new
        c.atn_config4(config, pt.target, new_sem_ctx)
      end
    else
      c = ATNConfig.new
      c.atn_config3(config, pt.target)
    end

    puts('config from pred transition=' << c) if debug
    c
  end

  def rule_transition(config, t)
    if @debug
      puts('CALL rule ' << rule_name(t.target.rule_index) << ', ctx=' << config.context.to_s)
    end

    return_state = t.follow_state
    new_context = SingletonPredictionContext.new(config.context, return_state.state_number)
    c = ATNConfig.new
    c.atn_config6(config, t.target, new_context)
    c
  end

  def conflicting_alts(configs)
    altsets = PredictionMode.conflicting_alt_subsets(configs)
    PredictionMode.get_alts1(altsets)
  end

  def conflicting_alts_or_unique_alt(configs)
    if configs.unique_alt != ATN::INVALID_ALT_NUMBER
      conflict_alts = new BitSet
      conflict_alts.set(configs.unique_alt)
    else
      conflict_alts = configs.conflictingAlts
    end
    conflict_alts
  end

  def token_name(t)
    return 'EOF' if t == Token::EOF

    vocabulary = !@parser.nil? ? @parser.get_vocabulary : VocabularyImpl.EMPTY_VOCABULARY
    display_name = vocabulary.display_name(t)
    return display_name if display_name == t.to_s

    result = ''
    result << display_name
    result << '<' << t.to_s << '>'
  end

  def lookahead_name(input)
    token_name(input.la(1))
  end

  def dump_dead_end_configs(nvae)
    STDERR.puts('dead end configs: ')
    nvae.getDeadEndConfigs.each do |c|
      trans = 'no edges'
      if c.state.number_of_transitions > 0
        t = c.state.transition(0)
        if t.is_a? AtomTransition
          at = t
          trans = 'Atom ' << token_name(at.label)
        elsif t.is_a? SetTransition
          st = t
          nott = st.is_a? NotSetTransition
          trans = (nott ? '~' : '') << 'Set ' << st.set.to_s
        end
      end
      STDERR.puts(c.to_s(@parser, true) << ':' << trans)
    end
  end

  def unique_alt(configs)
    alt = ATN::INVALID_ALT_NUMBER
    configs.configs.each do |c|
      if alt == ATN::INVALID_ALT_NUMBER
        alt = c.alt # found first alt
      elsif c.alt != alt
        return ATN::INVALID_ALT_NUMBER
      end
    end
    alt
  end

  def add_dfa_edge(dfa, from, t, to)
    if @debug
      puts('EDGE ' << from.to_s << ' -> ' << to.to_s << ' upon ' << token_name(t))
    end

    return nil if to.nil?

    to = add_dfa_state(dfa, to) # used existing if possible not incoming
    return to if from.nil? || t < -1 || t > atn.max_token_type

    from.edges = [] if from.edges.nil?

    from.edges[t + 1] = to # connect

    if @debug
      puts("DFA=\n" << dfa.to_s2(!@parser.nil? ? @parser.get_vocabulary : VocabularyImpl.EMPTY_VOCABULARY))
    end

    to
  end

  def add_dfa_state(dfa, d)
    return d if d == ERROR

    existing = dfa.states[d]
    return existing unless existing.nil?

    d.state_number = dfa.states.size
    unless d.configs.readonly
      d.configs.optimize_configs(self)
      d.configs.readonly = true
    end
    dfa.states[d] = d
    puts('adding new DFA state: ' << d.to_s) if @debug
    d
  end

  def report_attempting_full_context(dfa, conflict_alts, configs, start_index, stop_index)
    if @debug || @retry_debug
      interval = Interval.of(start_index, stop_index)
      puts('reportAttemptingFullContext decision=' << dfa.decision.to_s << ':' << configs.to_s << ', input=' << @parser._input.text2(interval).to_s)
    end
    unless @parser.nil?
      @parser.error_listener_dispatch.report_attempting_full_context(@parser, dfa, start_index, stop_index, conflict_alts, configs)
    end
  end

  def report_context_sensitivity(dfa, prediction, configs, start_index, stop_index)
    if @debug || @retry_debug
      interval = Interval.of(start_index, stop_index)
      puts('reportContextSensitivity decision=' << dfa.decision.to_s << ':' << configs.to_s << ', input=' << @parser._input.text2(interval).to_s)
    end
    unless @parser.nil?
      @parser.error_listener_dispatch.report_context_sensitivity(@parser, dfa, start_index, stop_index, prediction, configs)
    end
  end

  def report_ambiguity(dfa, _d, start_index, stop_index, exact, ambig_alts, configs) # configs that LL not SLL considered conflicting
    if @debug || @retry_debug
      interval = Interval.of(start_index, stop_index)
      puts('reportAmbiguity ' << ambig_alts.to_s << ':' << configs.to_s << ', input=' << @parser._input.text2(interval).to_s)
    end
    unless @parser.nil?
      @parser.error_listener_dispatch.report_ambiguity(@parser, dfa, start_index, stop_index, exact, ambig_alts, configs)
    end
  end

end
