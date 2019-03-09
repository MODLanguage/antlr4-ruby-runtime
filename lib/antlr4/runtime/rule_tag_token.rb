require '../antlr4/token'

class RuleTagToken < Token
  attr_reader :rule_name
  attr_reader :bypass_token_type
  attr_reader :label

  def initialize(rule_name, bypass_token_type, label = nil)
    if rule_name.nil? || rule_name.empty?
      raise IllegalArgumentException, 'rule_name cannot be nil or empty.'
    end

    @rule_name = rule_name
    @bypass_token_type = bypass_token_type
    @label = label
  end

  def channel
    DEFAULT_CHANNEL
  end

  def text
    return '<' + @label + ':' + @rule_name + '>' unless @label.nil?

    '<' + @rule_name + '>'
  end

  def type
    @bypass_token_type
  end

  def line
    0
  end

  def char_position_in_line
    -1
  end

  def token_index
    -1
  end

  def start_index
    -1
  end

  def stop_index
    -1
  end

  def token_source
    nil
  end

  def input_stream
    nil
  end

  def to_s
    @rule_name + ':' + @bypass_token_type
  end
end
