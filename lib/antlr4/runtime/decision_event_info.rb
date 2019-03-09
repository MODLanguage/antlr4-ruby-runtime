class DecisionEventInfo
  attr_accessor :decision
  attr_accessor :configs
  attr_accessor :input
  attr_accessor :start_index
  attr_accessor :stop_index
  attr_accessor :full_ctx

  def initialize(decision, configs, input, start_index, stop_index, full_ctx)
    @decision = decision
    @full_ctx = full_ctx
    @stop_index = stop_index
    @input = input
    @start_index = start_index
    @configs = configs
  end
end
