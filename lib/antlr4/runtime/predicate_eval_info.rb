class PredicateEvalInfo < DecisionEventInfo
  attr_reader :semctx

  attr_reader :predicted_alt

  attr_reader :eval_result

  def initialize(decision, input, start_index, stop_index, semctx, eval_result, predicted_alt, full_ctx)
    super(decision, ATNConfigSet().new, input, start_index, stop_index, full_ctx)
    @semctx = semctx
    @eval_result = eval_result
    @predicted_alt = predicted_alt
  end
end
