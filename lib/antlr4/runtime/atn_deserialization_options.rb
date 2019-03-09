class ATNDeserializationOptions
  @@default_options = ATNDeserializationOptions.new

  def initialize(read_only = true, options = nil)
    @read_only = read_only
    if !options.nil?
      @verify_atn = options.verify_atn
      @generate_rule_bypass_transitions = options.generate_rule_bypass_transitions
    else
      @verify_atn = true
      @generate_rule_bypass_transitions = false
    end
  end

  def self.get_default_options
    @@default_options
  end

  def read_only?
    @read_only
  end

  def make_read_only
    @read_only = true
  end

  def verify_atn?
    @verify_atn
  end

  def verify_atn(verify_atn)
    throw_if_read_only
    @verify_atn = verify_atn
  end

  def generate_rule_bypass_transitions?
    @generate_rule_bypass_transitions
  end

  def generate_rule_bypass_transitions(generate_rule_bypass_transitions)
    throw_if_read_only
    @generate_rule_bypass_transitions = generate_rule_bypass_transitions
  end

  def throw_if_read_only
    raise IllegalStateException, 'The object is read only.' if read_only?
  end
end
