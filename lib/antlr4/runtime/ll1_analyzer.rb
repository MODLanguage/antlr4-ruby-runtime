require '../antlr4/token'
require 'set'

class LL1Analyzer
  @@hit_pred = Token::INVALID_TYPE

  def initialize(atn)
    @atn = atn
  end

  def decision_lookahead(s)
    return nil if s.nil?

    look = []
    alt = 0
    while alt < s.number_of_transitions
      look[alt] = new IntervalSet
      look_busy = Set.new
      see_thru_preds = false # fail to get lookahead upon pred
      _look(s.transition(alt).target, nil, EmptyPredictionContext::EMPTY, look[alt], look_busy, Set.new, see_thru_preds, false)
      # Wipe out lookahead for this alternative if we found nothing
      # or we had a predicate when we !see_thru_preds
      look[alt] = nil if look[alt].empty? || look[alt].include?(HIT_PRED)
      alt += 1
    end
    look
  end

  def look(s, stop_state, ctx)
    r = IntervalSet.new
    see_thru_preds = true # ignore preds get all lookahead
    look_context = !ctx.nil? ? PredictionContextUtils.from_rule_context(s.atn, ctx) : nil
    _look(s, stop_state, look_context, r, Set.new, Set.new, see_thru_preds, true)
    r
  end

  def _look(s, stopState, ctx, look, lookBusy, calledRuleStack, seeThruPreds, addEOF)
    #    System.out.println("_LOOK("+s.stateNumber+", ctx="+ctx)
    c = ATNConfig.new
    c.atn_config1(s, 0, ctx)
    added = false
    unless lookBusy.include? c
      lookBusy.add(c)
      added = true
    end
    return unless added

    if s == stopState
      if ctx.nil?
        look.add(Token::EPSILON)
        return
      elsif ctx.empty? && addEOF
        look.add(Token::EOF)
        return
      end
    end

    if s.is_a? RuleStopState
      if ctx.nil?
        look.add(Token::EPSILON)
        return
      elsif ctx.empty? && addEOF
        look.add(Token::EOF)
        return
      end

      if ctx != EmptyPredictionContext::EMPTY
        # run thru all possible stack tops in ctx
        removed = calledRuleStack.get(s.rule_index)
        begin
          calledRuleStack.clear(s.rule_index)
          i = 0
          while i < ctx.size
            return_state = atn.states.get(ctx.get_return_state(i))

            _look(return_state, stopState, ctx.get_parent(i), look, lookBusy, calledRuleStack, seeThruPreds, addEOF)
            i += 1
          end
        ensure
          calledRuleStack.set(s.rule_index) if removed
        end
        return
      end
    end

    n = s.number_of_transitions
    i = 0
    while i < n
      t = s.transition(i)
      if t.is_a? RuleTransition.class
        if calledRuleStack.get(t.target.rule_index)
          i += 1
          next
        end

        new_ctx = SingletonPredictionContext.create(ctx, t.follow_state.state_number)

        begin
          calledRuleStack.set(t.target.rule_index)
          _look(t.target, stopState, new_ctx, look, lookBusy, calledRuleStack, seeThruPreds, addEOF)
        ensure
          calledRuleStack.clear(t.target.rule_index)
        end
      elsif t.is_a? AbstractPredicateTransition
        if seeThruPreds
          _look(t.target, stopState, ctx, look, lookBusy, calledRuleStack, seeThruPreds, addEOF)
        else
          look.add(HIT_PRED)
        end
      elsif t.epsilon?
        _look(t.target, stopState, ctx, look, lookBusy, calledRuleStack, seeThruPreds, addEOF)
      elsif t.is_a? WildcardTransition
        look.add_all(IntervalSet.of(Token::MIN_USER_TOKEN_TYPE, atn.max_token_type))
      else
        set = t.label
        unless set.nil?
          if t.is_a? NotSetTransition
            set = set.complement(IntervalSet.of(Token::MIN_USER_TOKEN_TYPE, atn.max_token_type))
          end
          look.add_all(set)
        end
      end

      i += 1
    end
  end
end
