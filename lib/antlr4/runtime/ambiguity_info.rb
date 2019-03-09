require 'decision_event_info'

class AmbiguityInfo < DecisionEventInfo
  def initialize(decision, configs, ambig_alts, input, start_index, stop_index, full_ctx)
    super(decision, configs, input, start_index, stop_index, full_ctx)
    @ambig_alts = ambig_alts
  end
end
