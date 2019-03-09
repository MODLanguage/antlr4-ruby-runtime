class ProfilingATNSimulator < ParserATNSimulator
  def initialize(parser)
    super(parser, parser._interp.atn, parser._interp.decision_to_dfa, parser._interp.shared_context_cache)

    @num_decisions = @atn.decision_to_state.size
    @_sll_stop_index = 0
    @_ll_stop_index = 0
    @current_decision = 0
    @current_state = nil
    @conflicting_alt_resolved_by_sll = 0

    @decisions = Array.new(@numDecisions)
    i = 0
    while i < @num_decisions
      @decisions[i] = DecisionInfo.new(i)
      i += 1
    end
  end

  def adaptive_predict(input, decision, outer_ctx)
    @_sll_stop_index = -1
    @_ll_stop_index = -1
    @current_decision = decision
    start = Time.now # expensive but useful info
    alt = super.adaptive_predict(input, decision, outer_ctx)
    stop = Time.now
    @decisions[decision].timeInPrediction += (stop - start)
    @decisions[decision].invocations += 1

    _s_ll_k = @_sll_stop_index - @_start_index + 1
    @decisions[decision].SLL_TotalLook += _s_ll_k
    @decisions[decision].SLL_MinLook = @decisions[decision].SLL_MinLook == 0 ? _s_ll_k : Math.min(@decisions[decision].SLL_MinLook, _s_ll_k)
    if _s_ll_k > @decisions[decision].SLL_MaxLook
      @decisions[decision].SLL_MaxLook = _s_ll_k
      @decisions[decision].SLL_MaxLookEvent = LookaheadEventInfo.new(decision, nil, alt, input, @_start_index, @_sll_stop_index, false)
    end

    if @_ll_stop_index >= 0
      _ll_k = @_ll_stop_index - @_start_index + 1
      @decisions[decision].LL_TotalLook += _ll_k
      @decisions[decision].LL_MinLook = @decisions[decision].LL_MinLook == 0 ? _ll_k : Math.min(@decisions[decision].LL_MinLook, _ll_k)
      if _ll_k > @decisions[decision].LL_MaxLook
        @decisions[decision].LL_MaxLook = _ll_k
        @decisions[decision].LL_MaxLookEvent = LookaheadEventInfo.new(decision, nil, alt, input, @_start_index, @_ll_stop_index, true)
      end
    end

    alt
  ensure
    @current_decision = -1
  end

  def existing_target_state(prev_d, t) # this method is called after each time the input position advances
    # during SLL prediction
    @_sll_stop_index = @_input.index

    existing_tgt_state = super.existing_target_state(prev_d, t)
    unless existing_tgt_state.nil?
      @decisions[@current_decision].SLL_DFATransitions += 1 # count only if we transition over a DFA state
      if existing_tgt_state == ERROR
        @decisions[@current_decision].errors.add(ErrorInfo.new(@current_decision, prev_d.configs, @_input, @_start_index, @_sll_stop_index, false))
      end
    end

    @current_state = existing_tgt_state
    existing_tgt_state
  end

  def compute_target_state(dfa, prev_d, t)
    state = super.compute_target_state(dfa, prev_d, t)
    @current_state = state
    state
  end

  def compute_reach_set(closure, t, full_ctx)
    if full_ctx
      # this method is called after each time the input position advances
      # during full context prediction
      @_ll_stop_index = @_input.index
    end

    reach_configs = super.compute_reach_set(closure, t, full_ctx)
    if full_ctx
      @decisions[@current_decision].LL_ATNTransitions += 1 # count computation even if error
      if !reach_configs.nil?
      else # no reach on current lookahead symbol. ERROR.
        # TODO: does not handle delayed errors per getSynValidOrSemInvalidAltThatFinishedDecisionEntryRule()
        @decisions[@current_decision].errors.add(ErrorInfo.new(@current_decision, closure, @_input, @_start_index, @_ll_stop_index, true))
      end
    else
      @decisions[@current_decision].SLL_ATNTransitions += 1
      if !reach_configs.nil?
      else # no reach on current lookahead symbol. ERROR.
        @decisions[@current_decision].errors.add(ErrorInfo.new(@current_decision, closure, @_input, @_start_index, @_sll_stop_index, false))
      end
    end

    reach_configs
  end

  def eval_semantic_context(pred, parser_call_stack, alt, full_ctx)
    result = super.eval_semantic_context(pred, parser_call_stack, alt, full_ctx)
    unless pred.is_a? SemanticContext.PrecedencePredicate
      full_context = (@_ll_stop_index >= 0)
      stop_index = full_context ? @_ll_stop_index : @_sll_stop_index
      @decisions[@current_decision].predicate_evals.add(PredicateEvalInfo.new(@current_decision, @_input, @_start_index, stop_index, pred, result, alt, full_ctx))
    end

    result
  end

  def report_attempting_full_context(dfa, conflicting_alts, configs, start_index, stop_index)
    if !conflicting_alts.nil?
      @conflicting_alt_resolved_by_sll = conflicting_alts.next_set_bit(0)
    else
      @conflicting_alt_resolved_by_sll = configs.alts.next_set_bit(0)
    end
    @decisions[@current_decision].LL_Fallback += 1
    super.report_attempting_full_context(dfa, conflicting_alts, configs, start_index, stop_index)
  end

  def report_context_sensitivity(dfa, prediction, configs, start_index, stop_index)
    if prediction != @conflicting_alt_resolved_by_sll
      @decisions[@current_decision].context_sensitivities.add(ContextSensitivityInfo.new(@current_decision, configs, @_input, start_index, stop_index))
    end
    super.report_context_sensitivity(dfa, prediction, configs, start_index, stop_index)
  end

  def report_ambiguity(dfa, _d, start_index, stop_index, exact, ambig_alts, configs)
    prediction = if !ambig_alts.nil?
                   ambig_alts.next_set_bit(0)
                 else
                   configs.alts.next_set_bit(0)
                 end

    if configs.full_ctx && prediction != @conflicting_alt_resolved_by_sll
      # Even though this is an ambiguity we are reporting, we can
      # still detect some context sensitivities.  Both SLL and LL
      # are showing a conflict, hence an ambiguity, but if they resolve
      # to different minimum alternatives we have also identified a
      # context sensitivity.
      @decisions[@current_decision].context_sensitivities.add(ContextSensitivityInfo.new(@current_decision, configs, @_input, start_index, stop_index))
    end
    @decisions[@current_decision].ambiguities.add(AmbiguityInfo.new(@current_decision, configs, ambig_alts, @_input, start_index, stop_index, configs.full_ctx))
    super.report_ambiguity(dfa, _d, start_index, stop_index, exact, ambig_alts, configs)
  end
end
