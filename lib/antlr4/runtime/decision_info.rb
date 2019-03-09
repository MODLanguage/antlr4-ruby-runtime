class DecisionInfo
  attr_accessor :decision
  attr_accessor :invocations
  attr_accessor :timeInPrediction
  attr_accessor :SLL_TotalLook
  attr_accessor :SLL_MinLook
  attr_accessor :SLL_MaxLook
  attr_accessor :SLL_MaxLookEvent
  attr_accessor :LL_TotalLook
  attr_accessor :LL_MinLook
  attr_accessor :LL_MaxLook
  attr_accessor :LL_MaxLookEvent
  attr_accessor :context_sensitivities
  attr_accessor :errors
  attr_accessor :ambiguities
  attr_accessor :predicate_evals
  attr_accessor :SLL_ATNTransitions
  attr_accessor :SLL_DFATransitions
  attr_accessor :LL_Fallback
  attr_accessor :LL_ATNTransitions
  attr_accessor :LL_DFATransitions

  def initialize(decision)
    @context_sensitivities = []
    @errors = []
    @ambiguities = []
    @predicate_evals = []
    @decision = decision
  end

  def to_s
    '' + 'decision=' + @decision + ', contextSensitivities=' + @context_sensitivities.size + ', errors=' + @errors.size + ', ambiguities=' + @ambiguities.size + ', SLL_lookahead=' + SLL_TotalLook + ', SLL_ATNTransitions=' + SLL_ATNTransitions + ', SLL_DFATransitions=' + SLL_DFATransitions + ', LL_Fallback=' + LL_Fallback + ', LL_lookahead=' + LL_TotalLook + ', LL_ATNTransitions=' + LL_ATNTransitions + 'end'
  end
end
