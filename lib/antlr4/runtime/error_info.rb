class ErrorInfo < DecisionEventInfo
  def initialize(decision, configs, input, start_index, stop_index, full_ctx)
    super(decision, configs, input, start_index, stop_index, full_ctx)
  end
end
