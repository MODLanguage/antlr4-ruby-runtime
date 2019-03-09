class LookaheadEventInfo < DecisionEventInfo
  attr_reader :predicted_alt

  def initialize(decision, configs, predicted_alt, input, start_index, stop_index, fullCtx)
    super(decision, configs, input, start_index, stop_index, fullCtx)
    @predicted_alt = predicted_alt
  end
end
