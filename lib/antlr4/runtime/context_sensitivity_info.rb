class ContextSensitivityInfo < DecisionEventInfo
  def initialize(decision, configs, input, start_index, stop_index)
    super(decision, configs, input, start_index, stop_index, true)
  end
end
